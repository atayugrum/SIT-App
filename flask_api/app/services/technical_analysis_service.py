# File: flask_api/app/services/technical_analysis_service.py
import pandas as pd
import numpy as np
from .ai_service import AIService 

class TechnicalAnalysisService:
    HORIZONS = {
        "shortTerm": {"name": "Kısa Vade"},
        "midTerm": {"name": "Orta Vade"},
        "longTerm": {"name": "Uzun Vade"},
    }
    
    # --- GÖSTERGE HESAPLAMA FONKSİYONLARI (DEĞİŞİKLİK YOK) ---
    
    @staticmethod
    def calculate_rsi(price_series: pd.Series, period: int = 14) -> "float | None":
        if price_series.empty or len(price_series) < period: return None
        delta = price_series.diff()
        gain = delta.where(delta > 0, 0).ewm(alpha=1/period, adjust=False).mean()
        loss = -delta.where(delta < 0, 0).ewm(alpha=1/period, adjust=False).mean()
        rs = gain / loss.replace(0, 1e-9)
        rsi = 100 - (100 / (1 + rs))
        return rsi.iloc[-1] if not rsi.empty else None

    @staticmethod
    def calculate_macd(price_series: pd.Series):
        if price_series.empty: return None, None
        ema12 = price_series.ewm(span=12, adjust=False).mean()
        ema26 = price_series.ewm(span=26, adjust=False).mean()
        macd_line = ema12 - ema26
        signal_line = macd_line.ewm(span=9, adjust=False).mean()
        last_macd = macd_line.iloc[-1] if not macd_line.empty else None
        last_signal = signal_line.iloc[-1] if not signal_line.empty else None
        return last_macd, last_signal

    @staticmethod
    def calculate_ema(price_series: pd.Series, span: int) -> "float | None":
        if price_series.empty or len(price_series) < span: return None
        ema = price_series.ewm(span=span, adjust=False).mean()
        return ema.iloc[-1] if not ema.empty else None

    @staticmethod
    def calculate_stochastic(high: pd.Series, low: pd.Series, close: pd.Series, period: int = 14):
        if len(close) < period: return None
        l14 = low.rolling(window=period).min()
        h14 = high.rolling(window=period).max()
        k_percent = 100 * ((close - l14) / (h14 - l14).replace(0, 1e-9))
        return k_percent.iloc[-1] if not k_percent.empty else None

    # --- ANA ANALİZ FONKSİYONU (GÜNCELLENMİŞ HALİ) ---
        
    @staticmethod
    def get_full_analysis(df: pd.DataFrame, symbol: str, risk_profile: str):
        if df.empty: return None
        if isinstance(df.columns, pd.MultiIndex):
            df.columns = df.columns.get_level_values(0)
        df = df.dropna(subset=["Open", "High", "Low", "Close", "Volume"])
        
        closes = df["Close"]
        last_price = closes.iloc[-1]
        
        analysis_data = {
            "symbol": symbol,
            "lastPrice": round(last_price, 4),
            "analysis": {}
        }
        
        # Tüm göstergeleri bir kez hesapla
        macd_line, signal_line = TechnicalAnalysisService.calculate_macd(closes)
        rsi = TechnicalAnalysisService.calculate_rsi(closes)
        stochastic = TechnicalAnalysisService.calculate_stochastic(df['High'], df['Low'], df['Close'])
        ema20 = TechnicalAnalysisService.calculate_ema(closes, 20)
        ema50 = TechnicalAnalysisService.calculate_ema(closes, 50)
        ema200 = TechnicalAnalysisService.calculate_ema(closes, 200)

        for horizon_key, params in TechnicalAnalysisService.HORIZONS.items():
            
            # --- YENİ: Her vade için SABİT 4 anahtar ama DEĞİŞKEN değerler ---
            current_indicators = {}
            if horizon_key == 'shortTerm':
                current_indicators = {
                    "rsi": round(rsi, 2) if rsi else None,
                    "stochastic": round(stochastic, 2) if stochastic else None,
                    "macd_status": "Pozitif" if macd_line and signal_line and macd_line > signal_line else "Negatif",
                    "ema_status": "Fiyat EMA20 Üstünde" if ema20 and last_price > ema20 else "Fiyat EMA20 Altında"
                }
            elif horizon_key == 'midTerm':
                current_indicators = {
                    "rsi": round(rsi, 2) if rsi else None,
                    "stochastic": round(stochastic, 2) if stochastic else None,
                    "macd_status": "Pozitif" if macd_line and signal_line and macd_line > signal_line else "Negatif",
                    "ema_status": "Fiyat EMA50 Üstünde" if ema50 and last_price > ema50 else "Fiyat EMA50 Altında"
                }
            elif horizon_key == 'longTerm':
                 current_indicators = {
                    "rsi": round(rsi, 2) if rsi else None,
                    "stochastic": round(stochastic, 2) if stochastic else None,
                    "macd_status": "Pozitif" if macd_line and signal_line and macd_line > signal_line else "Negatif",
                    "ema_status": "Fiyat EMA200 Üstünde" if ema200 and last_price > ema200 else "Fiyat EMA200 Altında"
                }
            
            # Yorumu Gemini'den alırken kullanılacak daha açıklayıcı veri
            indicators_for_ai = {k: v for k, v in current_indicators.items() if v is not None}

            rationale = AIService.generate_dynamic_analysis_comment(
                indicators=indicators_for_ai, 
                horizon=params["name"], 
                symbol=symbol, 
                risk_profile=risk_profile
            )

            analysis_data["analysis"][horizon_key] = {
                "verdict": "POZİTİF" if (current_indicators.get("ema_status", "").endswith("Üstünde") and current_indicators.get("macd_status") == "Pozitif") else "NEGATİF",
                "rationale": rationale,
                "indicators": current_indicators # UI için sabit anahtarlı veriyi gönder
            }

        return analysis_data