// File: lib/src/presentation/screens/profile/profile_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_profile_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/glass_card.dart';
import 'edit_profile_screen.dart';
import 'finance_test_intro_screen.dart';
import 'latest_test_result_wrapper_screen.dart';
import '../settings/manage_categories_screen.dart';
import '../settings/preferences_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _riskLabel(String? profile) {
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

  Future<bool> _confirmDelete(BuildContext context) async {
    bool confirmed = false;
    await showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Hesabınızı Silin'),
        content: const Text(
            'Bu işlem geri alınamaz. Hesabınız ve tüm finansal verileriniz kalıcı olarak silinecektir. Devam etmek istediğinizden emin misiniz?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              confirmed = true;
              Navigator.of(context).pop();
            },
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );
    return confirmed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Profilim'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => ref.invalidate(userProfileProvider),
          child: const Icon(CupertinoIcons.refresh,
              color: AppColors.primaryBlue, size: 20),
        ),
      ),
      child: SafeArea(
        child: profileAsync.when(
          data: (UserProfile? profile) {
            if (profile == null || firebaseUser == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Profil bilgileri yüklenemedi.',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      onPressed: () => ref.invalidate(userProfileProvider),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              );
            }
            return _ProfileBody(
              firebaseUser: firebaseUser,
              profile: profile,
              riskLabel: _riskLabel(profile.riskProfile),
              onDeleteAccount: () async {
                final confirmed = await _confirmDelete(context);
                if (!confirmed || !context.mounted) return;
                try {
                  await ref
                      .read(profileServiceProvider)
                      .deleteUserAccount(firebaseUser.uid);
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  }
                } catch (e) {
                  if (context.mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        content: Text('Hata: $e'),
                        actions: [
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Tamam'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              onSignOut: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                }
              },
            );
          },
          loading: () =>
              const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Text('Profil yüklenirken hata oluştu: $e',
                style:
                    const TextStyle(color: AppColors.danger)),
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final User firebaseUser;
  final UserProfile profile;
  final String riskLabel;
  final VoidCallback onDeleteAccount;
  final VoidCallback onSignOut;

  const _ProfileBody({
    required this.firebaseUser,
    required this.profile,
    required this.riskLabel,
    required this.onDeleteAccount,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Identity card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.person_fill,
                    size: 44, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 12),
              Text(profile.fullName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('@${profile.username}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
              Container(
                  height: 0.5,
                  color: AppColors.separator,
                  margin: const EdgeInsets.symmetric(vertical: 16)),
              _InfoRow(
                icon: CupertinoIcons.mail,
                label: 'E-posta',
                value: firebaseUser.email ?? '-',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: CupertinoIcons.gift,
                label: 'Doğum Tarihi',
                value: profile.birthDate.isNotEmpty
                    ? profile.birthDate
                    : '-',
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: profile.riskProfile != null
                    ? () => Navigator.of(context).push(CupertinoPageRoute(
                        builder: (_) =>
                            const LatestTestResultWrapperScreen()))
                    : null,
                child: _InfoRow(
                  icon: CupertinoIcons.shield_lefthalf_fill,
                  label: 'Risk Profiliniz',
                  value: riskLabel,
                  showChevron: profile.riskProfile != null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Finance test card
        GestureDetector(
          onTap: () => Navigator.of(context).push(CupertinoPageRoute(
              builder: (_) => const FinanceTestIntroScreen())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primaryBlue, width: 0.5),
            ),
            child: const Row(
              children: [
                Icon(CupertinoIcons.lightbulb_fill,
                    color: AppColors.primaryBlue, size: 28),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Finansal Profil Testi',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Risk ve finansal alışkanlıklarınızı ölçün',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12)),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right,
                    color: AppColors.textSecondary, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Settings card
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _NavRow(
                icon: CupertinoIcons.pencil,
                label: 'Profil Detaylarını Düzenle',
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) =>
                        EditProfileScreen(initialProfile: profile))),
              ),
              _Divider(),
              _NavRow(
                icon: CupertinoIcons.tag,
                label: 'Özel Kategorileri Yönet',
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => const ManageCategoriesScreen())),
              ),
              _Divider(),
              _NavRow(
                icon: CupertinoIcons.settings,
                label: 'Uygulama Tercihleri',
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => const PreferencesScreen())),
              ),
              _Divider(),
              _NavRow(
                icon: CupertinoIcons.delete,
                label: 'Hesabımı Sil',
                isDestructive: true,
                onTap: onDeleteAccount,
              ),
              _Divider(),
              _NavRow(
                icon: CupertinoIcons.square_arrow_left,
                label: 'Çıkış Yap',
                isDestructive: true,
                onTap: onSignOut,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showChevron;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (showChevron)
          const Icon(CupertinoIcons.chevron_right,
              color: AppColors.textSecondary, size: 14),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppColors.danger : AppColors.textPrimary;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(color: color, fontSize: 15))),
          if (!isDestructive)
            const Icon(CupertinoIcons.chevron_right,
                color: AppColors.textSecondary, size: 14),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 0.5,
        color: AppColors.separator,
        margin: const EdgeInsets.only(left: 52));
  }
}
