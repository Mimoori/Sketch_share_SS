import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'pages/welcome_page.dart';
import 'pages/feed_page.dart';
import 'pages/registration_page.dart';
import 'pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('=== Firebase инициализирован ===');
  
  runApp(const MyApp());
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoading => _isLoading;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('themeMode') ?? 'system';
      
      switch(savedTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    } catch (e) {
      _themeMode = ThemeMode.system;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      switch(mode) {
        case ThemeMode.light:
          await prefs.setString('themeMode', 'light');
          break;
        case ThemeMode.dark:
          await prefs.setString('themeMode', 'dark');
          break;
        case ThemeMode.system:
          await prefs.setString('themeMode', 'system');
          break;
      }
    } catch (e) {
      print('Ошибка сохранения темы: $e');
    }
    notifyListeners();
  }
}

// Создайте этот файл: lib/providers/sketches_provider.dart
class SketchesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _sketches = [];
  List<String> _likedSketchIds = [];
  
  List<Map<String, dynamic>> get sketches => _sketches;
  List<String> get likedSketchIds => _likedSketchIds;
  
  SketchesProvider() {
    _loadSketches();
  }
  
  Future<void> _loadSketches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sketchesJson = prefs.getString('sketches');
      
      if (sketchesJson != null) {
        _sketches = (jsonDecode(sketchesJson) as List<dynamic>)
            .cast<Map<String, dynamic>>();
        
        final likedJson = prefs.getString('liked_sketch_ids');
        if (likedJson != null) {
          _likedSketchIds = (jsonDecode(likedJson) as List<dynamic>).cast<String>();
        }
      }
    } catch (e) {
      print('Ошибка загрузки скетчей: $e');
    }
    notifyListeners();
  }
  
  Future<void> saveSketches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sketches', jsonEncode(_sketches));
      await prefs.setString('liked_sketch_ids', jsonEncode(_likedSketchIds));
    } catch (e) {
      print('Ошибка сохранения скетчей: $e');
    }
  }
  
  Future<void> addSketch(Map<String, dynamic> sketch) async {
    _sketches.insert(0, sketch);
    await saveSketches();
    notifyListeners();
  }
  
  Future<void> deleteSketch(String sketchId) async {
    _sketches.removeWhere((sketch) => sketch['id'] == sketchId);
    await saveSketches();
    notifyListeners();
  }
  
  Future<void> toggleLike(String sketchId) async {
    if (_likedSketchIds.contains(sketchId)) {
      _likedSketchIds.remove(sketchId);
    } else {
      _likedSketchIds.add(sketchId);
    }
    await saveSketches();
    notifyListeners();
  }
  
  bool isLiked(String sketchId) {
    return _likedSketchIds.contains(sketchId);
  }
}


// Необходимые конвертеры
Map<String, dynamic> _convertSketchToMap({
  required String id,
  required String imageBase64,
  required String authorName,
  String? caption,
  required int width,
  required int height,
  int likeCount = 0,
}) {
  return {
    'id': id,
    'imageBase64': imageBase64,
    'authorName': authorName,
    'caption': caption,
    'timestamp': DateTime.now().toIso8601String(),
    'likeCount': likeCount,
    'canvasSize': {'width': width, 'height': height},
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => SketchesProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          if (themeProvider.isLoading) {
            return MaterialApp(
              home: Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.brush,
                        size: 80,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Загрузка темы...',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          return MaterialApp(
            title: 'SketchShare',
            theme: ThemeData.light().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                centerTitle: true,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                centerTitle: true,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const AuthChecker(),
            routes: {
              '/welcome': (context) => const WelcomePage(),
              '/register': (context) => const RegistrationPage(),
              '/login': (context) => const LoginPage(),
              '/feed': (context) => const FeedPage(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<firebase_auth.User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        print('=== AuthChecker ===');
        print('Connection state: ${snapshot.connectionState}');
        print('Has data: ${snapshot.hasData}');
        print('Data: ${snapshot.data?.email}');
        print('Error: ${snapshot.error}');
        
        // Показываем индикатор загрузки пока идет проверка
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.deepPurple,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.brush,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Проверка авторизации...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Если есть ошибка
        if (snapshot.hasError) {
          print('Ошибка в StreamBuilder: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  Text('Ошибка: ${snapshot.error}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
                    child: const Text('На главную'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Если пользователь авторизован - показываем FeedPage
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('=== ПОЛЬЗОВАТЕЛЬ АВТОРИЗОВАН ===');
          print('UID: ${user.uid}');
          print('Email: ${user.email}');
          print('Display name: ${user.displayName}');
          
          return const FeedPage();
        }
        
        // Если пользователь не авторизован - показываем WelcomePage
        print('=== ПОЛЬЗОВАТЕЛЬ НЕ АВТОРИЗОВАН ===');
        return const WelcomePage();
      },
    );
  }
}