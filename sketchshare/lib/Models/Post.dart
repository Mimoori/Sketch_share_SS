// import 'dart:convert';

// class Post {
//   final int id;
//   final String title;
//   final String description;
//   final String imageUrl;
//   final int canvasWidth;
//   final int canvasHeight;
//   final int fileSize;
//   final int strokeCount;
//   final int likeCount;
//   final int viewCount;
//   final DateTime createdAt;
//   final User user;
//   final bool isLiked;
//   final String contentType;

//   Post({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.imageUrl,
//     required this.canvasWidth,
//     required this.canvasHeight,
//     required this.fileSize,
//     required this.strokeCount,
//     required this.likeCount,
//     required this.viewCount,
//     required this.createdAt,
//     required this.user,
//     required this.isLiked,
//     required this.contentType,
//   });

//   factory Post.fromJson(Map<String, dynamic> json) {
//     return Post(
//       id: json['id'] ?? 0,
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//       imageUrl: json['imageUrl'] ?? '',
//       canvasWidth: json['canvasWidth'] ?? 1000,
//       canvasHeight: json['canvasHeight'] ?? 1000,
//       fileSize: json['fileSize'] ?? 0,
//       strokeCount: json['strokeCount'] ?? 0,
//       likeCount: json['likeCount'] ?? 0,
//       viewCount: json['viewCount'] ?? 0,
//       createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
//       user: User.fromJson(json['user'] ?? {}),
//       isLiked: json['isLiked'] ?? false,
//       contentType: json['contentType'] ?? 'image/png',
//     );
//   }

//   // ДЛЯ ЛЕНТЫ - добавленные геттеры
//   String get formattedDate {
//     final now = DateTime.now();
//     final difference = now.difference(createdAt);
    
//     if (difference.inDays > 365) return '${(difference.inDays / 365).floor()}y';
//     if (difference.inDays > 30) return '${(difference.inDays / 30).floor()}mo';
//     if (difference.inDays > 0) return '${difference.inDays}d';
//     if (difference.inHours > 0) return '${difference.inHours}h';
//     if (difference.inMinutes > 0) return '${difference.inMinutes}m';
//     return 'now';
//   }

//   String get formattedFileSize {
//     if (fileSize < 1024) return '${fileSize}B';
//     if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
//     return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
//   }

//   double get aspectRatio => canvasHeight > 0 ? canvasWidth / canvasHeight : 1.0;

//   // Метод toJson
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'title': title,
//       'description': description,
//       'imageUrl': imageUrl,
//       'canvasWidth': canvasWidth,
//       'canvasHeight': canvasHeight,
//       'fileSize': fileSize,
//       'strokeCount': strokeCount,
//       'likeCount': likeCount,
//       'viewCount': viewCount,
//       'createdAt': createdAt.toIso8601String(),
//       'user': user.toJson(),
//       'isLiked': isLiked,
//       'contentType': contentType,
//     };
//   }
// }

// class User {
//   final int id;
//   final String name;
//   final String surname;
//   final String nickname;
//   final String avatar;

//   User({
//     required this.id,
//     required this.name,
//     required this.surname,
//     required this.nickname,
//     required this.avatar,
//   });

//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//       surname: json['surname'] ?? '',
//       nickname: json['nickname'] ?? 'User',
//       avatar: json['avatar'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'surname': surname,
//       'nickname': nickname,
//       'avatar': avatar,
//     };
//   }

//   String get fullName => '$name $surname'.trim();
// }