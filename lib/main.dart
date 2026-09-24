import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_inventory/l10n/app_localizations.dart';

import 'providers/auth_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/house_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/products_provider.dart';
import 'providers/rooms_provider.dart';
import 'providers/theme_provider.dart';
import 'services/supabase_service.dart';
import 'services/update_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshMembership();
    }
  }

  Future<void> _refreshMembership() async {
    if (SupabaseService.currentUserId == null) return;

    await ref.read(profileProvider.notifier).refresh();
    final houseId = ref.read(profileProvider).value?.houseId;
    if (houseId == null) return;
    if (ref.read(houseProvider).value?.id == houseId) return;

    await ref.read(houseProvider.notifier).loadHouse(houseId);
    await ref.read(roomsProvider.notifier).loadRooms(houseId);
    await ref.read(categoriesProvider.notifier).loadCategories(houseId);
    await ref.read(productsProvider.notifier).loadProducts(houseId);

    _navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeOption = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Home Inventory',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(themeOption),
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('it'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _AppStartupWrapper(child: SplashScreen()),
    );
  }
}

class _AppStartupWrapper extends StatefulWidget {
  final Widget child;
  const _AppStartupWrapper({required this.child});

  @override
  State<_AppStartupWrapper> createState() => _AppStartupWrapperState();
}

class _AppStartupWrapperState extends State<_AppStartupWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.check(context, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
