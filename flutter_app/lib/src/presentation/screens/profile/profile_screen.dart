// File: lib/src/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_providers.dart';
import '../../providers/profile_providers.dart';
import '../../../data/models/user_profile_model.dart';
import 'edit_profile_screen.dart';
import '../settings/manage_categories_screen.dart';
import 'finance_test_intro_screen.dart';
import '../settings/preferences_screen.dart';
import 'latest_test_result_wrapper_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getRiskProfileDisplayName(String? profile) {
    switch (profile?.toLowerCase()) {
      case 'low':
        return 'Düşük Risk';
      case 'medium':
        return 'Orta Risk';
      case 'high':
        return 'Yüksek Risk';
      default:
        return 'Henüz Belirlenmedi';
    }
  }
  
  // --- YENİ EKLENEN METOT ---
  // Kullanıcıdan hesap silme onayı almak için bir dialog gösterir.
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Hesabınızı Silin'),
              content: const Text(
                  'Bu işlem geri alınamaz. Hesabınız ve tüm finansal verileriniz (işlemler, bütçeler, yatırımlar vb.) kalıcı olarak silinecektir. Devam etmek istediğinizden emin misiniz?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Onaylanmadı
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('EVET, SİL'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // Onaylandı
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Dialog bir şekilde kapanırsa, onaylanmamış say
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? firebaseUser = ref.watch(currentUserProvider);
    final userProfileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Profili Yenile',
            onPressed: () => ref.invalidate(userProfileProvider),
          ),
        ],
      ),
      body: userProfileAsyncValue.when(
        data: (UserProfile? userProfile) {
          if (userProfile == null || firebaseUser == null) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Profil bilgileri yüklenemedi.'),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: const Text('Tekrar Dene')),
              ],
            ));
          }
          return _buildProfileView(context, firebaseUser, userProfile, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Profil yüklenirken hata oluştu: $error')),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, User firebaseUser,
      UserProfile userProfile, WidgetRef ref) {
    final theme = Theme.of(context);
    final Color primaryColor = Colors.teal.shade700;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, size: 60, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(userProfile.fullName,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('@${userProfile.username}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey.shade600)),
                  const Divider(height: 32),
                  _buildProfileListItem(
                      context,
                      Icons.email_outlined,
                      'E-posta Adresi',
                      firebaseUser.email ?? 'N/A',
                      primaryColor),
                  _buildProfileListItem(context, Icons.cake_outlined,
                      'Doğum Tarihi', userProfile.birthDate, primaryColor),
                  _buildProfileListItem(
                    context,
                    Icons.shield_outlined,
                    'Risk Profiliniz',
                    _getRiskProfileDisplayName(userProfile.riskProfile),
                    primaryColor,
                    onTap: userProfile.riskProfile != null
                        ? () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                const LatestTestResultWrapperScreen()))
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            color: primaryColor,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              leading: Icon(Icons.psychology_outlined,
                  color: Colors.white.withOpacity(0.9), size: 32),
              title: Text("Finansal Profil Testi",
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text("Risk ve finansal alışkanlıklarınızı ölçün",
                  style: TextStyle(color: Colors.white.withOpacity(0.8))),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: Colors.white),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const FinanceTestIntroScreen())),
            ),
          ),
          const SizedBox(height: 24),
          _buildActionCard(context, "Hesap ve Ayarlar", [
            () => _buildActionButton(
                context,
                'Profil Detaylarını Düzenle',
                Icons.edit_note_outlined,
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        EditProfileScreen(initialProfile: userProfile)))),
            () => _buildActionButton(
                context,
                'Özel Kategorileri Yönet',
                Icons.category_outlined,
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ManageCategoriesScreen()))),
            () => _buildActionButton(
                context,
                'Uygulama Tercihleri',
                Icons.tune_rounded,
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PreferencesScreen()))),
            
            // --- HESAP SİLME BUTONU VE MANTIĞI ---
            () => _buildActionButton(
                  context,
                  'Hesabımı Sil',
                  Icons.delete_forever,
                  () async {
                    final bool confirmed = await _showDeleteConfirmationDialog(context);
                    
                    if (confirmed && context.mounted) {
                      try {
                        await ref.read(profileServiceProvider).deleteUserAccount(firebaseUser.uid);
                        await ref.read(authServiceProvider).signOut();
                        
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hesabınız başarıyla silindi.'), backgroundColor: Colors.green),
                          );
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Hata: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  },
                  isDestructive: true,
                ),

            () => _buildActionButton(context, 'Çıkış Yap', Icons.logout,
                    () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                }, isDestructive: true),
          ]),
          const SizedBox(height: 20), // Alt boşluk
        ],
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context, String title, List<Widget Function()> actions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 4.0),
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey.shade700)),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              itemBuilder: (context, index) => actions[index](),
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 56),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: isDestructive
          ? null
          : Icon(Icons.arrow_forward_ios,
              size: 14, color: Colors.grey.shade500),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildProfileListItem(BuildContext context, IconData icon,
      String label, String value, Color iconColor,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor.withOpacity(0.8)),
      title: Text(label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: Colors.grey.shade700)),
      subtitle: Text(value,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
      trailing:
          onTap != null ? const Icon(Icons.arrow_forward_ios, size: 14) : null,
      onTap: onTap,
    );
  }
}