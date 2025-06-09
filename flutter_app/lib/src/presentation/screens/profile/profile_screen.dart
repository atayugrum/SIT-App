// File: lib/src/presentation/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import '../../providers/auth_providers.dart';
import '../../providers/profile_providers.dart';
import '../../../data/models/user_profile_model.dart'; 
import 'edit_profile_screen.dart'; 
import '../settings/manage_categories_screen.dart';
import 'finance_test_intro_screen.dart';
// YENİ EKLENEN EKRANLARIN IMPORTLARI
import 'change_password_screen.dart';
import 'change_email_screen.dart';
import 'icon_selection_screen.dart';
import '../settings/preferences_screen.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
                const SizedBox(height: 3),
                Text(value != null && value.isNotEmpty ? value : 'Belirlenmedi', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, User firebaseUser, UserProfile userProfile, WidgetRef ref) {
    final theme = Theme.of(context);
    Widget profileIconWidget;
    final iconId = userProfile.profileIconId;

    if (iconId != null && iconId.isNotEmpty && iconId.startsWith('icon-')) {
      profileIconWidget = SvgPicture.asset(
        'assets/icons/$iconId.svg', 
        width: 120,
        height: 120,
        placeholderBuilder: (BuildContext context) => CircleAvatar(
          radius: 60,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(Icons.person_outline, size: 70,  color: theme.colorScheme.onSecondaryContainer),
        ),
      );
    } else {
      profileIconWidget = CircleAvatar(
        radius: 60,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          userProfile.fullName.isNotEmpty ? userProfile.fullName[0].toUpperCase() : "?",
          style: TextStyle(fontSize: 50, color: theme.colorScheme.onPrimaryContainer),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          profileIconWidget,
          const SizedBox(height: 16),
          Text(
            userProfile.fullName,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '@${userProfile.username}',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow(context, Icons.email_outlined, 'E-posta Adresi', firebaseUser.email),
                  const Divider(height: 24, thickness: 0.5),
                  _buildInfoRow(context, Icons.cake_outlined, 'Doğum Tarihi', userProfile.birthDate),
                   const Divider(height: 24, thickness: 0.5),
                  _buildInfoRow(context, Icons.shield_outlined, 'Risk Profiliniz', userProfile.riskProfile),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(Icons.psychology_outlined, color: theme.colorScheme.onSecondaryContainer),
              ),
              title: Text("Finansal Profil Testi", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: const Text("Risk toleransınızı ve finansal sağlığınızı ölçün."),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceTestIntroScreen()));
              },
            ),
          ),
          
          const SizedBox(height: 32),

          // --- YENİ EKLENEN BUTONLAR ---
          _buildActionButton(
            context: context,
            icon: Icons.edit_note_outlined,
            label: 'Profil Detaylarını Düzenle',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditProfileScreen(initialProfile: userProfile)),
              ).then((value) {
                if (value == true) ref.invalidate(userProfileProvider);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            icon: Icons.image_outlined,
            label: 'Profil İkonu Değiştir',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IconSelectionScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            icon: Icons.lock_outline_rounded,
            label: 'Şifre Değiştir',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
            },
          ),
          const SizedBox(height: 12),
           _buildActionButton(
            context: context,
            icon: Icons.alternate_email_rounded,
            label: 'E-posta Değiştir',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangeEmailScreen()));
            },
          ),
           const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            icon: Icons.tune_rounded,
            label: 'Uygulama Tercihleri',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PreferencesScreen()));
            },
          ),
           const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            icon: Icons.category_outlined,
            label: 'Özel Kategorileri Yönet',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()));
            },
          ),
        ],
      ),
    );
  }

  // Butonlar için yardımcı bir widget
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? firebaseUser = ref.watch(currentUserProvider);
    final userProfileAsyncValue = ref.watch(userProfileProvider); 
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userProfileProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: firebaseUser == null
          ? const Center(child: Text('Profilinizi görmek için lütfen giriş yapın.'))
          : userProfileAsyncValue.when(
              data: (UserProfile? userProfile) {
                if (userProfile == null) {
                  return Center(child: ElevatedButton(onPressed: () => ref.invalidate(userProfileProvider), child: const Text('Tekrar Dene')));
                }
                return _buildProfileView(context, firebaseUser, userProfile, ref);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Profil yüklenirken hata oluştu: $error')),
            ),
    );
  }
}