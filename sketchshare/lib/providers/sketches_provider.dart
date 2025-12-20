// lib/providers/sketches_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sketch.dart';

class SketchesProvider extends ChangeNotifier {
  List<Sketch> _sketches = [];
  List<Sketch> _likedSketches = [];
  
  List<Sketch> get sketches => _sketches;
  List<Sketch> get likedSketches => _likedSketches;
  
  SketchesProvider() {
    _loadSketches();
  }
  
  Future<void> _loadSketches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sketchesJson = prefs.getString('sketches');
      
      if (sketchesJson != null) {
        final List<dynamic> sketchesList = jsonDecode(sketchesJson);
        _sketches = sketchesList.map((json) => Sketch.fromJson(json)).toList();
        
        final likedJson = prefs.getString('liked_sketches');
        if (likedJson != null) {
          final List<dynamic> likedList = jsonDecode(likedJson);
          _likedSketches = likedList.map((json) => Sketch.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Ошибка загрузки скетчей: $e');
    }
    notifyListeners();
  }
  
  Future<void> saveSketches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sketchesJson = jsonEncode(_sketches.map((s) => s.toJson()).toList());
      await prefs.setString('sketches', sketchesJson);
      
      final likedJson = jsonEncode(_likedSketches.map((s) => s.toJson()).toList());
      await prefs.setString('liked_sketches', likedJson);
    } catch (e) {
      print('Ошибка сохранения скетчей: $e');
    }
  }
  
  Future<void> addSketch(Sketch sketch) async {
    _sketches.insert(0, sketch);
    await saveSketches();
    notifyListeners();
  }
  
  Future<void> deleteSketch(String sketchId) async {
    _sketches.removeWhere((sketch) => sketch.id == sketchId);
    await saveSketches();
    notifyListeners();
  }
  
  Future<void> toggleLike(String sketchId, String userId) async {
    final sketch = _sketches.firstWhere((s) => s.id == sketchId);
    final isLiked = _likedSketches.any((s) => s.id == sketchId);
    
    if (isLiked) {
      // Удаляем лайк
      _likedSketches.removeWhere((s) => s.id == sketchId);
    } else {
      // Добавляем лайк
      _likedSketches.add(sketch);
    }
    
    await saveSketches();
    notifyListeners();
  }
  
  bool isLiked(String sketchId) {
    return _likedSketches.any((s) => s.id == sketchId);
  }
}