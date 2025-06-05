// File: flutter_app/lib/src/presentation/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Direct import for User type
import 'package:flutter_svg/flutter_svg.dart'; 
import '../../providers/auth_providers.dart';
import '../../providers/profile_providers.dart';
import '../../../data/models/user_profile_model.dart'; 
import 'edit_profile_screen.dart'; 
import '../settings/manage_categories_screen.dart'; // For Manage Custom Categories

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Helper method to build info rows, kept within the class for context access
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
                Text(value != null && value.isNotEmpty ? value : 'Not set', style: theme.textTheme.titleMedium),
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
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 40.0), // Added bottom padding
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
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow(context, Icons.email_outlined, 'Email', firebaseUser.email),
                  const Divider(height: 24, thickness: 0.5),
                  _buildInfoRow(context, Icons.cake_outlined, 'Birth Date', userProfile.birthDate),
                  const Divider(height: 24, thickness: 0.5),
                  _buildInfoRow(context, Icons.shield_outlined, 'Risk Profile', userProfile.riskProfile),
                  const Divider(height: 24, thickness: 0.5),
                  _buildInfoRow(context, Icons.image_search_outlined, 'Profile Icon ID', userProfile.profileIconId),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Edit Profile Details'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50), 
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(initialProfile: userProfile),
                ),
              ).then((value) {
                if (value == true || value == null) { 
                    // ignore: unused_result
                    ref.refresh(userProfileProvider);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.category_outlined),
            label: const Text('Manage Custom Categories'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: theme.colorScheme.primary),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
              );
            },
          ),
          // TODO: Add buttons for other deferred features (Change Email, Password, Preferences, Icon Selection Screen)
          // when those screens are ready.
          // Example:
          // const SizedBox(height: 12),
          // OutlinedButton.icon(
          //   icon: const Icon(Icons.palette_outlined),
          //   label: const Text('App Preferences'),
          //   onPressed: () { /* Navigate to PreferencesScreen */ },
          //   style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), /*...*/)
          // ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? firebaseUser = ref.watch(currentUserProvider); // Explicitly type User?
    final userProfileAsyncValue = ref.watch(userProfileProvider); 
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            onPressed: () {
                // ignore: unused_result
                ref.refresh(userProfileProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (!context.mounted) return; 
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: firebaseUser == null
          ? const Center(child: Text('Please log in to view your profile.'))
          : userProfileAsyncValue.when(
              data: (UserProfile? userProfile) { // Explicitly type UserProfile?
                if (userProfile == null) {
                  return Center( 
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Profile data not found or could not be loaded.'),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              // ignore: unused_result
                              ref.refresh(userProfileProvider);
                            },
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    )
                  );
                }
                // firebaseUser is guaranteed non-null here due to the outer check
                return _buildProfileView(context, firebaseUser, userProfile, ref);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) { 
                print("PROFILE_SCREEN: Error UI: $error\n$stackTrace");
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                          const SizedBox(height: 10),
                          Text('Error loading profile: ${error.toString().replaceFirst("Exception: ", "")}', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                          const SizedBox(height:20),
                          ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text("Retry"),
                              onPressed: () {
                                // ignore: unused_result
                                ref.refresh(userProfileProvider);
                              }
                          )
                        ],
                    ),
                  )
                );
              },
            ),
    );
  }
}