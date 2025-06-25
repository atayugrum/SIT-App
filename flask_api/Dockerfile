# Python 3.10'un hafif bir versiyonunu temel al
FROM python:3.10-slim

# Sunucuda /app adında bir çalışma klasörü oluştur
WORKDIR /app

# Önce sadece requirements dosyasını kopyala ve kütüphaneleri kur
# Bu, kodunuz değiştiğinde her seferinde kütüphaneleri yeniden kurmayı engeller
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Tüm proje kodunu (/app klasörünün içine) kopyala
COPY . .

# Render'ın uygulamanıza ulaşabilmesi için 10000 portunu aç
EXPOSE 10000

# Uygulamayı başlatacak olan komut
# Not: 'main:app' kısmını, ana python dosyanızın adı 'main.py' 
# ve içindeki Flask nesnenizin adı 'app' ise bu şekilde bırakın.
# Eğer dosyanızın adı 'app.py' ise 'app:app' olarak değiştirin.
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:10000", "run:app"]