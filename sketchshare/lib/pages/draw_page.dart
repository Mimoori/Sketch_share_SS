import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DrawPage extends StatefulWidget {
  const DrawPage({super.key});
  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  List<Stroke> strokes = [];
  List<Stroke> undoStack = [];
  Stroke? currentStroke;
  Tool tool = Tool.brush;
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;
  bool showPanel = false;

  final Map<String, Size> canvasSizes = {
    'Квадрат (1000x1000)': const Size(1000, 1000),
    'Вертикаль (1080x1920)': const Size(1080, 1920),
    'Альбом (1920x1080)': const Size(1920, 1080),
    'Классика (1200x1600)': const Size(1200, 1600),
  };
  late Size canvasSize;

  // Для масштабирования
  final TransformationController _transformationController =
      TransformationController();
  double _scale = 1.0;
  bool _isScaling = false;
  Offset _lastFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    canvasSize = canvasSizes.values.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSizeDialog();
    });
  }

  Future<void> _showSizeDialog() async {
    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Выберите размер холста'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: canvasSizes.keys.map((name) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(name),
                subtitle: Text(
                    '${canvasSizes[name]!.width.toInt()}x${canvasSizes[name]!.height.toInt()}'),
                onTap: () => Navigator.pop(context, name),
              ),
            )).toList(),
          ),
        ),
      ),
    );
    if (selected != null && canvasSizes[selected] != null) {
      setState(() {
        canvasSize = canvasSizes[selected]!;
        _transformationController.value = Matrix4.identity();
        _scale = 1.0;
      });
    }
  }

  void _undo() {
    if (strokes.isNotEmpty) {
      setState(() {
        undoStack.add(strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (undoStack.isNotEmpty) {
      setState(() {
        strokes.add(undoStack.removeLast());
      });
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount == 2) {
      _isScaling = true;
      _lastFocalPoint = details.focalPoint;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 2) {
      _isScaling = true;
      setState(() {
        _scale = details.scale * _scale;
        _scale = _scale.clamp(0.1, 10.0);

        final offset = details.focalPoint - _lastFocalPoint;
        _lastFocalPoint = details.focalPoint;

        final matrix = Matrix4.identity();
        matrix.translate(offset.dx, offset.dy);
        matrix.scale(_scale);
        _transformationController.value = matrix;
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isScaling = false;
  }

  void _resetTransform() {
    setState(() {
      _transformationController.value = Matrix4.identity();
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Выйти?'),
            content: const Text('Скетч не сохранён. Точно выйти?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Нет'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Да'),
              ),
            ],
          ),
        );
        if (exit == true && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text('Новый скетч'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: _undo,
              icon: const Icon(Icons.undo),
              tooltip: 'Отменить',
            ),
            IconButton(
              onPressed: _redo,
              icon: const Icon(Icons.redo),
              tooltip: 'Повторить',
            ),
            _toolBtn(Tool.brush, Icons.brush, 'Кисть'),
            _toolBtn(Tool.pencil, Icons.edit, 'Карандаш'),
            _toolBtn(Tool.eraser, Icons.auto_fix_high, 'Ластик'),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _resetTransform,
              icon: const Icon(Icons.zoom_out_map),
              tooltip: 'Сбросить масштаб',
            ),
            IconButton(
              onPressed: _saveImage,
              icon: const Icon(Icons.save_alt),
              tooltip: 'Сохранить',
            ),
            IconButton(
              onPressed: _showPublishDialog,
              icon: const Icon(Icons.send),
              tooltip: 'Опубликовать',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Холст с поддержкой жестов
            GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: Transform(
                transform: _transformationController.value,
                child: Center(
                  child: Container(
                    width: canvasSize.width,
                    height: canvasSize.height,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: GestureDetector(
                      onPanStart: (details) {
                        if (!_isScaling) {
                          final offset = details.localPosition;
                          setState(() {
                            currentStroke = Stroke(
                              points: [offset],
                              color: selectedColor,
                              width: strokeWidth,
                              isEraser: tool == Tool.eraser,
                              toolType: tool,
                            );
                          });
                        }
                      },
                      onPanUpdate: (details) {
                        if (!_isScaling && currentStroke != null) {
                          final offset = details.localPosition;
                          setState(() {
                            currentStroke!.points.add(offset);
                          });
                        }
                      },
                      onPanEnd: (details) {
                        if (!_isScaling && currentStroke != null) {
                          setState(() {
                            strokes.add(currentStroke!);
                            undoStack.clear();
                            currentStroke = null;
                          });
                        }
                      },
                      child: CustomPaint(
                        size: canvasSize,
                        painter: SketchPainter(
                          strokes: strokes,
                          currentStroke: currentStroke,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

           
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Инструмент: ${_getToolName(tool)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Масштаб: ${_scale.toStringAsFixed(1)}x',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Толщина: ${strokeWidth.round()}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: showPanel ? 0 : -150,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => showPanel = !showPanel),
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 60,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          ...[
                            Colors.black,
                            Colors.white,
                            Colors.red,
                            Colors.blue,
                            Colors.green,
                            Colors.yellow,
                            Colors.purple,
                            Colors.orange,
                            Colors.brown,
                            Colors.pink,
                            Colors.cyan,
                            Colors.grey,
                          ].map((color) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setState(() => selectedColor = color),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedColor == color
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                      child: Row(
                        children: [
                          const Text(
                            'Толщина:',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Slider(
                              value: strokeWidth,
                              min: 1,
                              max: tool == Tool.eraser ? 50 : 30,
                              divisions: tool == Tool.eraser ? 49 : 29,
                              activeColor: tool == Tool.eraser
                                  ? Colors.red
                                  : Colors.deepPurple,
                              inactiveColor: Colors.grey,
                              onChanged: (value) =>
                                  setState(() => strokeWidth = value),
                            ),
                          ),
                          Text(
                            '${strokeWidth.round()}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  backgroundColor: Colors.deepPurple,
                  onPressed: () => setState(() => showPanel = !showPanel),
                  child: Icon(
                    showPanel ? Icons.keyboard_arrow_down : Icons.palette,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getToolName(Tool tool) {
    switch (tool) {
      case Tool.brush:
        return 'Кисть';
      case Tool.pencil:
        return 'Карандаш';
      case Tool.eraser:
        return 'Ластик';
    }
  }

  Widget _toolBtn(Tool t, IconData icon, String tooltip) {
    bool selected = tool == t;
    Color iconColor;
    switch (t) {
      case Tool.brush:
        iconColor = Colors.blue;
        break;
      case Tool.pencil:
        iconColor = Colors.green;
        break;
      case Tool.eraser:
        iconColor = Colors.red;
        break;
    }

    return IconButton(
      icon: Icon(icon),
      color: selected ? iconColor : Colors.white,
      tooltip: tooltip,
      onPressed: () {
        setState(() {
          tool = t;
          if (t == Tool.eraser) {
            strokeWidth = 20.0;
          } else if (t == Tool.pencil) {
            strokeWidth = 3.0;
          } else {
            strokeWidth = 5.0;
          }
        });
      },
    );
  }

  Future<void> _saveImage() async {
    if (strokes.isEmpty) {
      _showMessage('Нет ничего для сохранения!', isError: true);
      return;
    }

    try {
      
      _showLoadingIndicator();

      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        Paint()..color = Colors.white,
      );

      
      for (final stroke in strokes) {
        final paint = Paint()
          ..color = stroke.isEraser ? Colors.white : stroke.color
          ..strokeWidth = stroke.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        if (stroke.points.length > 1) {
          final path = Path();
          path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
          for (int i = 1; i < stroke.points.length; i++) {
            path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
          }
          canvas.drawPath(path, paint);
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        canvasSize.width.toInt(),
        canvasSize.height.toInt(),
      );
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'sketch_$timestamp.png';
      final filePath = '${appDir.path}/$fileName';
      final file = File(filePath);
      
      await file.writeAsBytes(bytes);

     
      _hideLoadingIndicator();

      
      _showSaveDialog(filePath, fileName);

    } catch (e) {
      _hideLoadingIndicator();
      _showMessage('Ошибка сохранения: $e', isError: true);
    }
  }

  void _showLoadingIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingIndicator() {
    Navigator.of(context).pop();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSaveDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранено успешно!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Рисунок сохранен в памяти приложения.'),
            const SizedBox(height: 10),
            Text(
              'Файл: $fileName',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              'Путь: ${filePath.split('/').sublist(0, 3).join('/')}/.../${filePath.split('/').last}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            const Text(
              'Чтобы получить доступ к файлу, воспользуйтесь файловым менеджером устройства.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPublishDialog() async {
    if (strokes.isEmpty) {
      _showMessage('Нет ничего для публикации!', isError: true);
      return;
    }

    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выложить в ленту?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Подпись (необязательно)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Text(
              'Размер холста: ${canvasSize.width.toInt()}x${canvasSize.height.toInt()}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text('Выложить'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _publish(controller.text.trim());
    }
  }

  Future<void> _publish(String caption) async {
    try {
      _showLoadingIndicator();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        Paint()..color = Colors.white,
      );

      for (final stroke in strokes) {
        final paint = Paint()
          ..color = stroke.isEraser ? Colors.white : stroke.color
          ..strokeWidth = stroke.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        if (stroke.points.length > 1) {
          final path = Path();
          path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
          for (int i = 1; i < stroke.points.length; i++) {
            path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
          }
          canvas.drawPath(path, paint);
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        canvasSize.width.toInt(),
        canvasSize.height.toInt(),
      );
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final ref = FirebaseStorage.instance.ref().child(
          'sketches/${DateTime.now().millisecondsSinceEpoch}.png');
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('sketches').add({
        'imageUrl': url,
        'caption': caption,
        'authorName': FirebaseAuth.instance.currentUser?.displayName ?? 'Аноним',
        'authorId': FirebaseAuth.instance.currentUser?.uid,
        'canvasSize': {'width': canvasSize.width, 'height': canvasSize.height},
        'timestamp': FieldValue.serverTimestamp(),
        'toolCount': strokes.length,
      });

      _hideLoadingIndicator();
      _showMessage('Успешно опубликовано!');
      
      // Задержка перед возвратом
      await Future.delayed(const Duration(seconds: 2));
      Navigator.of(context).pop();

    } catch (e) {
      _hideLoadingIndicator();
      _showMessage('Ошибка публикации: $e', isError: true);
    }
  }
}

enum Tool { brush, pencil, eraser }

class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
  final Tool toolType;

  Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.isEraser,
    required this.toolType,
  });
}

class SketchPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  SketchPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final all = [...strokes];
    if (currentStroke != null) all.add(currentStroke!);

    for (final stroke in all) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke;

      if (stroke.isEraser) {
        
        paint.color = Colors.white;
      } else {
        paint.color = stroke.color;
      }

      final path = Path();
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}