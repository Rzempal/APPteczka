import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'services/storage_service.dart';
import 'services/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/add_medicine_screen.dart';
import 'screens/backup_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicjalizacja storage
  final storageService = StorageService();
  await storageService.init();

  // Inicjalizacja theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    PudelkoNaLekiApp(
      storageService: storageService,
      themeProvider: themeProvider,
    ),
  );
}

class PudelkoNaLekiApp extends StatelessWidget {
  final StorageService storageService;
  final ThemeProvider themeProvider;

  const PudelkoNaLekiApp({
    super.key,
    required this.storageService,
    required this.themeProvider,
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
          ),
        );
      },
    );
  }
}

/// Główna nawigacja z bottom navigation bar
class MainNavigation extends StatefulWidget {
  final StorageService storageService;
  final ThemeProvider themeProvider;

  const MainNavigation({
    super.key,
    required this.storageService,
    required this.themeProvider,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Domyślnie Apteczka (środkowy tab)
  final GlobalKey<_HomeScreenWrapperState> _homeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Kopia
          BackupScreen(storageService: widget.storageService),
          // 1: Apteczka (domyślny)
          _HomeScreenWrapper(
            key: _homeKey,
            storageService: widget.storageService,
            themeProvider: widget.themeProvider,
          ),
          // 2: Dodaj
          AddMedicineScreen(storageService: widget.storageService),
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
            // Odśwież listę po powrocie do Apteczki
            if (index == 1) {
              _homeKey.currentState?.refresh();
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.package),
              selectedIcon: Icon(LucideIcons.package),
              label: 'Kopia',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.pill),
              selectedIcon: Icon(LucideIcons.pill),
              label: 'Apteczka',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.plusCircle),
              selectedIcon: Icon(LucideIcons.plusCircle),
              label: 'Dodaj',
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

  const _HomeScreenWrapper({
    super.key,
    required this.storageService,
    required this.themeProvider,
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
    );
  }
}
