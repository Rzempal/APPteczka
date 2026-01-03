import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'config/app_config.dart';
import 'services/storage_service.dart';
import 'services/theme_provider.dart';
import 'services/update_service.dart';
import 'screens/home_screen.dart';
import 'screens/add_medicine_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/bug_report_sheet.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/karton_icons.dart';

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
          title: 'Karton z lekami',
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
  int _currentIndex = 1; // Domyślnie Apteczka (środkowy tab)
  final GlobalKey<_HomeScreenWrapperState> _homeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Dodaj
          AddMedicineScreen(storageService: widget.storageService),
          // 1: Apteczka (domyślny, środkowy)
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
            onNavigateToAdd: () {
              setState(() {
                _currentIndex = 0; // Navigate to Dodaj tab
              });
            },
          ),
          // 2: Ustawienia
          SettingsScreen(
            storageService: widget.storageService,
            themeProvider: widget.themeProvider,
            updateService: widget.updateService,
          ),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Odśwież widok po przełączeniu na Apteczkę
          if (index == 1) {
            _homeKey.currentState?.refresh();
          }
        },
        items: [
          const NavItem(icon: LucideIcons.plus, label: 'Dodaj'),
          NavItem(
            icon: LucideIcons.briefcaseMedical, // fallback
            iconBuilder: (color, size) =>
                KartonMonoClosedIcon(size: size, color: color),
            label: 'Apteczka',
          ),
          const NavItem(icon: LucideIcons.settings2, label: 'Ustawienia'),
        ],
      ),
      // FAB for bug reporting - only visible in DEV builds
      floatingActionButton: AppConfig.isInternal
          ? FloatingActionButton(
              onPressed: () => BugReportSheet.show(context),
              backgroundColor: AppColors.expired,
              child: const Icon(LucideIcons.bug, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// Wrapper dla HomeScreen z możliwością odświeżania
class _HomeScreenWrapper extends StatefulWidget {
  final StorageService storageService;
  final ThemeProvider themeProvider;
  final UpdateService updateService;
  final VoidCallback onNavigateToSettings;
  final VoidCallback onNavigateToAdd;

  const _HomeScreenWrapper({
    super.key,
    required this.storageService,
    required this.themeProvider,
    required this.updateService,
    required this.onNavigateToSettings,
    required this.onNavigateToAdd,
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
      onNavigateToAdd: widget.onNavigateToAdd,
    );
  }
}
