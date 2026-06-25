import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import '../providers/auth_provider.dart';
import '../providers/house_provider.dart';
import '../providers/rooms_provider.dart';
import '../providers/categories_provider.dart';
import '../services/supabase_service.dart';
import '../models/house.dart';
import 'main_shell.dart';

class HouseOnboardingScreen extends ConsumerStatefulWidget {
  const HouseOnboardingScreen({super.key});

  @override
  ConsumerState<HouseOnboardingScreen> createState() => _HouseOnboardingScreenState();
}

class _HouseOnboardingScreenState extends ConsumerState<HouseOnboardingScreen> {
  bool _isCreating = true;
  final _createFormKey = GlobalKey<FormState>();
  final _houseNameController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;

  Future<void> _createHouse() async {
    if (!_createFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.currentUserId!;
      final house = await SupabaseService.createHouse(
        name: _houseNameController.text.trim(),
        createdBy: userId,
      );

      await ref.read(profileProvider.notifier).setHouse(house.id);
      await ref.read(houseProvider.notifier).loadHouse(house.id);

      // Verify profile was updated before creating rooms
      final updatedProfile = ref.read(profileProvider).value;
      if (updatedProfile == null || updatedProfile.houseId != house.id) {
        throw Exception('Failed to update profile house membership');
      }

      // Create default room
      await ref.read(roomsProvider.notifier).addRoom(
        AppLocalizations.of(context)!.house,
        house.id,
      );

      // Seed default categories
      await ref.read(categoriesProvider.notifier).seedDefaults(house.id);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      debugPrint('_createHouse error: $e');
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchHouses() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await SupabaseService.searchHouses(_searchController.text.trim());
      setState(() => _searchResults = results);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestJoin(Map<String, dynamic> result) async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.currentUserId!;
      final house = result['house'] as House;
      final creatorEmail = result['creator_email'] as String;
      
      await SupabaseService.createInvitation(
        fromUserId: userId,
        toEmail: creatorEmail,
        houseId: house.id,
      );

      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.requestSent)),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.house)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l10n.createHouse),
                  icon: const Icon(Icons.add_home_outlined),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.joinHouse),
                  icon: const Icon(Icons.login_outlined),
                ),
              ],
              selected: {_isCreating},
              onSelectionChanged: (set) {
                setState(() {
                  _isCreating = set.first;
                  _errorMessage = null;
                  _searchResults = [];
                });
              },
            ),
            const SizedBox(height: 24),
            if (_isCreating)
              Form(
                key: _createFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _houseNameController,
                      decoration: InputDecoration(
                        labelText: l10n.houseName,
                        prefixIcon: const Icon(Icons.home_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.requiredField;
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
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isLoading ? null : _createHouse,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.createHouse),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: l10n.searchHouse,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _isLoading ? null : _searchHouses,
                      ),
                    ),
                    onSubmitted: (_) => _searchHouses(),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                    Text(
                      l10n.houseNotFound,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        final house = result['house'] as House;
                        final creatorNickname = result['creator_nickname'] as String;
                        return Card(
                          child: ListTile(
                            title: Text(house.name),
                            subtitle: Text('${l10n.createdBy}: $creatorNickname'),
                            trailing: FilledButton.tonal(
                              onPressed: () => _requestJoin(result),
                              child: Text(l10n.requestJoin),
                            ),
                          ),
                        );
                      },
                    ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: scheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _houseNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
