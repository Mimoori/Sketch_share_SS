// lib/models/sketch.dart
import 'dart:convert';

class Sketch {
  final String id;
  final String imageUrl; // Будет хранить Base64 изображение
  final String authorName;
  final String? caption;
  final DateTime timestamp;
  final int likeCount;
  final Map<String, dynamic> canvasSize;
  
  Sketch({
    required this.id,
    required this.imageUrl,
    required this.authorName,
    this.caption,
    required this.timestamp,
    this.likeCount = 0,
    required this.canvasSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'authorName': authorName,
      'caption': caption,
      'timestamp': timestamp.toIso8601String(),
      'likeCount': likeCount,
      'canvasSize': canvasSize,
    };
  }

  factory Sketch.fromJson(Map<String, dynamic> json) {
    return Sketch(
      id: json['id'],
      imageUrl: json['imageUrl'],
      authorName: json['authorName'],
      caption: json['caption'],
      timestamp: DateTime.parse(json['timestamp']),
      likeCount: json['likeCount'] ?? 0,
      canvasSize: json['canvasSize'],
    );
  }
}