import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'services/storage_service.dart';
import 'services/theme_provider.dart';
import 'services/update_service.dart';
import 'screens/home_screen.dart';
import 'screens/add_medicine_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicjalizacja storage
  final storageService = StorageService();
  await storageService.init();

  // Inicjalizacja theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Inicjalizacja update service
  final updateService = UpdateService();
  await updateService.init();

  runApp(
    PudelkoNaLekiApp(
      storageService: storageService,
      themeProvider: themeProvider,
      updateService: updateService,
    ),
  );
}

class PudelkoNaLekiApp extends StatelessWidget {
  final StorageService storageService;
  final ThemeProvider themeProvider;
  final UpdateService updateService;

  const PudelkoNaLekiApp({
    super.key,
    required this.storageService,
    required this.themeProvider,
    required this.updateService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, child) {
        return MaterialApp(
          title: 'Pudełko na leki',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: MainNavigation(
            storageService: storageService,
            themeProvider: themeProvider,
            updateService: updateService,
          ),
        );
      },
    );
  }
}

/// Główna nawigacja z bottom navigation bar (4 zakładki)
class MainNavigation extends StatefulWidget {
  final StorageService storageService;
  final ThemeProvider themeProvider;
  final UpdateService updateService;

  const MainNavigation({
    super.key,
    required this.storageService,
    required this.themeProvider,
    required this.updateService,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0; // Domyślnie Apteczka (pierwszy tab)
  final GlobalKey<_HomeScreenWrapperState> _homeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Apteczka (domyślny)
          _HomeScreenWrapper(
            key: _homeKey,
            storageService: widget.storageService,
            themeProvider: widget.themeProvider,
            updateService: widget.updateService,
            onNavigateToSettings: () {
              setState(() {
                _currentIndex = 2; // Navigate to Ustawienia tab
              });
            },
          ),
          // 1: Dodaj
          AddMedicineScreen(storageService: widget.storageService),
          // 2: Ustawienia
          SettingsScreen(
            storageService: widget.storageService,
            themeProvider: widget.themeProvider,
            updateService: widget.updateService,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.darkShadowDark
                  : AppColors.lightShadowDark,
              offset: const Offset(0, -4),
              blurRadius: 12,
            ),
            BoxShadow(
              color: isDark
                  ? AppColors.darkShadowLight
                  : AppColors.lightShadowLight,
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Odśwież widok po przełączeniu taba
            if (index == 0) {
              _homeKey.currentState?.refresh();
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.briefcaseMedical),
              selectedIcon: Icon(LucideIcons.briefcaseMedical),
              label: 'Apteczka',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.plus),
              selectedIcon: Icon(LucideIcons.plus),
              label: 'Dodaj',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.settings2),
              selectedIcon: Icon(LucideIcons.settings2),
              label: 'Ustawienia',
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper dla HomeScreen z możliwością odświeżania
class _HomeScreenWrapper extends StatefulWidget {
  final StorageService storageService;
  final ThemeProvider themeProvider;
  final UpdateService updateService;
  final VoidCallback onNavigateToSettings;

  const _HomeScreenWrapper({
    super.key,
    required this.storageService,
    required this.themeProvider,
    required this.updateService,
    required this.onNavigateToSettings,
  });

  @override
  State<_HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<_HomeScreenWrapper> {
  Key _refreshKey = UniqueKey();

  void refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      key: _refreshKey,
      storageService: widget.storageService,
      themeProvider: widget.themeProvider,
      updateService: widget.updateService,
      onNavigateToSettings: widget.onNavigateToSettings,
    );
  }
}
