// File: flutter_app/lib/src/core/categories.dart
import 'package:flutter/material.dart';

/// ─── Income Categories ─────────────────────────────────────────────────────

/// Top-level income categories with Material icons
const Map<String, IconData> incomeCategories = {
  'Maaş': Icons.work_outline, // Using outline icons for consistency
  'Ek Gelir': Icons.attach_money_outlined,
  'Yatırım': Icons.trending_up_outlined,
  'Hediye': Icons.card_giftcard_outlined,
  'Diğer Gelir': Icons.category_outlined,
};

/// Subcategories for each income category
const Map<String, List<String>> incomeSubcategories = {
  'Maaş': [
    'Ana Maaş',
    'Prim',
    'Bonus',
    'Fazla Mesai',
  ],
  'Ek Gelir': [
    'Freelance',
    'Kira Geliri', // Clarified "Kira" for income
    'Komisyon',
    'Yan İş',
  ],
  'Yatırım': [
    'Faiz Geliri', // Clarified "Faiz"
    'Temettü',
    'Alım-Satım Karı',
    'Kur Kazancı',
  ],
  'Hediye': [
    'Doğum Günü',
    'Tatil Hediyesi',
    'Ödül',
    'Alınan Bağış', // Clarified "Bağış" for income
  ],
  'Diğer Gelir': [
    'Arızi Gelir',
    'Diğer',
  ],
};

/// ─── Expense Categories ────────────────────────────────────────────────────

/// Top-level expense categories with Material icons
const Map<String, IconData> expenseCategories = {
  'Market': Icons.shopping_cart_outlined,
  'Ulaşım': Icons.directions_car_outlined, // Changed for consistency
  'Eğlence': Icons.celebration_outlined,
  'Fatura': Icons.receipt_long_outlined,
  'Sağlık': Icons.local_hospital_outlined,
  'Kira Gideri': Icons.house_outlined, // Differentiated from income "Kira"
  'Eğitim': Icons.school_outlined,
  'Giyim': Icons.checkroom_outlined,
  'Seyahat': Icons.flight_takeoff_outlined, // Changed for consistency
  'Ev Bakım': Icons.build_outlined,
  'Sigorta': Icons.shield_outlined,
  'Vergi': Icons.account_balance_outlined,
  'Yardım/Bağış Gideri': Icons.volunteer_activism_outlined, // Differentiated
  'Diğer Gider': Icons.category_outlined,
};

/// Subcategories for each expense category
const Map<String, List<String>> expenseSubcategories = {
  'Market': [
    'Gıda',
    'Yiyecek & İçecek',
    'Temizlik Malzemesi', // Clarified
    'Kişisel Bakım', // Added common one
    'Kırtasiye',
    'Şarküteri',
  ],
  'Ulaşım': [
    'Yakıt',
    'Toplu Taşıma', // More general
    'Taksi', // Simplified
    'Araç Bakım', // Clarified
    'Park Ücreti',
    'Otoyol/Köprü Geçiş', // Added
  ],
  'Eğlence': [
    'Sinema/Tiyatro', // Combined
    'Restoran/Kafe', // Combined
    'Konser/Etkinlik', // Combined
    'Oyun/Hobi', // Combined
    'Kitap/Dergi', // Added
    'Dijital Abonelikler (Netflix, Spotify vb.)', // Added
  ],
  'Fatura': [
    'Elektrik',
    'Su',
    'Doğalgaz/Isınma', // Clarified
    'İnternet',
    'Telefon (Mobil/Sabit)', // Combined
    'TV & Dijital Yayın', // Clarified
    'Aidat', // Added
  ],
  'Sağlık': [
    'Hastane/Doktor Muayenesi', // Combined
    'İlaç',
    'Dişçi',
    'Gözlük/Lens', // Combined
    'Terapi/Danışmanlık', // Added
  ],
  'Kira Gideri': [ // Matched category name
    'Konut Kirası',
    'Oda/Kısmî Kira',
    'Depozito Ödemesi', // Clarified
  ],
  'Eğitim': [
    'Kurs & Seminer Ücreti', // Clarified
    'Okul/Üniversite Harcı', // Clarified
    'Kitap/Eğitim Materyali', // Combined
  ],
  'Giyim': [
    'Günlük Giyim', // More general
    'İş Kıyafeti', // Added
    'Ayakkabı',
    'Aksesuar',
    'Çocuk Giyim', // Added
  ],
  'Seyahat': [
    'Uçak/Tren/Otobüs Bileti', // Combined
    'Otel/Konaklama', // Clarified
    'Vize/Pasaport Ücreti', // Clarified
    'Tur & Gezi Harcaması', // Clarified
    'Seyahat İçi Harcamalar', // Added
  ],
  'Ev Bakım': [
    'Tamirat/Tadilat', // Combined
    'Mobilya/Beyaz Eşya', // Combined
    'Dekorasyon',
    'Bahçe/Balkon Bakım', // Combined
    'Ev Aletleri', // Added
  ],
  'Sigorta': [
    'Sağlık Sigortası',
    'Araç Sigortası (Kasko/Trafik)', // Combined
    'Konut Sigortası (DASK vb.)', // Combined
    'Seyahat Sigortası',
    'Hayat Sigortası', // Added
  ],
  'Vergi': [
    'Emlak Vergisi',
    'Gelir Vergisi Ödemesi', // Clarified
    'Motorlu Taşıtlar Vergisi (MTV)', // Clarified
    'Diğer Resmi Ödemeler', // Added
  ],
  'Yardım/Bağış Gideri': [ // Matched category name
    'Vakıf Bağışı', // Clarified
    'Dernek Bağışı', // Clarified
    'Kişisel Yardımlar', // Added
    'Sosyal Sorumluluk Projesi Katkısı', // Clarified
  ],
  'Diğer Gider': [
    'Hediye Alımı', // Clarified
    'Arızi Gider',
    'Banka Masrafları', // Added
    'Evcil Hayvan Masrafı', // Added
    'Diğer Tanımsız Giderler', // Clarified
  ],
};