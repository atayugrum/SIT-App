# File: flask_api/app/services/technical_analysis_service.py
import pandas as pd
import numpy as np

class TechnicalAnalysisService:
    """
    Finansal veriler üzerinde teknik analiz hesaplamaları yapan
    yardımcı fonksiyonları içerir.
    """
    @staticmethod
    def calculate_rsi(price_series: pd.Series, period: int = 14) -> float | None:
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
        
        # Son değerlerin None olup olmadığını kontrol et
        last_macd = macd_line.iloc[-1] if not macd_line.empty else None
        last_signal = signal_line.iloc[-1] if not signal_line.empty else None
        
        return last_macd, last_signal

    @staticmethod
    def calculate_ema(price_series: pd.Series, span: int) -> float | None:
        """Belirtilen periyot için Üstel Hareketli Ortalama (EMA) hesaplar."""
        if price_series.empty or len(price_series) < span: return None
        ema = price_series.ewm(span=span, adjust=False).mean()
        return ema.iloc[-1] if not ema.empty else None

    @staticmethod
    def calculate_sl_tp(price_series: pd.Series):
        """Volatiliteye dayalı Stop-Loss ve Take-Profit seviyeleri hesaplar."""
        if len(price_series) < 20: return None, None # Yeterli veri yoksa hesaplama
        last_price = price_series.iloc[-1]
        
        # ATR (Average True Range) kullanarak volatilite hesapla
        high_low = price_series.rolling(14).max() - price_series.rolling(14).min()
        high_close = np.abs(price_series.rolling(14).max() - price_series.shift().rolling(14).mean())
        low_close = np.abs(price_series.rolling(14).min() - price_series.shift().rolling(14).mean())
        
        tr = pd.DataFrame({'hl': high_low, 'hc': high_close, 'lc': low_close}).max(axis=1)
        atr = tr.ewm(alpha=1/14, adjust=False).mean().iloc[-1]
        
        if pd.isna(atr) or pd.isna(last_price):
             return None, None

        stop_loss = last_price - (atr * 1.5)
        take_profit = last_price + (atr * 2.0)
        return stop_loss, take_profit

    @staticmethod
    def get_analysis_verdict(price: float, ema50: float, rsi: float, macd_line: float, signal_line: float):
        """Teknik göstergelere göre bir skor ve yorum oluşturur."""
        score = 0
        reasons = []

        # Kontroller: Göstergeler None ise analize dahil etme
        if rsi is not None:
            if rsi < 30: score += 2; reasons.append(f"RSI ({rsi:.1f}) aşırı satım bölgesinde.")
            elif rsi > 70: score -= 2; reasons.append(f"RSI ({rsi:.1f}) aşırı alım bölgesinde.")
        
        if price is not None and ema50 is not None:
            if price > ema50: score += 1; reasons.append(f"Fiyat ({price:.2f}), 50 periyotluk EMA'nın ({ema50:.2f}) üzerinde (Yükseliş Trendi).")
            else: score -= 1; reasons.append(f"Fiyat ({price:.2f}), 50 periyotluk EMA'nın ({ema50:.2f}) altında (Düşüş Trendi).")

        if macd_line is not None and signal_line is not None:
            if macd_line > signal_line: score += 2; reasons.append("MACD çizgisi, sinyal çizgisini yukarı kesmiş (Al Sinyali).")
            else: score -= 2; reasons.append("MACD çizgisi, sinyal çizgisini aşağı kesmiş (Sat Sinyali).")
        
        if not reasons:
             return {
                "score": 0, "verdict": "Yetersiz Veri",
                "recommendation": "Teknik analiz için yeterli geçmiş veri bulunamadı.",
                "reasons": []
            }

        if score >= 3:
            verdict = "Güçlü Pozitif"
            recommendation = "Teknik göstergeler kısa vadede güçlü bir yükseliş potansiyeline işaret ediyor."
        elif score >= 1:
            verdict = "Nötr-Pozitif"
            recommendation = "Teknik görünüm pozitif ancak teyit için daha fazla sinyal beklenebilir."
        elif score <= -3:
            verdict = "Güçlü Negatif"
            recommendation = "Teknik görünüm zayıf. Düşüş baskısının devam etme olasılığı mevcut."
        else:
            verdict = "Nötr"
            recommendation = "Piyasa yatay bir seyir izliyor ve net bir yön sinyali bulunmuyor."
        
        return {
            "score": score,
            "verdict": verdict,
            "recommendation": recommendation,
            "reasons": reasons
        }