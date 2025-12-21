import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок с информацией о пользователе
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Аватар
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Информация о пользователе
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Иван Иванов', // Используем имя из профиля или дефолтное
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'user@example.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Художник • Новичок',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Пункты меню
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Мой профиль',
            subtitle: 'Просмотр и редактирование',
            onTap: () {
              // TODO: Переход на страницу профиля
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Страница профиля в разработке')),
              );
            },
          ),
          
          _buildMenuItem(
            icon: Icons.brush_outlined,
            title: 'Мои рисунки',
            subtitle: 'Просмотр ваших работ',
            onTap: () {
              // TODO: Переход к рисункам пользователя
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Мои рисунки в разработке')),
              );
            },
          ),
          
          _buildMenuItem(
            icon: Icons.favorite_outline,
            title: 'Избранное',
            subtitle: 'Сохранённые работы',
            onTap: () {
              // TODO: Переход к избранному
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Избранное в разработке')),
              );
            },
          ),
          
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Настройки',
            subtitle: 'Настройки приложения',
            onTap: () {
              // TODO: Переход к настройкам
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройки в разработке')),
              );
            },
          ),
          
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Помощь и поддержка',
            subtitle: 'FAQ и контакты',
            onTap: () {
              // TODO: Переход к помощи
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Помощь в разработке')),
              );
            },
          ),
          
          const Divider(height: 30, thickness: 1),
          
          // Выход
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Выйти',
            subtitle: 'Завершить сеанс',
            color: Colors.red,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/register');
            },
          ),
          
          const SizedBox(height: 10),
          
          // Версия приложения
          Text(
            'SketchShare v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.6),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}