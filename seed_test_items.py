# File: seed_test_items.py (Proje ana dizinine kaydedin)
import os
import firebase_admin
from firebase_admin import credentials, firestore

# --- YENİ BAĞLANTI KODU ---
# 1. Servis hesabı anahtarınızın yolunu ortam değişkeninden alın.
#    Bu, bir önceki adımda ayarladığımız GOOGLE_APPLICATION_CREDENTIALS değişkenidir.
cred_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')

if not cred_path:
    # Lütfen bir önceki yanıttaki adımları takip ederek bu ortam değişkenini ayarladığınızdan emin olun.
    raise ValueError("GOOGLE_APPLICATION_CREDENTIALS ortam değişkeni ayarlanmamış.")

# 2. Firebase Admin SDK'yı başlatın.
#    Eğer zaten başka bir yerde başlatılmamışsa, bu betik başlatır.
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    print("Firebase Admin SDK başlatıldı.")
else:
    print("Firebase Admin SDK zaten başlatılmış.")

# 3. Firestore veritabanı istemcisini alın.
db = firestore.client()
# --- YENİ BAĞLANTI KODU SONU ---


def seed_data():
    if db is None:
        print("Firestore bağlantısı kurulamadı. Betik durduruluyor.")
        return

    items_collection = db.collection('FinanceTestItems')
    print("Mevcut test maddeleri siliniyor ve yenileri ekleniyor...")
    
    # Koleksiyondaki eski belgeleri temizle (opsiyonel)
    for doc in items_collection.stream():
        doc.reference.delete()

    test_items = [
        # Finansal Okuryazarlık (FO) - 5 Madde
        {"id": "fo_1", "scale": "FO", "questionText": "1000 TL’yi %5 yıllık basit faizle bankaya yatırırsanız 3 yıl sonunda toplam paranız kaç TL olur?", "choices": {"A": "1050", "B": "1150", "C": "1150 + faiz", "D": "1150 × faiz", "E": "Emin değilim"}, "correctChoice": "B"},
        {"id": "fo_2", "scale": "FO", "questionText": "200 TL bugün %10 bileşik faizle 2 yıl tutulursa yaklaşık değeri ne olur?", "choices": {"A": "220", "B": "240", "C": "242", "D": "260", "E": "Emin değilim"}, "correctChoice": "C"},
        {"id": "fo_3", "scale": "FO", "questionText": "Tasarruf hesabınız %3 getiriyor, enflasyon %5 ise gerçek satın alma gücünüz…", "choices": {"A": "Artar", "B": "Aynı kalır", "C": "Azalır", "D": "Belirsiz", "E": "Emin değilim"}, "correctChoice": "C"},
        {"id": "fo_4", "scale": "FO", "questionText": "Piyasa faizleri yükseldiğinde sabit kuponlu tahvilinizin fiyatı genelde…", "choices": {"A": "Yükselir", "B": "Değişmez", "C": "Düşer", "D": "Önemli değil", "E": "Emin değilim"}, "correctChoice": "C"},
        {"id": "fo_5", "scale": "FO", "questionText": "“Hisse senedi + tahvil + nakit” karışımı, tek bir hisse senedine kıyasla riski…", "choices": {"A": "Artırır", "B": "Aynı tutar", "C": "Azaltır", "D": "Belirleyemez", "E": "Emin değilim"}, "correctChoice": "C"},

        # Finansal İyi-Oluş (FWB) - 5 Madde (Likert-5)
        {"id": "fwb_1", "scale": "FWB", "questionText": "Gelirimin çoğunu karşılamakta zorlanmadan faturalarımı öderim.", "reverseScored": False},
        {"id": "fwb_2", "scale": "FWB", "questionText": "Aylık harcamalarımı kolayca tahmin edebilir ve planlayabilirim.", "reverseScored": False},
        {"id": "fwb_3", "scale": "FWB", "questionText": "Kötü bir finansal sürpriz (ör. acil onarım) karşısında en az 3 aylık giderimi karşılayacak kaynağım var.", "reverseScored": False},
        {"id": "fwb_4", "scale": "FWB", "questionText": "Gelecekteki emeklilik yaşam standardım hakkında kendimi güvende hissediyorum.", "reverseScored": False},
        {"id": "fwb_5", "scale": "FWB", "questionText": "Parayla ilgili stresim genel yaşam kalitemi olumsuz etkilemez.", "reverseScored": False},

        # Risk Toleransı (RT) - 10 Madde (Likert-7)
        {"id": "rt_1", "scale": "RT", "questionText": "Piyasa dalgalanmaları yüksek olsa bile uzun vadede daha yüksek getiri için riske girmeye hazırım.", "reverseScored": False},
        {"id": "rt_2", "scale": "RT", "questionText": "Portföyümün bir yıl içinde %20 değer kaybetmesi beni rahatsız etmez.", "reverseScored": False},
        {"id": "rt_3", "scale": "RT", "questionText": "Yeni, az bilinen finansal ürünleri denemekten keyif alırım.", "reverseScored": False},
        {"id": "rt_4", "scale": "RT", "questionText": "“Yüksek risk = yüksek getiri” ifadesine katılıyorum.", "reverseScored": False},
        {"id": "rt_5", "scale": "RT", "questionText": "Güvenli bir mevduat hesabını, dalgalı ama potansiyeli yüksek borsaya tercih ederim.", "reverseScored": True},
        {"id": "rt_6", "scale": "RT", "questionText": "Bir yatırımın geçmişteki kayıpları beni o yatırımdan tamamen vazgeçirir.", "reverseScored": True},
        {"id": "rt_7", "scale": "RT", "questionText": "Uzun vadeli hedeflerim için, kısa vadeli portföy kayıplarını normal karşılarım.", "reverseScored": False},
        {"id": "rt_8", "scale": "RT", "questionText": "Finans haberlerini yakından takip eder ve buna göre sık sık pozisyonumu değiştiririm.", "reverseScored": False},
        {"id": "rt_9", "scale": "RT", "questionText": "Emeklilik fonumun %60'ından fazlasını hisse senetlerine ayırmak bana mantıklı geliyor.", "reverseScored": False},
        {"id": "rt_10", "scale": "RT", "questionText": "Daha düşük ama garanti bir getiri yerine, daha yüksek ama belirsiz bir getiriyi tercih ederim.", "reverseScored": False},
        
        # Finansal Kabiliyet (FCAP) - 20 Madde (Freq-5)
        {"id": "fcap_1", "scale": "FCAP", "questionText": "Ay başında detaylı bir bütçe hazırlarım.", "reverseScored": False},
        {"id": "fcap_2", "scale": "FCAP", "questionText": "Gerçekleşen harcamalarımı bütçemle düzenli olarak karşılaştırırım.", "reverseScored": False},
        {"id": "fcap_3", "scale": "FCAP", "questionText": "Gelirimin en az %10’unu düzenli olarak birikim veya yatırım hesabına aktarırım.", "reverseScored": False},
        {"id": "fcap_4", "scale": "FCAP", "questionText": "Finansal işlemlerim için mobil bankacılık veya dijital cüzdan uygulamalarını aktif olarak kullanırım.", "reverseScored": False},
        {"id": "fcap_5", "scale": "FCAP", "questionText": "Kredi kartı borcumun dönem sonunda tamamını öderim.", "reverseScored": False},
        {"id": "fcap_6", "scale": "FCAP", "questionText": "Önemli bir harcama yapmadan önce farklı satıcılardan fiyat karşılaştırması yaparım.", "reverseScored": False},
        {"id": "fcap_7", "scale": "FCAP", "questionText": "Finansal bir karar verirken (kredi, yatırım vb.) güvenilir kaynaklardan araştırma yaparım.", "reverseScored": False},
        {"id": "fcap_8", "scale": "FCAP", "questionText": "Parasal hedeflerime (ör. tatil, eğitim fonu) ulaşmak için bir zaman çizelgesi belirlerim.", "reverseScored": False},
        {"id": "fcap_9", "scale": "FCAP", "questionText": "Acil durumlar için ayırdığım birikimi düzenli olarak kontrol ederim.", "reverseScored": False},
        {"id": "fcap_10", "scale": "FCAP", "questionText": "Sahip olduğum sigorta poliçelerini (sağlık, araç vb.) en az yılda bir kez gözden geçiririm.", "reverseScored": False},
        {"id": "fcap_11", "scale": "FCAP", "questionText": "Beklenmedik bir gelir (prim, ikramiye) elde ettiğimde, bunu öncelikle borçlarımı azaltmak veya tasarrufa yönlendirmek için kullanırım.", "reverseScored": False},
        {"id": "fcap_12", "scale": "FCAP", "questionText": "Yatırım kararlarımı anlık duygular yerine veri ve analizlere dayanarak alırım.", "reverseScored": False},
        {"id": "fcap_13", "scale": "FCAP", "questionText": "Uzun vadeli yatırımlarımı farklı varlık türleri (hisse, fon, döviz vb.) arasında çeşitlendiririm.", "reverseScored": False},
        {"id": "fcap_14", "scale": "FCAP", "questionText": "Vergi avantajı sağlayan yatırım veya birikim ürünlerini (BES vb.) aktif olarak değerlendiririm.", "reverseScored": False},
        {"id": "fcap_15", "scale": "FCAP", "questionText": "Finansal taahhütlerimi (taksit, abonelik vb.) ödeme gününden önce planlarım ve hazırlarım.", "reverseScored": False},
        {"id": "fcap_16", "scale": "FCAP", "questionText": "Finansal hedeflerimi ve planlarımı ailemle veya partnerimle açıkça konuşurum.", "reverseScored": False},
        {"id": "fcap_17", "scale": "FCAP", "questionText": "En az yılda bir kez genel finansal durumumu (net değer, borç/varlık oranı) değerlendiririm.", "reverseScored": False},
        {"id": "fcap_18", "scale": "FCAP", "questionText": "Kullanmadığım abonelikleri (dijital platformlar, dergiler vb.) düzenli olarak kontrol eder ve iptal ederim.", "reverseScored": False},
        {"id": "fcap_19", "scale": "FCAP", "questionText": "Kredi veya borçlanma ihtiyacım olduğunda, farklı bankaların faiz oranlarını ve şartlarını karşılaştırırım.", "reverseScored": False},
        {"id": "fcap_20", "scale": "FCAP", "questionText": "Kullandığım finansal ürünlerin (fon, kredi, sigorta) kesinti ve masraf oranlarını bilirim.", "reverseScored": False},
    ]

    batch = db.batch()
    for item in test_items:
        doc_ref = items_collection.document(item['id'])
        batch.set(doc_ref, item)
    
    batch.commit()
    print(f"Başarıyla {len(test_items)} adet test maddesi Firestore'a eklendi.")

if __name__ == '__main__':
    seed_data()