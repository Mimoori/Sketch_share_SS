// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import '../models/post.dart';

// class PostService {
//   // Для эмулятора Android
//   static const String _baseUrl = 'http://10.0.2.2:5000/api';
  
//   // Для тестирования без API - временные данные
//   Future<List<Post>> fetchPosts({int page = 1, int pageSize = 20}) async {
//     try {
//       // Попытка получить данные с API
//       final response = await http.get(
//         Uri.parse('$_baseUrl/posts?page=$page&pageSize=$pageSize'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         return data.map((json) => Post.fromJson(json)).toList();
//       } else {
//         // Если API не отвечает, возвращаем тестовые данные
//         return _getMockPosts();
//       }
//     } catch (e) {
//       debugPrint('Error fetching posts from API: $e');
//       // Возвращаем тестовые данные при ошибке
//       return _getMockPosts();
//     }
//   }

//   // Тестовые данные для отображения
//   List<Post> _getMockPosts() {
//     return [
//       Post(
//         id: 1,
//         title: 'Мой первый скетч',
//         description: 'Пробую новое приложение для рисования',
//         imageUrl: '/api/posts/1/image',
//         canvasWidth: 1000,
//         canvasHeight: 1000,
//         fileSize: 102400,
//         strokeCount: 150,
//         likeCount: 42,
//         viewCount: 128,
//         createdAt: DateTime.now().subtract(const Duration(hours: 2)),
//         user: User(
//           id: 1,
//           name: 'Анна',
//           surname: 'Иванова',
//           nickname: 'art_anna',
//           avatar: '',
//         ),
//         isLiked: false,
//         contentType: 'image/png',
//       ),
//       Post(
//         id: 2,
//         title: 'Городской пейзаж',
//         description: 'Рисовала вечером после работы',
//         imageUrl: '/api/posts/2/image',
//         canvasWidth: 1920,
//         canvasHeight: 1080,
//         fileSize: 204800,
//         strokeCount: 320,
//         likeCount: 89,
//         viewCount: 256,
//         createdAt: DateTime.now().subtract(const Duration(days: 1)),
//         user: User(
//           id: 2,
//           name: 'Максим',
//           surname: 'Петров',
//           nickname: 'max_art',
//           avatar: '',
//         ),
//         isLiked: true,
//         contentType: 'image/png',
//       ),
//       Post(
//         id: 3,
//         title: 'Абстракция',
//         description: 'Эксперимент с цветами и формами',
//         imageUrl: '/api/posts/3/image',
//         canvasWidth: 1200,
//         canvasHeight: 1600,
//         fileSize: 153600,
//         strokeCount: 210,
//         likeCount: 156,
//         viewCount: 512,
//         createdAt: DateTime.now().subtract(const Duration(days: 3)),
//         user: User(
//           id: 3,
//           name: 'Екатерина',
//           surname: 'Сидорова',
//           nickname: 'kat_creative',
//           avatar: '',
//         ),
//         isLiked: false,
//         contentType: 'image/png',
//       ),
//       Post(
//         id: 4,
//         title: 'Портрет друга',
//         description: 'Подарок на день рождения',
//         imageUrl: '/api/posts/4/image',
//         canvasWidth: 1080,
//         canvasHeight: 1920,
//         fileSize: 307200,
//         strokeCount: 480,
//         likeCount: 234,
//         viewCount: 789,
//         createdAt: DateTime.now().subtract(const Duration(days: 5)),
//         user: User(
//           id: 4,
//           name: 'Дмитрий',
//           surname: 'Кузнецов',
//           nickname: 'dima_draw',
//           avatar: '',
//         ),
//         isLiked: true,
//         contentType: 'image/png',
//       ),
//       Post(
//         id: 5,
//         title: 'Закат в горах',
//         description: 'Воспоминания об отпуске',
//         imageUrl: '/api/posts/5/image',
//         canvasWidth: 1600,
//         canvasHeight: 1200,
//         fileSize: 256000,
//         strokeCount: 390,
//         likeCount: 187,
//         viewCount: 654,
//         createdAt: DateTime.now().subtract(const Duration(days: 7)),
//         user: User(
//           id: 5,
//           name: 'Ольга',
//           surname: 'Смирнова',
//           nickname: 'olya_nature',
//           avatar: '',
//         ),
//         isLiked: false,
//         contentType: 'image/png',
//       ),
//     ];
//   }

//   Future<bool> toggleLike(int postId) async {
//     // Имитация запроса к API
//     await Future.delayed(const Duration(milliseconds: 300));
//     return true; // Всегда успешно для теста
//   }

//   Future<bool> createPost({
//     required String title,
//     required String description,
//     required int canvasWidth,
//     required int canvasHeight,
//     required int strokeCount,
//     required String imagePath,
//   }) async {
//     try {
//       // Имитация создания поста
//       await Future.delayed(const Duration(seconds: 2));
//       return true;
//     } catch (e) {
//       debugPrint('Error creating post: $e');
//       return false;
//     }
//   }

//   Future<bool> deletePost(int postId, {String? reason}) async {
//     try {
//       await Future.delayed(const Duration(seconds: 1));
//       return true;
//     } catch (e) {
//       debugPrint('Error deleting post: $e');
//       return false;
//     }
//   }
// }