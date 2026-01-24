import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import 'config/app_config.dart';
import 'models/medicine.dart';
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

/// Akcja importu kopii zapasowej
enum _ImportAction { add, overwrite, cancel }

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

  // MethodChannel do odbioru file intents z Androida
  static const _fileIntentChannel = MethodChannel('app.karton/file_intent');

  @override
  void initState() {
    super.initState();
    _initFileIntentHandler();
  }

  /// Inicjalizuje obsługę file intents przez MethodChannel
  void _initFileIntentHandler() {
    // Obsługa callback z Androida (warm start)
    _fileIntentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onFileReceived') {
        final uriString = call.arguments as String?;
        debugPrint('🔗 [MethodChannel] onFileReceived: $uriString');
        if (uriString != null) {
          _handleBackupFileImport(Uri.parse(uriString));
        }
      }
    });

    // Sprawdź initial intent (cold start)
    _fileIntentChannel
        .invokeMethod<String>('getInitialFileUri')
        .then((uriString) {
          debugPrint('🔗 [MethodChannel] Initial file URI: $uriString');
          if (uriString != null && uriString.isNotEmpty) {
            _handleBackupFileImport(Uri.parse(uriString));
          }
        })
        .catchError((e) {
          debugPrint('🔗 [MethodChannel] Error: $e');
        });
  }

  /// Obsługuje import pliku .karton z deep link
  Future<void> _handleBackupFileImport(Uri uri) async {
    debugPrint('🔗 [handler] Processing URI: $uri');
    debugPrint('🔗 [handler] Scheme: ${uri.scheme}, Path: ${uri.path}');

    // Małe opóźnienie - pozwala UI się w pełni załadować
    await Future.delayed(const Duration(milliseconds: 500));

    // Sprawdź czy to plik .karton (sprawdzamy różne źródła nazwy)
    final uriString = uri.toString().toLowerCase();
    final path = uri.path.toLowerCase();

    // Dla content:// URI nazwa pliku może być w query params lub w ostatnim segmencie
    final lastSegment = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last.toLowerCase()
        : '';

    final isKartonFile =
        path.endsWith('.karton') ||
        lastSegment.endsWith('.karton') ||
        uriString.contains('.karton');

    if (!isKartonFile) {
      // Nie jest to plik .karton - ignoruj
      return;
    }

    // Odczytaj zawartość pliku
    String content;
    try {
      // Dla content:// URI nie można użyć File() bezpośrednio
      // Musimy skopiować do cache lub użyć platform channel
      // Na razie próbujemy odczytać bezpośrednio (działa dla file://)
      if (uri.scheme == 'file') {
        final file = File(uri.toFilePath());
        content = await file.readAsString();
      } else {
        // content:// URI - spróbuj odczytać przez ścieżkę
        // To może nie działać na wszystkich urządzeniach
        try {
          final file = File(uri.path);
          content = await file.readAsString();
        } catch (_) {
          // Fallback - pokaż instrukcję użytkownikowi
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Użyj opcji "Dodaj leki" → "Import kopii zapasowej" aby zaimportować plik',
                ),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd odczytu pliku: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Parsuj JSON
    List<Medicine> medicines;
    try {
      medicines = _parseBackupJson(content);
      if (medicines.isEmpty) {
        throw const FormatException('Brak leków w pliku');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nieprawidłowy format pliku: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Pokaż dialog z wyborem akcji
    if (!mounted) return;
    final action = await _showImportActionDialog(medicines.length);

    if (action == null || action == _ImportAction.cancel) {
      return;
    }

    if (action == _ImportAction.overwrite) {
      // Nadpisz - usuń wszystkie istniejące leki
      await widget.storageService.clearMedicines();
    }

    // Dodaj nowe leki (zarówno dla 'add' jak i 'overwrite')
    await widget.storageService.importMedicines(medicines);

    if (mounted) {
      // Przełącz na zakładkę Apteczka i odśwież
      setState(() {
        _currentIndex = 1;
        _showApteczkaToolbar = false;
      });
      _homeKey.currentState?.refresh();

      final actionText = action == _ImportAction.overwrite
          ? 'Nadpisano apteczkę'
          : 'Dodano ${medicines.length} leków';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(actionText),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Parsuje JSON backupu i zwraca listę leków
  List<Medicine> _parseBackupJson(String text) {
    final data = jsonDecode(text);

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Nieprawidłowy format JSON');
    }

    // Import leków
    final lekiRaw = data['leki'];
    if (lekiRaw is! List) {
      throw const FormatException('Brak leków w pliku');
    }

    final medicines = <Medicine>[];
    for (final item in lekiRaw) {
      if (item is Map<String, dynamic>) {
        final medicineData = Map<String, dynamic>.from(item);
        if (medicineData['id'] == null) {
          medicineData['id'] = const Uuid().v4();
        }
        if (medicineData['dataDodania'] == null) {
          medicineData['dataDodania'] = DateTime.now().toIso8601String();
        }
        medicines.add(Medicine.fromJson(medicineData));
      }
    }

    return medicines;
  }

  /// Dialog wyboru akcji importu (3 opcje)
  Future<_ImportAction?> _showImportActionDialog(int count) {
    return showDialog<_ImportAction>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(LucideIcons.fileInput, size: 32),
        title: const Text('Import kopii zapasowej'),
        content: Text(
          'Plik zawiera $count ${_getPolishPlural(count)}.\nCo chcesz zrobić?',
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ImportAction.cancel),
            child: const Text('Anuluj'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, _ImportAction.overwrite),
            child: const Text('Nadpisz'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _ImportAction.add),
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  String _getPolishPlural(int count) {
    if (count == 1) return 'lek';
    if (count >= 2 && count <= 4) return 'leki';
    if (count >= 12 && count <= 14) return 'leków';
    final lastDigit = count % 10;
    if (lastDigit >= 2 && lastDigit <= 4) return 'leki';
    return 'leków';
  }

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
                  final showBugReportButton =
                      widget.storageService.showBugReportFab ||
                      AppConfig.isInternal ||
                      FabService.instance.scannerError != null;

                  return IgnorePointer(
                    ignoring: !(_currentIndex == 1 && _showApteczkaToolbar),
                    child: ApteczkaToolbar(
                      isVisible: _currentIndex == 1 && _showApteczkaToolbar,
                      hasActiveFilters:
                          _homeKey.currentState?.hasActiveFilters ?? false,
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
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: widget.storageService.performanceModeNotifier,
        builder: (context, performanceMode, _) {
          return FloatingNavBar(
            currentIndex: _currentIndex,
            performanceMode: performanceMode,
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
          );
        },
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
  bool get hasActiveFilters =>
      _homeScreenKey.currentState?.hasActiveFilters ?? false;

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
      onFiltersChanged: widget.onFiltersChanged,
    );
  }
}
