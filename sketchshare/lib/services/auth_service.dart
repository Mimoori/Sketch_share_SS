// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получаем поток изменений состояния аутентификации
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Получаем текущего пользователя
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Регистрация
  Future<firebase_auth.User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('Начало регистрации: $email');
      
      // Создаем пользователя
      final firebase_auth.UserCredential userCredential = 
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebase_auth.User? user = userCredential.user;
      
      if (user != null) {
        print('Пользователь создан: ${user.uid}');
        
        // Обновляем displayName
        await user.updateDisplayName(name);
        print('Display name обновлен: $name');
        
        // Создаем профиль в Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': name,
          'displayName': name,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'sketchesCount': 0,
          'likesCount': 0,
          'photoURL': user.photoURL ?? '',
        }, SetOptions(merge: true));
        
        print('Профиль создан в Firestore');
        
        // ЗАКЛЮЧИТЕЛЬНЫЙ ШАГ: Принудительно обновляем пользователя
        await user.reload();
        final updatedUser = _auth.currentUser;
        print('Пользователь обновлен: ${updatedUser?.uid}');
        
        return updatedUser;
      }
      
      return null;
    } catch (e) {
      print('Ошибка регистрации: $e');
      rethrow;
    }
  }

  // Вход
  Future<firebase_auth.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Вход: $email');
      final firebase_auth.UserCredential userCredential = 
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      print('Вход успешен: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      print('Ошибка входа: $e');
      rethrow;
    }
  }

  // Выход
  Future<void> signOut() async {
    await _auth.signOut();
    print('Выход выполнен');
  }

  // Получить профиль пользователя
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Ошибка получения профиля: $e');
      return null;
    }
  }
}