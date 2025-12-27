import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/add_medicine_screen.dart';
import 'screens/backup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicjalizacja storage
  final storageService = StorageService();
  await storageService.init();

  runApp(PudelkoNaLekiApp(storageService: storageService));
}

class PudelkoNaLekiApp extends StatelessWidget {
  final StorageService storageService;

  const PudelkoNaLekiApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pudełko na leki',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366f1), // Indigo
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366f1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: MainNavigation(storageService: storageService),
    );
  }
}

/// Główna nawigacja z bottom navigation bar
class MainNavigation extends StatefulWidget {
  final StorageService storageService;

  const MainNavigation({super.key, required this.storageService});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<_HomeScreenWrapperState> _homeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeScreenWrapper(
            key: _homeKey,
            storageService: widget.storageService,
          ),
          AddMedicineScreen(storageService: widget.storageService),
          BackupScreen(storageService: widget.storageService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Odśwież listę po powrocie
          if (index == 0) {
            _homeKey.currentState?.refresh();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Apteczka',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Dodaj',
          ),
          NavigationDestination(
            icon: Icon(Icons.backup_outlined),
            selectedIcon: Icon(Icons.backup),
            label: 'Kopia',
          ),
        ],
      ),
    );
  }
}

/// Wrapper dla HomeScreen z możliwością odświeżania
class _HomeScreenWrapper extends StatefulWidget {
  final StorageService storageService;

  const _HomeScreenWrapper({super.key, required this.storageService});

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
    return HomeScreen(key: _refreshKey, storageService: widget.storageService);
  }
}
