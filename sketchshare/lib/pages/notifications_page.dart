// lib/pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late WebViewController _controller;
  bool _showDocumentation = false;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    
    // Инициализация WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)  // Включаем JavaScript для docsify
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('Ошибка загрузки документации: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // ВСЕ ссылки открываются ВНУТРИ WebView
            return NavigationDecision.navigate;
          },
        ),
      )
      // ЗАГРУЖАЕМ С ХОСТИНГА (GitHub Pages)
      ..loadRequest(Uri.parse('https://mimoori.github.io/Sketch_share_SS/#/'));
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: _showDocumentation 
            ? const Text('📖 Документация') 
            : const Text('Уведомления'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_showDocumentation) ...[
            // Кнопка обновления
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: () {
                _controller.reload();
              },
            ),
            // Кнопка назад
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (await _controller.canGoBack()) {
                  await _controller.goBack();
                }
              },
            ),
          ]
        ],
      ),
      
      body: _showDocumentation 
          ? _buildDocumentationView()
          : _buildNotificationsView(userId),
    );
  }

  // Виджет документации (WebView)
  Widget _buildDocumentationView() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        
        // Кнопка закрытия документации
        Positioned(
          top: 10,
          left: 10,
          child: FloatingActionButton.small(
            backgroundColor: Colors.deepPurple.withOpacity(0.8),
            foregroundColor: Colors.white,
            onPressed: () {
              setState(() {
                _showDocumentation = false;
              });
            },
            child: const Icon(Icons.arrow_back),
          ),
        ),
        
        // Индикатор загрузки
        if (_isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.deepPurple.withOpacity(0.5),
              ),
            ),
          ),
        
        // Полноэкранный индикатор при начале загрузки
        if (_isLoading && _progress < 0.1)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.deepPurple,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Загрузка документации с хостинга...',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Виджет уведомлений
  Widget _buildNotificationsView(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyNotifications();
        }

        final docs = snapshot.data!.docs;
        return _buildNotificationsList(docs);
      },
    );
  }

  // Пустые уведомления + кнопка документации
  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет уведомлений',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          
          // КНОПКА ДОКУМЕНТАЦИИ
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showDocumentation = true;
                });
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('📖 ОТКРЫТЬ ДОКУМЕНТАЦИЮ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Документация загружается с хостинга GitHub Pages',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Список уведомлений
  Widget _buildNotificationsList(List<QueryDocumentSnapshot> docs) {
    return Column(
      children: [
        
        const SizedBox(height: 10),
        
        // Список уведомлений
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? 'Уведомление';
              final body = data['body'] as String? ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active, color: Colors.red),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(body),
                  trailing: Text(
                    _formatTime(data['timestamp']),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    return '${date.day}.${date.month}.${date.year}';
  }
}