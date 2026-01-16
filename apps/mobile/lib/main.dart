import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'config/app_config.dart';
import 'services/app_logger.dart';
import 'services/bug_report_service.dart';
import 'services/fab_service.dart';
import 'services/storage_service.dart';
import 'services/theme_provider.dart';
import 'services/update_service.dart';
import 'screens/home_screen.dart';
import 'screens/add_medicine_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/apteczka_toolbar.dart';
import 'widgets/bug_report_sheet.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/karton_icons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicjalizacja loggera JAKO PIERWSZY
  AppLogger.init();

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

class PudelkoNaLekiApp extends StatefulWidget {
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
  State<PudelkoNaLekiApp> createState() => _PudelkoNaLekiAppState();
}

class _PudelkoNaLekiAppState extends State<PudelkoNaLekiApp> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.themeProvider,
      builder: (context, child) {
        return MaterialApp(
          title: 'Karton z lekami',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: widget.themeProvider.themeMode,
          // Lokalizacja
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pl', 'PL')],
          locale: const Locale('pl', 'PL'),
          home: MainNavigation(
            storageService: widget.storageService,
            themeProvider: widget.themeProvider,
            updateService: widget.updateService,
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
  bool _showApteczkaToolbar = false; // Stan widoczności toolbara
  final GlobalKey<_HomeScreenWrapperState> _homeKey = GlobalKey();

  // Klucz do przechwytywania screenshotów dla bug reportu
  final GlobalKey _screenshotKey = GlobalKey();

  /// Otwiera bug report z przechwyconym screenshotem
  Future<void> _openBugReportWithScreenshot() async {
    final screenshot = await BugReportService.instance.captureScreenshot(
      _screenshotKey,
    );
    if (!mounted) return;

    BugReportSheet.show(context, screenshot: screenshot);
  }

  /// Callback wywoływany gdy zmieni się stan filtrów w HomeScreen
  void _onFiltersChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
        key: _screenshotKey,
        child: Stack(
          children: [
            // Główna zawartość - IndexedStack z ekranami
            IndexedStack(
              index: _currentIndex,
              children: [
                // 0: Dodaj
                AddMedicineScreen(
                  storageService: widget.storageService,
                  onError: (error) {
                    if (error != null) {
                      FabService.instance.showError(error);
                    } else {
                      FabService.instance.clearError();
                    }
                  },
                ),
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
                  onFiltersChanged: _onFiltersChanged,
                ),
                // 2: Ustawienia
                SettingsScreen(
                  storageService: widget.storageService,
                  themeProvider: widget.themeProvider,
                  updateService: widget.updateService,
                ),
              ],
            ),
            // ApteczkaToolbar - pozycjonowany w body, nad navbarem
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  FabService.instance,
                  widget.storageService.showBugReportFabNotifier,
                ]),
                builder: (context, _) {
                  final showBugReportButton = widget.storageService.showBugReportFab ||
                      AppConfig.isInternal ||
                      FabService.instance.scannerError != null;

                  return IgnorePointer(
                    ignoring: !(_currentIndex == 1 && _showApteczkaToolbar),
                    child: ApteczkaToolbar(
                      isVisible: _currentIndex == 1 && _showApteczkaToolbar,
                      hasActiveFilters: _homeKey.currentState?.hasActiveFilters ?? false,
                      showBugReportButton: showBugReportButton,
                      onSearch: () => _homeKey.currentState?.activateSearch(),
                      onSort: () => _homeKey.currentState?.showSort(),
                      onFilter: () => _homeKey.currentState?.showFilters(),
                      onClearFilter: () {
                        _homeKey.currentState?.clearFilters();
                        // Rebuild toolbar po wyczyszczeniu filtrów
                        setState(() {});
                      },
                      onMenu: () => _homeKey.currentState?.showManagement(),
                      onBugReport: _openBugReportWithScreenshot,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            if (index == 1) {
              // Apteczka tab
              if (_currentIndex != 1) {
                // Przechodzimy z innego tabu -> pokaż toolbar
                _currentIndex = 1;
                _showApteczkaToolbar = true;
              } else {
                // Już jesteśmy w Apteczce -> toggle toolbar
                _showApteczkaToolbar = !_showApteczkaToolbar;
              }
            } else {
              // Inne taby -> ukryj toolbar
              _currentIndex = index;
              _showApteczkaToolbar = false;
            }
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
  final VoidCallback? onFiltersChanged;

  const _HomeScreenWrapper({
    super.key,
    required this.storageService,
    required this.themeProvider,
    required this.updateService,
    required this.onNavigateToSettings,
    required this.onNavigateToAdd,
    this.onFiltersChanged,
  });

  @override
  State<_HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<_HomeScreenWrapper> {
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey();

  void refresh() {
    _homeScreenKey.currentState?.refresh();
  }

  /// Czy są aktywne filtry
  bool get hasActiveFilters => _homeScreenKey.currentState?.hasActiveFilters ?? false;

  /// Aktywuje pole wyszukiwania
  void activateSearch() => _homeScreenKey.currentState?.activateSearch();

  /// Otwiera sortowanie
  void showSort() => _homeScreenKey.currentState?.showSortBottomSheet();

  /// Otwiera filtry
  void showFilters() => _homeScreenKey.currentState?.showFilters();

  /// Czyści filtry
  void clearFilters() {
    _homeScreenKey.currentState?.clearFilters();
    widget.onFiltersChanged?.call();
  }

  /// Otwiera zarządzanie apteczką
  void showManagement() => _homeScreenKey.currentState?.showFilterManagement();

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      key: _homeScreenKey,
      storageService: widget.storageService,
      themeProvider: widget.themeProvider,
      updateService: widget.updateService,
      onNavigateToSettings: widget.onNavigateToSettings,
      onNavigateToAdd: widget.onNavigateToAdd,
    );
  }
}
