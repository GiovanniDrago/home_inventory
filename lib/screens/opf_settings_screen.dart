import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import '../models/opf_credentials.dart';
import '../providers/opf_credentials_provider.dart';

class OpfSettingsScreen extends ConsumerStatefulWidget {
  const OpfSettingsScreen({super.key});

  @override
  ConsumerState<OpfSettingsScreen> createState() => _OpfSettingsScreenState();
}

class _OpfSettingsScreenState extends ConsumerState<OpfSettingsScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(opfCredentialsProvider);
    if (existing != null) {
      _usernameController.text = existing.username;
      _passwordController.text = existing.password;
    }
  }

  Future<void> _save() async {
    if (_usernameController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await ref.read(opfCredentialsProvider.notifier).save(
          OpfCredentials(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          ),
        );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open Products Facts login saved')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _clear() async {
    await ref.read(opfCredentialsProvider.notifier).clear();
    _usernameController.clear();
    _passwordController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credentials removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Products Facts Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: scheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Open Products Facts Login',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your Open Products Facts credentials to contribute missing products directly from the app.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_isSaving)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(l10n.save),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove Credentials'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
