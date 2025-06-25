// File: flutter_app/lib/src/core/categories.dart
import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// HARCAMA KATEGORİLERİ (EXPENSE)
// -----------------------------------------------------------------------------

/// Ana harcama kategorileri ve ikonları
const Map<String, IconData> expenseCategories = {
  'Ev & Faturalar': Icons.home_work_outlined,
  'Market & Gıda': Icons.shopping_basket_outlined,
  'Ulaşım': Icons.directions_car_filled_outlined,
  'Kişisel Bakım': Icons.face_retouching_natural_outlined,
  'Sağlık & Spor': Icons.health_and_safety_outlined,
  'Eğlence & Sosyal Yaşam': Icons.celebration_outlined,
  'Giyim & Aksesuar': Icons.checkroom_outlined,
  'Finansal Giderler': Icons.account_balance_outlined,
  'Diğer': Icons.category_outlined,
};

/// Her harcama kategorisi için detaylı alt kategoriler
const Map<String, List<String>> expenseSubcategories = {
  'Ev & Faturalar': [
    'Kira Gideri',
    'Aidat',
    'Elektrik Faturası',
    'Su Faturası',
    'Doğalgaz & Isınma',
    'İnternet Faturası',
    'Cep Telefonu Faturası',
    'Dijital Abonelikler (Netflix, Spotify vb.)',
    'Ev Eşyası & Tadilat',
  ],
  'Market & Gıda': [
    'Süpermarket Alışverişi',
    'Restoran & Kafe',
    'Kahve Dükkanları',
    'Dışarıdan Sipariş (Yemeksepeti, Getir vb.)',
    'Fırın & Pastane',
  ],
  'Ulaşım': [
    'Toplu Taşıma (Aylık Akbil/Kart)',
    'Tek Bilet & Dolum',
    'Taksi',
    'Yakıt (Benzin/Dizel)',
    'Araç Bakım & Sigorta',
    'Park & Otoyol Ücretleri',
  ],
  'Kişisel Bakım': [
    'Kozmetik & Cilt Bakımı',
    'Kuaför & Berber',
    'Kişisel Hijyen Ürünleri',
  ],
  'Sağlık & Spor': [
    'İlaç & Vitamin',
    'Doktor & Muayene Ücreti',
    'Diş Hekimi',
    'Spor Salonu Üyeliği',
    'Spor Malzemeleri',
  ],
  'Eğlence & Sosyal Yaşam': [
    'Sinema, Tiyatro, Konser',
    'Hobi & Aktiviteler',
    'Kitap & Dergi',
    'Tatil & Seyahat',
    'Barlar & Gece Hayatı',
  ],
  'Giyim & Aksesuar': [
    'Kıyafet',
    'Ayakkabı',
    'Aksesuar & Çanta',
    'Kuru Temizleme',
  ],
  'Finansal Giderler': [
    'Kredi Kartı Borcu Ödemesi',
    'Kredi Taksiti Ödemesi',
    'Banka Masrafları (EFT, Havale vb.)',
    'Vergiler',
  ],
  'Diğer': [
    'Evcil Hayvan Masrafları',
    'Hediye',
    'Bağış',
    'Eğitim & Kurslar',
    'Diğer Harcamalar',
  ],
};

// -----------------------------------------------------------------------------
// GELİR KATEGORİLERİ (INCOME)
// -----------------------------------------------------------------------------

/// Ana gelir kategorileri ve ikonları
const Map<String, IconData> incomeCategories = {
  'Maaş & Hak Edişler': Icons.work_history_outlined,
  'Yatırım Gelirleri': Icons.trending_up_outlined,
  'Ek Gelirler': Icons.add_card_outlined,
};

/// Her gelir kategorisi için detaylı alt kategoriler
const Map<String, List<String>> incomeSubcategories = {
  'Maaş & Hak Edişler': [
    'Aylık Maaş',
    'Prim & Bonus',
    'Fazla Mesai',
    'Serbest Meslek (Freelance)',
  ],
  'Yatırım Gelirleri': [
    'Faiz Geliri (Mevduat vb.)',
    'Temettü (Dividend)',
    'Hisse Senedi Satış Karı',
    'Kripto Varlık Satış Karı',
    'Kira Geliri',
  ],
  'Ek Gelirler': [
    'Satılan Eşya (Letgo, Dolap vb.)',
    'Hediye & Burs',
    'Vergi İadesi',
    'Diğer Ek Gelirler',
  ],
};
