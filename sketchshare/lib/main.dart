// lib/main.dart — 100% РАБОЧИЙ + ВСЁ СОХРАНЯЕТСЯ ПОСЛЕ ВЫХОДА
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'pages/feed_page.dart';
import 'pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SketchShare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Пока грузится — показываем загрузку
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Если пользователь авторизован — создаём/обновляем его в БД
        if (snapshot.hasData) {
          final user = snapshot.data!;
          
          // Заглушка — создаём пользователя в Firestore, если его нет
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'name': user.displayName ?? 'Аноним',
                'email': user.email ?? '',
                'photoURL': user.photoURL ?? '',
                'lastSeen': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true)); // не перезаписывает, только добавляет

          return const FeedPage();
        }

        // Если не авторизован — логин
        return const LoginPage();
      },
    );
  }
}