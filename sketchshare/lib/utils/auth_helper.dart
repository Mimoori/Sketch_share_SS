// lib/utils/auth_helper.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthHelper {
  static Future<void> createUserIfNeeded(User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!userDoc.exists) {
        print('Создание профиля для пользователя ${user.uid}');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'name': user.displayName ?? 'Аноним',
              'email': user.email ?? '',
              'createdAt': FieldValue.serverTimestamp(),
              'lastSeen': FieldValue.serverTimestamp(),
              'sketchesCount': 0,
              'likesCount': 0,
            }, SetOptions(merge: true));
        print('Профиль создан успешно');
      } else {
        print('Профиль уже существует для ${user.uid}');
      }
    } catch (e) {
      print('Ошибка создания пользователя: $e');
    }
  }
}