import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // Импортируем ThemeProvider и SketchesProvider из main.dart
import 'draw_page.dart';
import 'profile_page.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sketchesProvider = Provider.of<SketchesProvider>(context);
    final sketches = sketchesProvider.sketches;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SketchShare'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const ProfilePage())
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'SketchShare',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Профиль'),
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const ProfilePage())
              ),
            ),
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
      body: Column(
        children: [
          // Заголовок приложения
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.brush, color: Colors.deepPurple, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'SketchShare',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Приложение для быстрых набросков и творческих идей',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Рисуйте и сохраняйте свои работы локально',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Лента скетчей
          Expanded(
            child: sketches.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.brush, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Пока нет скетчей',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Создайте первый!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: sketches.length,
                    itemBuilder: (context, index) {
                      final sketch = sketches[index];
                      final isLiked = sketchesProvider.isLiked(sketch['id'] ?? '');
                      final imageBase64 = sketch['imageBase64'] as String? ?? '';
                      final authorName = sketch['authorName'] as String? ?? 'Аноним';
                      final caption = sketch['caption'] as String?;
                      final likeCount = sketch['likeCount'] as int? ?? 0;

                      // Декодируем Base64 изображение
                      Uint8List? imageBytes;
                      try {
                        if (imageBase64.isNotEmpty) {
                          // Убираем префикс data:image/png;base64, если есть
                          final cleanBase64 = imageBase64.contains(',')
                              ? imageBase64.split(',').last
                              : imageBase64;
                          imageBytes = base64.decode(cleanBase64);
                        }
                      } catch (e) {
                        print('Ошибка декодирования изображения: $e');
                      }

                      return GestureDetector(
                        onTap: () => _showSketchDetails(context, sketch),
                        child: Stack(
                          children: [
                            // Изображение скетча
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: imageBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(imageBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: imageBytes == null ? Colors.grey[200] : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: imageBytes == null
                                  ? Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey[400],
                                        size: 40,
                                      ),
                                    )
                                  : null,
                            ),

                            // Градиент для текста
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

                            // Автор
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(140, 0, 0, 0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  authorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // Кнопка лайка
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _toggleLike(context, sketch['id'] ?? ''),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(140, 0, 0, 0),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
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

                            // Подпись
                            if (caption != null && caption.isNotEmpty)
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 60,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(140, 0, 0, 0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    caption,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DrawPage()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _toggleLike(BuildContext context, String sketchId) {
    final provider = Provider.of<SketchesProvider>(context, listen: false);
    provider.toggleLike(sketchId);
  }

  void _showSketchDetails(BuildContext context, Map<String, dynamic> sketch) {
    final imageBase64 = sketch['imageBase64'] as String? ?? '';
    final authorName = sketch['authorName'] as String? ?? 'Аноним';
    final caption = sketch['caption'] as String?;
    final timestampStr = sketch['timestamp'] as String?;
    final timestamp = timestampStr != null 
        ? DateTime.tryParse(timestampStr) ?? DateTime.now()
        : DateTime.now();
    final likeCount = sketch['likeCount'] as int? ?? 0;
    final canvasSize = sketch['canvasSize'] as Map<String, dynamic>? ?? {};
    final width = (canvasSize['width'] as num?)?.toInt() ?? 1000;
    final height = (canvasSize['height'] as num?)?.toInt() ?? 1000;

    // Декодируем изображение
    Uint8List? imageBytes;
    try {
      if (imageBase64.isNotEmpty) {
        final cleanBase64 = imageBase64.contains(',')
            ? imageBase64.split(',').last
            : imageBase64;
        imageBytes = base64.decode(cleanBase64);
      }
    } catch (e) {
      print('Ошибка декодирования: $e');
    }

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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  children: [
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
                          Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: imageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(imageBytes!),
                                      fit: BoxFit.contain,
                                    )
                                  : null,
                              color: imageBytes == null 
                                  ? Theme.of(context).canvasColor 
                                  : null,
                            ),
                            child: imageBytes == null
                                ? const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 20),
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
                                      authorName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(timestamp),
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (caption != null && caption.isNotEmpty) ...[
                            const SizedBox(height: 20),
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
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDetailItem(
                                Icons.photo_size_select_actual,
                                '${width}x$height',
                              ),
                              _buildDetailItem(
                                Icons.favorite,
                                '$likeCount',
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () => _saveImageToGallery(context, imageBase64),
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

  Widget _buildDetailItem(IconData icon, String text) {
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

  Future<void> _saveImageToGallery(
      BuildContext context, String base64Image) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция сохранения скоро будет доступна'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}