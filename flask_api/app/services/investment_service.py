# File: flask_api/app/services/investment_service.py

from app.utils.firebase_config import db
from datetime import datetime, timezone
import traceback
from firebase_admin import firestore
import yfinance as yf
import uuid
from functools import lru_cache
import pandas as pd
from google.cloud.firestore_v1.base_query import FieldFilter
from .technical_analysis_service import TechnicalAnalysisService


class InvestmentService:
    # === YARDIMCI METOTLAR ===

    @staticmethod
    def _get_accounts_collection():
        return db.collection('user_accounts')

    @staticmethod
    def _get_holdings_collection():
        return db.collection('holdings')

    @staticmethod
    def _get_transactions_collection():
        return db.collection('investment_transactions')

    @staticmethod
    @lru_cache(maxsize=1)
    def get_usdtry_rate():
        try:
            data = yf.download("USDTRY=X", period="1d", interval="1h", progress=False)
            if not data.empty:
                return float(data["Close"].iloc[-1])
        except Exception as e:
            print(f"INVESTMENT_SERVICE: USDTRY fetch failed: {e}. Using fallback.")
        return 38.5
    
    @staticmethod
    def _update_investment_accounts_balance(accounts_values: dict):
        try:
            batch = db.batch()
            for account_id, new_balance in accounts_values.items():
                ref = InvestmentService._get_accounts_collection().document(account_id)
                batch.update(ref, {
                    "currentBalance": new_balance,
                    "updatedAt": datetime.now(timezone.utc).isoformat()
                })
            batch.commit()
            print(f"INVESTMENT_SERVICE: Balances updated for {len(accounts_values)} investment accounts.")
        except Exception as e:
            print(f"INVESTMENT_SERVICE: Failed to update balances: {e}")

    # === İŞ MANTIĞI METOTLARI ===

    @staticmethod
    @firestore.transactional
    def _recalculate_holding(transaction, account_id, user_id, asset_symbol):
        txs_collection = InvestmentService._get_transactions_collection()
        query = (txs_collection
                 .where(filter=FieldFilter("accountId", "==", account_id))
                 .where(filter=FieldFilter("assetSymbol", "==", asset_symbol))
                 .order_by("date", direction=firestore.Query.ASCENDING)
                 .order_by("createdAt", direction=firestore.Query.ASCENDING))
        
        all_transactions = list(query.get(transaction=transaction))
        
        total_quantity = 0.0
        weighted_total_cost = 0.0

        for doc in all_transactions:
            tx = doc.to_dict()
            quantity = float(tx.get("quantity", 0.0))
            price = float(tx.get("pricePerUnit", 0.0))
            
            if tx.get("type") == "buy":
                current_avg_cost = weighted_total_cost / total_quantity if total_quantity > 0 else 0
                weighted_total_cost = (total_quantity * current_avg_cost) + (quantity * price)
                total_quantity += quantity
            else:  # sell
                if total_quantity < quantity:
                    raise ValueError(f"Sell quantity {quantity} exceeds available {total_quantity} for {asset_symbol}")
                
                avg_cost_before_sell = weighted_total_cost / total_quantity if total_quantity > 0 else 0
                weighted_total_cost -= quantity * avg_cost_before_sell
                total_quantity -= quantity

        holdings_collection = InvestmentService._get_holdings_collection()
        holdings_query = (holdings_collection
                          .where(filter=FieldFilter("accountId", "==", account_id))
                          .where(filter=FieldFilter("assetSymbol", "==", asset_symbol))
                          .limit(1))
        
        existing_holdings = list(holdings_query.get(transaction=transaction))
        holding_ref = existing_holdings[0].reference if existing_holdings else None

        if total_quantity > 1e-9:
            new_average_cost = weighted_total_cost / total_quantity if total_quantity > 0 else 0
            data_to_update = {
                "quantity": total_quantity,
                "averageCost": new_average_cost,
                "updatedAt": datetime.now(timezone.utc).isoformat()
            }
            if holding_ref:
                transaction.update(holding_ref, data_to_update)
            else:
                new_holding_ref = holdings_collection.document(str(uuid.uuid4()))
                data_to_update.update({
                    "userId": user_id,
                    "accountId": account_id,
                    "assetSymbol": asset_symbol,
                    "createdAt": datetime.now(timezone.utc).isoformat()
                })
                transaction.set(new_holding_ref, data_to_update)
        elif holding_ref:
            transaction.delete(holding_ref)

    @staticmethod
    def create_transaction(data):
        try:
            required_fields = ("userId", "accountId", "assetSymbol", "type", "quantity", "pricePerUnit", "date")
            if not all(field in data for field in required_fields):
                return {"success": False, "error": "Missing required fields"}, 400

            tx_type = data["type"].lower()
            quantity = float(data["quantity"])
            price_per_unit = float(data["pricePerUnit"])
            symbol = data["assetSymbol"].upper()
            account_id = data["accountId"]
            user_id = data["userId"]
            
            payload = {**data, "createdAt": datetime.now(timezone.utc).isoformat(), "totalAmount": quantity * float(data["pricePerUnit"])}

            if tx_type == "sell":
                holdings_ref = InvestmentService._get_holdings_collection()
                hold_q = (holdings_ref
                          .where(filter=FieldFilter("accountId", "==", account_id))
                          .where(filter=FieldFilter("assetSymbol", "==", symbol)).limit(1))
                
                existing_hold = list(hold_q.stream())
                if not existing_hold or existing_hold[0].to_dict().get('quantity', 0) < quantity:
                    return {"success": False, "error": f"Yetersiz varlık. Satılabilecek miktar: {existing_hold[0].to_dict().get('quantity', 0) if existing_hold else 0}"}, 400

                hold_data = existing_hold[0].to_dict()
                average_cost = hold_data.get('averageCost', 0)
                
                cost_of_goods_sold = quantity * average_cost
                revenue = quantity * price_per_unit
                realized_pl = revenue - cost_of_goods_sold
                
                payload["realizedPL"] = realized_pl

                try:
                    account_ref = InvestmentService._get_accounts_collection().document(account_id)
                    account_ref.update({"totalRealizedPL": firestore.Increment(realized_pl)})
                except Exception as e:
                    print(f"Could not update realized PL for account {account_id}: {e}")   

            tx_ref = InvestmentService._get_transactions_collection().document()
            tx_ref.set(payload)

            txn = db.transaction()
            InvestmentService._recalculate_holding(txn, account_id, user_id, symbol)

            payload["id"] = tx_ref.id
            return {"success": True, "transaction": payload}, 201

        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def get_portfolio_summary(user_id):
        try:
            # 1. Adım: Hesapları ve Holdingleri Çek
            acc_q = (InvestmentService._get_accounts_collection()
                     .where(filter=FieldFilter("userId", "==", user_id))
                     .where(filter=FieldFilter("accountType", "==", "investment")))
            accounts = list(acc_q.stream())
            if not accounts:
                return {"success": True, "summary": {"totalPortfolioValue": 0, "totalProfitLoss": 0, "totalProfitLossPercent": 0, "totalRealizedPL": 0, "holdings": []}}, 200

            account_map = {acc.id: acc.to_dict() for acc in accounts}

            hold_q = InvestmentService._get_holdings_collection().where(filter=FieldFilter("accountId", "in", list(account_map.keys())))
            all_holdings = list(hold_q.stream())
            if not all_holdings:
                return {"success": True, "summary": {"totalPortfolioValue": 0, "totalProfitLoss": 0, "totalProfitLossPercent": 0, "totalRealizedPL": 0, "holdings": []}}, 200

            symbols = list(set(h.to_dict()["assetSymbol"] for h in all_holdings))
            
            # 2. Adım: Fiyatları Sağlam Bir Yöntemle Çek
            live_prices = {}
            if symbols:
                price_data = yf.download(symbols, period="1d", progress=False) 
                
                if not price_data.empty:
                    close_prices_df = price_data.get('Close')
                    if close_prices_df is not None:
                        for symbol in symbols:
                            if isinstance(close_prices_df, pd.Series):
                                price_series = close_prices_df.dropna()
                                if not price_series.empty:
                                    live_prices[symbol] = float(price_series.iloc[-1])
                            elif isinstance(close_prices_df, pd.DataFrame) and symbol in close_prices_df.columns:
                                price_series = close_prices_df[symbol].dropna()
                                if not price_series.empty:
                                    live_prices[symbol] = float(price_series.iloc[-1])
            
            # 3. Adım: Portföyü Hesapla
            usd_try_rate = InvestmentService.get_usdtry_rate()
            detailed_holdings = []
            total_portfolio_value_try = 0.0
            total_portfolio_cost_try = 0.0
            val_by_acc = {aid: 0.0 for aid in account_map.keys()}

            for hold in all_holdings:
                h_data = hold.to_dict()
                symbol = h_data["assetSymbol"]
                account_id = h_data["accountId"]
                account_info = account_map.get(account_id, {})
                
                currency = account_info.get("currency", "TRY")
                category = account_info.get("category", "Diğer")
                quantity = float(h_data["quantity"])
                avg_cost_native = float(h_data["averageCost"])
                
                current_price_native = live_prices.get(symbol)
                
                is_market_open = current_price_native is not None
                if not is_market_open:
                    current_price_native = avg_cost_native

                current_value_native = quantity * current_price_native
                total_cost_native = quantity * avg_cost_native
                
                conversion_rate = usd_try_rate if currency == "USD" else 1.0
                cost_in_try = total_cost_native * conversion_rate
                value_in_try = current_value_native * conversion_rate
                
                profit_loss_try = value_in_try - cost_in_try
                profit_loss_percent = (profit_loss_try / cost_in_try * 100) if cost_in_try > 0 else 0.0

                detailed_holdings.append({
                    "id": hold.id, "symbol": symbol, "quantity": quantity,
                    "averageCostNative": round(avg_cost_native, 4),
                    "currentPriceNative": round(current_price_native, 4),
                    "currentValueTRY": round(value_in_try, 2),
                    "profitLossTRY": round(profit_loss_try, 2),
                    "profitLossPercent": round(profit_loss_percent, 2),
                    "isMarketOpen": is_market_open, "currency": currency, "category": category
                })

                total_portfolio_value_try += value_in_try
                total_portfolio_cost_try += cost_in_try
                val_by_acc[account_id] += value_in_try

            InvestmentService._update_investment_accounts_balance(val_by_acc)
            total_pl = total_portfolio_value_try - total_portfolio_cost_try
            total_pl_pct = (total_pl / total_portfolio_cost_try * 100) if total_portfolio_cost_try > 0 else 0.0
            total_realized_pl_all_accounts = sum(acc.get('totalRealizedPL', 0) for acc in account_map.values())
            
            summary = {
                "totalPortfolioValue": round(total_portfolio_value_try, 2),
                "totalProfitLoss": round(total_pl, 2),
                "totalProfitLossPercent": round(total_pl_pct, 2),
                "totalRealizedPL": round(total_realized_pl_all_accounts, 2),
                "holdings": sorted(detailed_holdings, key=lambda x: x["currentValueTRY"], reverse=True)
            }
            return {"success": True, "summary": summary}, 200

        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500
    @staticmethod
    def list_transactions(user_id, account_id=None, asset_symbol=None):
        try:
            q = InvestmentService._get_transactions_collection().where(filter=FieldFilter("userId", "==", user_id))
            if account_id:
                q = q.where(filter=FieldFilter("accountId", "==", account_id))
            if asset_symbol:
                q = q.where(filter=FieldFilter("assetSymbol", "==", asset_symbol.upper()))
            q = q.order_by("date", direction=firestore.Query.DESCENDING).order_by("createdAt", direction=firestore.Query.DESCENDING)
            txs = [{"id": d.id, **d.to_dict()} for d in q.stream()]
            return {"success": True, "transactions": txs}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def update_transaction(transaction_id, data):
        try:
            tx_ref = InvestmentService._get_transactions_collection().document(transaction_id)
            existing = tx_ref.get()
            if not existing.exists:
                return {"success": False, "error": "Transaction not found"}, 404

            update_payload = data.copy()
            update_payload["updatedAt"] = datetime.now(timezone.utc).isoformat()
            tx_ref.update(update_payload)

            old = existing.to_dict()
            txn = db.transaction()
            InvestmentService._recalculate_holding(
                txn, old["accountId"], old["userId"], old["assetSymbol"]
            )

            updated = tx_ref.get().to_dict()
            updated["id"] = transaction_id
            return {"success": True, "transaction": updated}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def delete_transaction(transaction_id):
        try:
            tx_ref = InvestmentService._get_transactions_collection().document(transaction_id)
            existing = tx_ref.get()
            if not existing.exists:
                return {"success": True, "message": "Transaction already deleted."}, 200

            data = existing.to_dict()
            tx_ref.delete()

            txn = db.transaction()
            InvestmentService._recalculate_holding(
                txn, data["accountId"], data["userId"], data["assetSymbol"]
            )
            return {"success": True, "message": "Transaction deleted successfully."}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def delete_holding(holding_id):
        try:
            hold_ref = InvestmentService._get_holdings_collection().document(holding_id)
            doc = hold_ref.get()
            if not doc.exists:
                return {"success": True, "message": "Holding already deleted."}, 200

            d = doc.to_dict()
            acc_id = d["accountId"]
            sym = d["assetSymbol"]

            txs_ref = InvestmentService._get_transactions_collection()
            q = (txs_ref
                 .where(filter=FieldFilter("accountId", "==", acc_id))
                 .where(filter=FieldFilter("assetSymbol", "==", sym)))
            to_delete = list(q.stream())

            batch = db.batch()
            for tx in to_delete:
                batch.delete(tx.reference)
            batch.delete(hold_ref)
            batch.commit()

            return {
                "success": True,
                "message": f"Holding {sym} and its transactions were deleted."
            }, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def override_holding(holding_id, data):
        """
        Bir holding'in tüm işlem geçmişini siler ve verilen yeni miktar/maliyetle
        tek bir 'buy' işlemi oluşturur.
        """
        try:
            # 1. Holding belgesini al
            hold_ref = InvestmentService._get_holdings_collection().document(holding_id)
            doc = hold_ref.get()
            if not doc.exists:
                return {"success": False, "error": "Holding not found"}, 404

            h_data = doc.to_dict()
            user_id = h_data["userId"]
            account_id = h_data["accountId"]
            asset_symbol = h_data["assetSymbol"]
            
            # 2. Bu holding'e ait tüm eski işlemleri sil
            txs_ref = InvestmentService._get_transactions_collection()
            q = (txs_ref
                 .where(filter=FieldFilter("accountId", "==", account_id))
                 .where(filter=FieldFilter("assetSymbol", "==", asset_symbol)))
            
            batch = db.batch()
            for tx_doc in q.stream():
                batch.delete(tx_doc.reference)
            batch.commit()

            # 3. Yeni verilerle tek bir 'buy' işlemi oluştur
            new_quantity = float(data["quantity"])
            new_average_cost = float(data["averageCost"])
            
            new_tx_payload = {
                "userId": user_id,
                "accountId": account_id,
                "assetSymbol": asset_symbol,
                "type": "buy",
                "quantity": new_quantity,
                "pricePerUnit": new_average_cost,
                "totalAmount": new_quantity * new_average_cost,
                "date": datetime.now(timezone.utc).strftime('%Y-%m-%d'),
                "createdAt": datetime.now(timezone.utc).isoformat(),
                "note": "Holding override işlemi."
            }
            new_tx_ref = txs_ref.document()
            new_tx_ref.set(new_tx_payload)
            
            # 4. Holding'i yeniden hesaplat (bu, tek işleme göre güncelleyecektir)
            txn = db.transaction()
            InvestmentService._recalculate_holding(txn, account_id, user_id, asset_symbol)

            return {"success": True, "message": "Holding overridden successfully"}, 200

        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500

    @staticmethod
    def get_asset_analysis(symbol):
        try:
            df = yf.download(symbol, period="90d", interval="1h", progress=False)
            if df.empty:
                return {"success": False, "error": "Veri bulunamadı."}, 404

            if isinstance(df.columns, pd.MultiIndex):
                df.columns = df.columns.get_level_values(0)

            df = df.dropna(subset=["Open", "High", "Low", "Close", "Volume"])
            closes = df["Close"]

            rsi = TechnicalAnalysisService.calculate_rsi(closes)
            macd_line, signal_line = TechnicalAnalysisService.calculate_macd(closes)
            ema50 = TechnicalAnalysisService.calculate_ema(closes, span=50)
            sl, tp = TechnicalAnalysisService.calculate_sl_tp(closes)
            
            verdict = TechnicalAnalysisService.get_analysis_verdict(
                price=closes.iloc[-1], ema50=ema50, rsi=rsi,
                macd_line=macd_line, signal_line=signal_line
            )

            chart_df = df[["Close"]].copy()
            chart_df["timestamp_ms"] = (chart_df.index.astype(int) / 10**6).astype(int)
            chart_data = (
                chart_df[["timestamp_ms", "Close"]]
                .rename(columns={"timestamp_ms": "timestamp", "Close": "price"})
                .to_dict("records")
            )

            result = {
                "symbol": symbol,
                "lastPrice": round(closes.iloc[-1], 4),
                "rsi": round(rsi, 2) if rsi is not None else None,
                "macd": {
                    "macdLine": round(macd_line, 4) if macd_line is not None else None,
                    "signalLine": round(signal_line, 4) if signal_line is not None else None
                },
                "ema50": round(ema50, 4) if ema50 is not None else None,
                "volatilityLevels": {
                    "stopLoss": round(sl, 4) if sl is not None else None,
                    "takeProfit": round(tp, 4) if tp is not None else None
                },
                "verdict": verdict,
                "chartData": chart_data
            }
            return {"success": True, "analysis": result}, 200
        except Exception as e:
            traceback.print_exc()
            return {"success": False, "error": str(e)}, 500