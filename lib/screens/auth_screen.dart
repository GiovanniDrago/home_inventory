import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/house_provider.dart';
import '../providers/rooms_provider.dart';
import '../providers/categories_provider.dart';
import '../services/supabase_service.dart';
import 'house_onboarding_screen.dart';
import 'main_shell.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);
    ref.read(authLoadingProvider.notifier).state = true;

    try {
      if (_isSignUp) {
        // Check uniqueness
        final nicknameTaken = await SupabaseService.isNicknameTaken(_nicknameController.text.trim());
        if (nicknameTaken) {
          setState(() => _errorMessage = AppLocalizations.of(context)!.nicknameTaken);
          ref.read(authLoadingProvider.notifier).state = false;
          return;
        }

        final emailTaken = await SupabaseService.isEmailTaken(_emailController.text.trim());
        if (emailTaken) {
          setState(() => _errorMessage = AppLocalizations.of(context)!.emailTaken);
          ref.read(authLoadingProvider.notifier).state = false;
          return;
        }

        final response = await SupabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.session != null) {
          await SupabaseService.createProfile(
            userId: response.user!.id,
            nickname: _nicknameController.text.trim(),
            email: _emailController.text.trim(),
          );
          await ref.read(profileProvider.notifier).refresh();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HouseOnboardingScreen()),
            );
          }
        } else if (response.user != null) {
          setState(() => _errorMessage = AppLocalizations.of(context)!.emailTaken);
          ref.read(authLoadingProvider.notifier).state = false;
          return;
        }
      } else {
        final response = await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null) {
          await ref.read(profileProvider.notifier).refresh();
          var profile = ref.read(profileProvider).value;

          if (profile == null) {
            final user = response.user!;
            final email = user.email ?? _emailController.text.trim();
            final nickname = email.split('@').first;
            await SupabaseService.createProfile(
              userId: user.id,
              nickname: nickname,
              email: email,
            );
            await ref.read(profileProvider.notifier).refresh();
            profile = ref.read(profileProvider).value;
          }

          if (mounted) {
            if (profile?.houseId != null) {
              await ref.read(houseProvider.notifier).loadHouse(profile!.houseId);
              await ref.read(roomsProvider.notifier).loadRooms(profile.houseId!);
              await ref.read(categoriesProvider.notifier).loadCategories(profile.houseId!);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainShell()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HouseOnboardingScreen()),
              );
            }
          }
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      debugPrint('_submit error: $e');
      setState(() => _errorMessage = e.toString());
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authLoadingProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Icon(
                  Icons.home_work_outlined,
                  size: 64,
                  color: scheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  _isSignUp ? l10n.signUp : l10n.signIn,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_isSignUp)
                  TextFormField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      labelText: l10n.nickname,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.requiredField;
                      }
                      return null;
                    },
                  ),
                if (_isSignUp) const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.requiredField;
                    }
                    if (!value.contains('@')) {
                      return l10n.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.requiredField;
                    }
                    if (_isSignUp && value.length < 6) {
                      return l10n.passwordTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: scheme.error),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? l10n.signUp : l10n.signIn),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? ${l10n.signIn}'
                        : 'Need an account? ${l10n.signUp}',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }
}
