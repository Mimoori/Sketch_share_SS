import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> user = {
    'name': 'Вика',
    'surname': 'Иванова',
    'nickname': 'vika_art',
    'email': 'vika@example.com',
    'avatarPath': '', // Локальный путь к изображению
  };

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('user_profile');
      
      if (savedUser != null && mounted) {
        setState(() {
          user = jsonDecode(savedUser);
          _initializeControllers();
        });
      } else {
        _initializeControllers();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки профиля: $e');
      _initializeControllers();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeControllers() {
    _nameController.text = user['name'] ?? '';
    _surnameController.text = user['surname'] ?? '';
    _nicknameController.text = user['nickname'] ?? '';
    _emailController.text = user['email'] ?? '';
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedUser = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'email': _emailController.text.trim(),
        'avatarPath': user['avatarPath'] ?? '',
      };
      
      await prefs.setString('user_profile', jsonEncode(updatedUser));
      
      if (mounted) {
        setState(() {
          user = updatedUser;
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль сохранён!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changeAvatar() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (picked != null && mounted) {
        // Копируем файл в директорию приложения для постоянного хранения
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = File('${appDir.path}/$fileName');
        await File(picked.path).copy(savedFile.path);
        
        setState(() {
          _selectedImage = savedFile;
          user['avatarPath'] = savedFile.path;
        });
        
        // Сохраняем обновленный профиль
        final prefs = await SharedPreferences.getInstance();
        final currentUser = Map<String, dynamic>.from(user);
        currentUser['avatarPath'] = savedFile.path;
        await prefs.setString('user_profile', jsonEncode(currentUser));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Аватар обновлён!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора изображения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите имя'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите email'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректный email'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    
    return true;
  }

  void _toggleEditMode() {
    if (_isEditing) {
      _initializeControllers(); // Сбросить изменения
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditing ? 'Отменить' : 'Редактировать',
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Сохранить',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Аватар
                  GestureDetector(
                    onTap: _isEditing ? _changeAvatar : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundImage: _getAvatarImage(),
                          backgroundColor: Colors.grey[300],
                          child: user['avatarPath'] == null || user['avatarPath'].isEmpty
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Поля для редактирования/отображения
                  if (_isEditing) ...[
                    _buildTextField('Имя', _nameController, Icons.person),
                    const SizedBox(height: 15),
                    _buildTextField('Фамилия', _surnameController, Icons.person_outline),
                    const SizedBox(height: 15),
                    _buildTextField('Никнейм', _nicknameController, Icons.alternate_email),
                    const SizedBox(height: 15),
                    _buildTextField('Email', _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 30),
                    
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Сохранить изменения',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ] else ...[
                    // Отображение данных
                    _buildProfileInfo('Имя', user['name'], Icons.person),
                    const SizedBox(height: 15),
                    _buildProfileInfo('Фамилия', user['surname'], Icons.person_outline),
                    const SizedBox(height: 15),
                    _buildProfileInfo('Никнейм', user['nickname'], Icons.alternate_email),
                    const SizedBox(height: 15),
                    _buildProfileInfo('Email', user['email'], Icons.email),
                    const SizedBox(height: 30),
                    
                    ElevatedButton(
                      onPressed: _toggleEditMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Редактировать профиль',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Статистика
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Статистика',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('0', 'Рисунков'),
                            _buildStatItem('0', 'Лайков'),
                            _buildStatItem('0', 'Подписчиков'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  ImageProvider _getAvatarImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    
    final avatarPath = user['avatarPath'];
    if (avatarPath != null && avatarPath.isNotEmpty) {
      try {
        return FileImage(File(avatarPath));
      } catch (e) {
        debugPrint('Ошибка загрузки аватара: $e');
      }
    }
    
    // Заглушка если нет аватара
    return const AssetImage('assets/images/default_avatar.png');
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _buildProfileInfo(String label, String? value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value?.isNotEmpty == true ? value! : 'Не указано',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}