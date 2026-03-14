// File: flutter_app/lib/src/core/categories.dart
import 'package:flutter/cupertino.dart';

// ─── Harcama Kategorileri ────────────────────────────────────────────────────

const Map<String, IconData> expenseCategories = {
  'Ev & Faturalar':          CupertinoIcons.house_fill,
  'Market & Gıda':           CupertinoIcons.cart_fill,
  'Ulaşım':                  CupertinoIcons.car_fill,
  'Kişisel Bakım':           CupertinoIcons.person_crop_circle_fill,
  'Sağlık & Spor':           CupertinoIcons.heart_fill,
  'Eğlence & Sosyal Yaşam':  CupertinoIcons.star_fill,
  'Giyim & Aksesuar':        CupertinoIcons.tag_fill,
  'Finansal Giderler':       CupertinoIcons.building_2_fill,
  'Diğer':                   CupertinoIcons.square_grid_2x2_fill,
};

const Map<String, List<String>> expenseSubcategories = {
  'Ev & Faturalar': [
    'Kira Gideri', 'Aidat', 'Elektrik Faturası', 'Su Faturası',
    'Doğalgaz & Isınma', 'İnternet Faturası', 'Cep Telefonu Faturası',
    'Dijital Abonelikler (Netflix, Spotify vb.)', 'Ev Eşyası & Tadilat',
  ],
  'Market & Gıda': [
    'Süpermarket Alışverişi', 'Restoran & Kafe', 'Kahve Dükkanları',
    'Dışarıdan Sipariş (Yemeksepeti, Getir vb.)', 'Fırın & Pastane',
  ],
  'Ulaşım': [
    'Toplu Taşıma (Aylık Akbil/Kart)', 'Tek Bilet & Dolum', 'Taksi',
    'Yakıt (Benzin/Dizel)', 'Araç Bakım & Sigorta', 'Park & Otoyol Ücretleri',
  ],
  'Kişisel Bakım': [
    'Kozmetik & Cilt Bakımı', 'Kuaför & Berber', 'Kişisel Hijyen Ürünleri',
  ],
  'Sağlık & Spor': [
    'İlaç & Vitamin', 'Doktor & Muayene Ücreti', 'Diş Hekimi',
    'Spor Salonu Üyeliği', 'Spor Malzemeleri',
  ],
  'Eğlence & Sosyal Yaşam': [
    'Sinema, Tiyatro, Konser', 'Hobi & Aktiviteler', 'Kitap & Dergi',
    'Tatil & Seyahat', 'Barlar & Gece Hayatı',
  ],
  'Giyim & Aksesuar': [
    'Kıyafet', 'Ayakkabı', 'Aksesuar & Çanta', 'Kuru Temizleme',
  ],
  'Finansal Giderler': [
    'Kredi Kartı Borcu Ödemesi', 'Kredi Taksiti Ödemesi',
    'Banka Masrafları (EFT, Havale vb.)', 'Vergiler',
  ],
  'Diğer': [
    'Evcil Hayvan Masrafları', 'Hediye', 'Bağış',
    'Eğitim & Kurslar', 'Diğer Harcamalar',
  ],
};

// ─── Gelir Kategorileri ──────────────────────────────────────────────────────

const Map<String, IconData> incomeCategories = {
  'Maaş & Hak Edişler':  CupertinoIcons.briefcase_fill,
  'Yatırım Gelirleri':   CupertinoIcons.graph_circle_fill,
  'Ek Gelirler':         CupertinoIcons.plus_circle_fill,
};

const Map<String, List<String>> incomeSubcategories = {
  'Maaş & Hak Edişler': [
    'Aylık Maaş', 'Prim & Bonus', 'Fazla Mesai', 'Serbest Meslek (Freelance)',
  ],
  'Yatırım Gelirleri': [
    'Faiz Geliri (Mevduat vb.)', 'Temettü (Dividend)', 'Hisse Senedi Satış Karı',
    'Kripto Varlık Satış Karı', 'Kira Geliri',
  ],
  'Ek Gelirler': [
    'Satılan Eşya (Letgo, Dolap vb.)', 'Hediye & Burs',
    'Vergi İadesi', 'Diğer Ek Gelirler',
  ],
};
