import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_navigation_screen.dart';
import 'services/database_service.dart';
import 'state/store_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive NoSQL Database
  await DatabaseService.instance.init();

  runApp(const MelangadiStoreApp());
}

class MelangadiStoreApp extends StatefulWidget {
  const MelangadiStoreApp({super.key});

  @override
  State<MelangadiStoreApp> createState() => _MelangadiStoreAppState();
}

class _MelangadiStoreAppState extends State<MelangadiStoreApp> {
  late final StoreProvider _storeProvider;

  @override
  void initState() {
    super.initState();
    _storeProvider = StoreProvider();
  }

  @override
  void dispose() {
    _storeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreProviderScope(
      notifier: _storeProvider,
      child: MaterialApp(
        title: 'Melangadi Store',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
