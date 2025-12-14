// lib/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'draw_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';

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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ],
      ),
    );

    if (reason == null) return;

    await FirebaseFirestore.instance.collection('sketches').doc(sketchId).update({
      'isDeleted': true,
      'deleteReason': reason,
      'deletedAt': FieldValue.serverTimestamp(),
    });

    // Уведомление автору
    final sketchSnapshot = await FirebaseFirestore.instance.collection('sketches').doc(sketchId).get();
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

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdmin = currentUser?.email == 'admin@example.com'; // ← замени на свой email админа

    return Scaffold(
      appBar: AppBar(
        title: const Text('SketchShare'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
          ),
        ],
      ),
      drawer: Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      const DrawerHeader(
        decoration: BoxDecoration(color: Colors.deepPurple),
        child: Text('SketchShare', style: TextStyle(color: Colors.white, fontSize: 24)),
      ),
      ListTile(
        leading: const Icon(Icons.person),
        title: const Text('Профиль'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
      ),
      ListTile(
        leading: const Icon(Icons.notifications),
        title: const Text('Уведомления'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
      ),
      ListTile(
        leading: const Icon(Icons.dark_mode),
        title: const Text('Тёмная тема'),
        trailing: Switch(
          value: Theme.of(context).brightness == Brightness.dark,
          onChanged: (val) {
            // Пока просто перезапускаем с темой (можно сделать через Provider)
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
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Пока нет скетчей'));
          }

          final docs = snapshot.data!.docs;

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
              final imageUrl = data['imageUrl'] as String;
              final author = data['authorName'] ?? 'Аноним';

              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        author,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  if (isAdmin)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _showDeleteDialog(context, docs[i].id),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DrawPage())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}