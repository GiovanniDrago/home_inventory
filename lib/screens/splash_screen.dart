import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/house_provider.dart';
import '../providers/rooms_provider.dart';
import '../providers/categories_provider.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import 'house_onboarding_screen.dart';
import 'main_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Check session directly from Supabase client (synchronous, restored from storage)
    final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          await ref.read(profileProvider.notifier).refresh();
          var profile = ref.read(profileProvider).value;

          if (profile == null) {
            final user = session.user;
            final email = user.email ?? '';
            final nickname = email.isNotEmpty
                ? email.split('@').first
                : user.id.substring(0, 8);
            await SupabaseService.createProfile(
              userId: user.id,
              nickname: nickname,
              email: email,
            );
            await ref.read(profileProvider.notifier).refresh();
            profile = ref.read(profileProvider).value;
          }

          if (profile?.houseId != null) {
        await ref.read(houseProvider.notifier).loadHouse(profile!.houseId);
        await ref.read(roomsProvider.notifier).loadRooms(profile.houseId!);
        await ref.read(categoriesProvider.notifier).loadCategories(profile.houseId!);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HouseOnboardingScreen()),
          );
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Home Inventory',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
