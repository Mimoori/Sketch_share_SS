import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'draw_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _posts = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String _sortBy = 'newest';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_scrollListener);
    
    // Автообновление каждые 30 секунд
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_isLoading) {
        _loadMorePosts();
      }
    }
  }

  Future<List<dynamic>> _fetchPosts(int page) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5432/api/posts?page=$page&pageSize=20&sortBy=$_sortBy'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final totalCount = int.parse(response.headers['x-total-count'] ?? '0');
        final totalPages = int.parse(response.headers['x-total-pages'] ?? '1');
        
        setState(() {
          _totalPages = totalPages;
        });

        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      // Fallback: пытаемся получить посты из Firebase
      return _fetchPostsFromFirebase();
    }
  }

  Future<List<dynamic>> _fetchPostsFromFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sketches')
          .where('isDeleted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['caption'] ?? '',
          'firebaseImageUrl': data['imageUrl'],
          'likeCount': data['likeCount'] ?? 0,
          'userId': data['authorId'],
          'user': {'username': data['authorName'] ?? 'Аноним'},
          'createdAt': (data['timestamp'] as Timestamp).toDate().toIso8601String(),
          'canvasWidth': data['canvasSize']?['width'] ?? 1000,
          'canvasHeight': data['canvasSize']?['height'] ?? 1000,
          'strokeCount': data['toolCount'] ?? 0,
          'isFromFirebase': true,
        };
      }).toList();
    } catch (e) {
      print('Error fetching from Firebase: $e');
      return [];
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final posts = await _fetchPosts(1);
      
      setState(() {
        _posts = posts;
        _isLoading = false;
        _hasMore = posts.length == 20 && _currentPage < _totalPages;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() => _isLoading = false);
      _showMessage('Ошибка загрузки постов');
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);

    try {
      final newPosts = await _fetchPosts(_currentPage + 1);
      
      setState(() {
        _posts.addAll(newPosts);
        _currentPage++;
        _isLoading = false;
        _hasMore = newPosts.length == 20 && _currentPage < _totalPages;
      });
    } catch (e) {
      print('Error loading more posts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(int postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showMessage('Войдите в аккаунт чтобы ставить лайки');
        return;
      }

      // Отправляем запрос в PostgreSQL API
      final token = await currentUser.getIdToken();
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/posts/$postId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final newLikeCount = result['likeCount'] as int;
        
        // Обновляем локально
        setState(() {
          final index = _posts.indexWhere((p) => p['id'] == postId);
          if (index != -1) {
            _posts[index]['likeCount'] = newLikeCount;
          }
        });

        // Отправляем уведомление
        await _sendLikeNotification(postId);
      } else {
        throw Exception('Failed to toggle like');
      }
    } catch (e) {
      print('Error toggling like: $e');
      _showMessage('Ошибка при обновлении лайка');
    }
  }

  Future<void> _sendLikeNotification(int postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final post = _posts.firstWhere((p) => p['id'] == postId);
      final authorId = post['userId'];

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': authorId,
        'title': 'Новый лайк',
        'body': '${currentUser.displayName} понравился ваш скетч',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'postId': postId,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> _showDeleteDialog(String postId, String authorName) async {
    final currentUser = _auth.currentUser;
    final isAdmin = currentUser?.email == 'admin@example.com';

    if (!isAdmin) {
      _showMessage('Только администратор может удалять посты');
      return;
    }

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
        title: const Text('Удалить пост?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Автор: $authorName'),
            const SizedBox(height: 16),
            const Text('Причина удаления:'),
            SizedBox(
              width: double.maxFinite,
              height: 200,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reasons.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(reasons[i]),
                  onTap: () => Navigator.pop(context, reasons[i]),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasons.last),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    try {
      final token = await currentUser!.getIdToken();
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 204) {
        _showMessage('Пост удален');
        _loadPosts(); // Перезагружаем список
      } else {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      print('Error deleting post: $e');
      _showMessage('Ошибка при удалении поста');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final isAdmin = currentUser?.email == 'admin@example.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SketchShare'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Сортировка
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _loadPosts();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'newest',
                child: Text('Сначала новые'),
              ),
              const PopupMenuItem(
                value: 'popular',
                child: Text('Популярные'),
              ),
              const PopupMenuItem(
                value: 'views',
                child: Text('Просмотры'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProfilePage())),
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
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Тёмная тема'),
              trailing: Switch(
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (val) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MaterialApp(
                        theme: val ? ThemeData.dark() : ThemeData.light(),
                        home: const FeedPage(),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.info, color: Colors.grey[600]),
              title: Text('Версия 1.0.0', style: TextStyle(color: Colors.grey[600])),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Выйти', style: TextStyle(color: Colors.red)),
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
      ),
      body: _isLoading && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: _posts.isEmpty
                  ? const Center(
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
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _posts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _posts.length) {
                          return _buildLoader();
                        }
                        
                        final post = _posts[index];
                        return _buildPostItem(post, isAdmin);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const DrawPage())),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Создать скетч',
      ),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post, bool isAdmin) {
    final imageUrl = post['firebaseImageUrl'] ?? post['imageUrl'];
    final author = post['user']?['username'] ?? 'Аноним';
    final likeCount = post['likeCount'] ?? 0;
    final caption = post['title'] ?? '';
    final createdAt = DateTime.parse(post['createdAt']);
    final postId = post['id'].toString();

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и автор
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text(
                author.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              author,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_formatDate(createdAt)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _showDeleteDialog(postId, author),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showPostOptions(post),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Изображение
          if (imageUrl != null && imageUrl.isNotEmpty)
            GestureDetector(
              onDoubleTap: () => _toggleLike(int.parse(postId)),
              onTap: () => _showImageFullscreen(imageUrl),
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Информация о размере
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(140, 0, 0, 0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${post['canvasWidth'] ?? 1000}×${post['canvasHeight'] ?? 1000}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    // Кнопка лайка
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleLike(int.parse(postId)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(140, 0, 0, 0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                likeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Подпись и действия
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      caption,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            onPressed: () => _toggleLike(int.parse(postId)),
                            tooltip: 'Лайкнуть',
                          ),
                          Text(
                            '$likeCount лайков',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _sharePost(post),
                      tooltip: 'Поделиться',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border),
                      onPressed: () => _savePost(post),
                      tooltip: 'Сохранить',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return _isLoading
        ? const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        : Container();
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

  void _showImageFullscreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black87,
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPostOptions(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Пожаловаться'),
              onTap: () {
                Navigator.pop(context);
                _reportPost(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Копировать ссылку'),
              onTap: () {
                Navigator.pop(context);
                _copyPostLink(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Сохранить изображение'),
              onTap: () {
                Navigator.pop(context);
                _savePostImage(post);
              },
            ),
            const Divider(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }

  void _reportPost(Map<String, dynamic> post) {
    _showMessage('Жалоба отправлена');
  }

  void _copyPostLink(Map<String, dynamic> post) {
    _showMessage('Ссылка скопирована');
  }

  void _savePost(Map<String, dynamic> post) {
    _showMessage('Пост сохранен');
  }

  void _sharePost(Map<String, dynamic> post) {
    final imageUrl = post['firebaseImageUrl'] ?? post['imageUrl'];
    final caption = post['title'] ?? '';
    final author = post['user']?['username'] ?? 'Аноним';
    
    _showMessage('Функция шаринга будет добавлена позже');
  }

  Future<void> _savePostImage(Map<String, dynamic> post) async {
    final imageUrl = post['firebaseImageUrl'] ?? post['imageUrl'];
    if (imageUrl == null) return;

    try {
      _showMessage('Скачивание...');
      // Здесь можно добавить сохранение изображения
      await Future.delayed(const Duration(seconds: 1));
      _showMessage('Изображение готово к сохранению');
    } catch (e) {
      _showMessage('Ошибка при сохранении');
    }
  }
}