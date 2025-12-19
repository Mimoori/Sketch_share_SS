import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';

class PostDetailPage extends StatelessWidget {
  final Post post;
  
  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          post.title.isNotEmpty ? post.title : 'Просмотр скетча',
          style: const TextStyle(fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePost,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Карточка с изображением
            _buildImageCard(),
            
            // Информация о пользователе
            _buildUserInfo(),
            
            // Контент поста
            _buildPostContent(),
            
            // Статистика
            _buildStatsCard(),
            
            // Действия
            _buildActionButtons(),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: _calculateAspectRatio(),
          child: Container(
            color: _getRandomColor(),
            child: Stack(
              children: [
                // Имитация рисунка
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.brush,
                        size: 80,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        post.title.isNotEmpty ? post.title : 'Скетч #${post.id}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${post.canvasWidth} × ${post.canvasHeight}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Водяной знак
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SketchShare',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Аватар
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.deepPurple[100],
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple[300]!,
                  Colors.deepPurple[500]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                post.user.nickname.isNotEmpty 
                    ? post.user.nickname[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.user.nickname.isNotEmpty 
                      ? post.user.nickname 
                      : 'Анонимный художник',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.user.fullName.isNotEmpty 
                      ? post.user.fullName 
                      : 'Участник SketchShare',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(post.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Кнопка подписки
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.deepPurple),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Подписаться',
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.title.isNotEmpty) ...[
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          if (post.description.isNotEmpty) ...[
            Text(
              post.description,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Теги (если будут)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag('Рисование', Icons.brush),
              _buildTag('Арт', Icons.palette),
              _buildTag('Творчество', Icons.lightbulb),
              if (post.canvasWidth > post.canvasHeight) 
                _buildTag('Альбомный', Icons.crop_landscape),
              if (post.canvasWidth < post.canvasHeight) 
                _buildTag('Портретный', Icons.crop_portrait),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Статистика скетча',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildStatItem('❤️', '${post.likeCount}', 'Лайки'),
              _buildStatItem('👁️', '${post.viewCount}', 'Просмотры'),
              _buildStatItem('✏️', '${post.strokeCount}', 'Штрихи'),
              _buildStatItem('📏', '${post.canvasWidth}x${post.canvasHeight}', 'Размер'),
              _buildStatItem('💾', _formatFileSize(post.fileSize), 'Файл'),
              _buildStatItem('🕒', DateFormat('dd.MM.yy').format(post.createdAt), 'Дата'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _likePost,
              icon: Icon(
                post.isLiked ? Icons.favorite : Icons.favorite_border,
                color: post.isLiked ? Colors.white : Colors.deepPurple,
              ),
              label: Text(
                post.isLiked ? 'Понравилось' : 'Нравится',
                style: TextStyle(
                  color: post.isLiked ? Colors.white : Colors.deepPurple,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: post.isLiked ? Colors.red : Colors.white,
                foregroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: post.isLiked ? Colors.red : Colors.deepPurple,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _sharePost,
              icon: const Icon(Icons.share, color: Colors.deepPurple),
              label: const Text(
                'Поделиться',
                style: TextStyle(color: Colors.deepPurple),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Colors.deepPurple),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          IconButton(
            onPressed: () {
              // Дополнительные действия
              _showMoreOptions();
            },
            icon: const Icon(Icons.more_vert, color: Colors.deepPurple),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательные виджеты
  Widget _buildTag(String text, IconData icon) {
    return Chip(
      label: Text(text),
      avatar: Icon(icon, size: 16),
      backgroundColor: Colors.deepPurple[50],
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы
  double _calculateAspectRatio() {
    if (post.canvasHeight > 0) {
      return post.canvasWidth / post.canvasHeight;
    }
    return 1.0;
  }

  Color _getRandomColor() {
    final colors = [
      Colors.deepPurple,
      Colors.blue[800]!,
      Colors.teal[700]!,
      Colors.indigo[700]!,
      Colors.purple[700]!,
    ];
    return colors[post.id % colors.length];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} лет назад';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} месяцев назад';
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Обработчики действий
  void _likePost() {
    // Логика лайка
  }

  void _sharePost() {
    // Логика шаринга
  }

  void _showMoreOptions() {
    // Показать меню дополнительных опций
  }
}