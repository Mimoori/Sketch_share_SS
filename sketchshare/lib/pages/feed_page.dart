// lib/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'draw_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import '../main.dart'; // Импортируем ThemeProvider из main.dart

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  Future<void> _showDeleteDialog(BuildContext context, String sketchId) async {
    final reasons = [
      "Нарушение правил",
      "Спам",
      "Неприемлемый контент",
      "Автор попросил удалить",
      "Другое",
    ];

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Причина удаления'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reasons.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(reasons[i]),
              onTap: () => Navigator.pop(context, reasons[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    await FirebaseFirestore.instance.collection('sketches').doc(sketchId).update({
      'isDeleted': true,
      'deleteReason': reason,
      'deletedAt': FieldValue.serverTimestamp(),
    });

    final sketchSnapshot =
        await FirebaseFirestore.instance.collection('sketches').doc(sketchId).get();
    final authorId = sketchSnapshot['authorId'] as String?;

    if (authorId != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': authorId,
        'title': 'Скетч удалён',
        'body': 'Ваш скетч был удалён модератором.\nПричина: $reason',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Скетч удалён по причине: $reason')),
    );
  }

  // Функция для переключения лайка
  Future<void> _toggleLike(
      BuildContext context, String sketchId, bool isLiked, int currentLikes) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Войдите в аккаунт чтобы ставить лайки')),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;

    if (isLiked) {
      // Удаляем лайк
      final likeQuery = await firestore
          .collection('likes')
          .where('sketchId', isEqualTo: sketchId)
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (var doc in likeQuery.docs) {
        await doc.reference.delete();
      }

      // Уменьшаем счетчик
      await firestore.collection('sketches').doc(sketchId).update({
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      // Добавляем лайк
      await firestore.collection('likes').add({
        'sketchId': sketchId,
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Увеличиваем счетчик
      await firestore.collection('sketches').doc(sketchId).update({
        'likeCount': FieldValue.increment(1),
      });

      // Отправляем уведомление автору
      final sketchDoc = await firestore.collection('sketches').doc(sketchId).get();
      final authorId = sketchDoc['authorId'] as String?;
      final currentUserName =
          FirebaseAuth.instance.currentUser?.displayName ?? 'Пользователь';

      if (authorId != null && authorId != currentUserId) {
        await firestore.collection('notifications').add({
          'userId': authorId,
          'title': 'Новый лайк',
          'body': '$currentUserName понравился ваш скетч',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdmin = currentUser?.email == 'admin@example.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SketchShare'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text('SketchShare',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Профиль'),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ProfilePage())),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Уведомления'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage())),
            ),
            // Исправленный Switch для темы
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Тёмная тема'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (val) {
                      themeProvider.setThemeMode(
                        val ? ThemeMode.dark : ThemeMode.light
                      );
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Выйти', style: TextStyle(color: Colors.red)),
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sketches')
            .where('isDeleted', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Ошибка загрузки'));
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.brush, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Пока нет скетчей',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Создайте первый!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final sketchId = docs[i].id;
              final imageUrl = data['imageUrl'] as String;
              final author = data['authorName'] ?? 'Аноним';
              final likeCount = (data['likeCount'] as int?) ?? 0;
              final caption = data['caption'] as String? ?? '';

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('likes')
                    .where('sketchId', isEqualTo: sketchId)
                    .where('userId', isEqualTo: currentUser?.uid)
                    .snapshots(),
                builder: (context, likeSnapshot) {
                  final isLiked = likeSnapshot.data?.docs.isNotEmpty ?? false;

                  return GestureDetector(
                    onTap: () => _showSketchDetails(context, sketchId, data),
                    child: Stack(
                      children: [
                        // Фон с изображением
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),

                        // Градиент сверху для лучшей читаемости
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromARGB(140, 0, 0, 0),
                                Colors.transparent,
                                Colors.transparent,
                                Color.fromARGB(140, 0, 0, 0),
                              ],
                            ),
                          ),
                        ),

                        // Информация вверху
                        Positioned(
                          top: 8,
                          left: 8,
                          right: 8,
                          child: Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(140, 0, 0, 0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  author,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              if (isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_forever,
                                      size: 20, color: Colors.red),
                                  onPressed: () => _showDeleteDialog(context, sketchId),
                                ),
                            ],
                          ),
                        ),

                        // Кнопка лайка внизу
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _toggleLike(context, sketchId, isLiked, likeCount),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(140, 0, 0, 0),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    likeCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Подпись внизу слева
                        if (caption.isNotEmpty)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 60,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(140, 0, 0, 0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                caption,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DrawPage())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Функция для просмотра деталей скетча
  void _showSketchDetails(
      BuildContext context, String sketchId, Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] as String;
    final author = data['authorName'] ?? 'Аноним';
    final caption = data['caption'] as String? ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    final likeCount = (data['likeCount'] as int?) ?? 0;
    final canvasSize = data['canvasSize'] as Map<String, dynamic>? ?? {};
    final width = (canvasSize['width'] as num?)?.toInt() ?? 1000;
    final height = (canvasSize['height'] as num?)?.toInt() ?? 1000;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: const Color.fromARGB(128, 0, 0, 0),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  children: [
                    // Ручка для драга
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Изображение
                          Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.contain,
                              ),
                              color: Theme.of(context).canvasColor,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Информация
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      author,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(date),
                                      style: TextStyle(
                                          color: Theme.of(context).hintColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Подпись
                          if (caption.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).hoverColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                caption,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Детали
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDetailItem(
                                context,
                                Icons.photo_size_select_actual,
                                '${width}x$height',
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('likes')
                                    .where('sketchId', isEqualTo: sketchId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.docs.length ?? likeCount;
                                  return _buildDetailItem(
                                    context,
                                    Icons.favorite,
                                    '$count',
                                  );
                                },
                              ),
                              _buildDetailItem(
                                context,
                                Icons.brush,
                                '${data['toolCount'] ?? 0} штрихов',
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Кнопка сохранить
                          ElevatedButton.icon(
                            onPressed: () => _saveImageToGallery(context, imageUrl),
                            icon: const Icon(Icons.download),
                            label: const Text('Сохранить в галерею'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${difference.inDays ~/ 365} лет назад';
    } else if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} месяцев назад';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} дней назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} часов назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} минут назад';
    } else {
      return 'Только что';
    }
  }

  Future<void> _saveImageToGallery(BuildContext context, String imageUrl) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция сохранения скоро будет доступна'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}