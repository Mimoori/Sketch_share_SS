import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isZoomMode = false;
  
  final GlobalKey _canvasContainerKey = GlobalKey();
  final ScrollController _toolsScrollController = ScrollController();

  final Map<String, Size> canvasSizes = {
    'Квадрат (1000x1000)': const Size(1000, 1000),
    'Вертикаль (1080x1920)': const Size(1080, 1920),
    'Альбом (1920x1080)': const Size(1920, 1080),
    'Классика (1200x1600)': const Size(1200, 1600),
  };
  late Size canvasSize;

  Matrix4 _transform = Matrix4.identity();
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _lastFocalPoint;
  bool _isPanning = false;

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
        _transform = Matrix4.identity();
        _scale = 1.0;
        _offset = Offset.zero;
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

  void _handleScaleStart(ScaleStartDetails details) {
    if (_isZoomMode) {
      _lastFocalPoint = details.localFocalPoint;
      _isPanning = true;
    } else {
      try {
        final renderBox = _canvasContainerKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        
        final localPoint = renderBox.globalToLocal(details.focalPoint);
        
        final inverseMatrix = Matrix4.inverted(_transform);
        final transformedPoint = MatrixUtils.transformPoint(
          inverseMatrix, 
          localPoint
        );
        
        if (_isPointInCanvas(transformedPoint)) {
          setState(() {
            currentStroke = Stroke(
              points: [transformedPoint],
              color: selectedColor,
              width: strokeWidth,
              isEraser: tool == Tool.eraser,
              toolType: tool,
            );
          });
        }
      } catch (e) {
        debugPrint('Error in scale start: $e');
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isZoomMode && _isPanning) {
      setState(() {
        if (_lastFocalPoint != null) {
          final delta = details.localFocalPoint - _lastFocalPoint!;
          _offset += delta;
          _lastFocalPoint = details.localFocalPoint;
          
          _transform = Matrix4.identity()
            ..translate(_offset.dx, _offset.dy, 0.0)
            ..scale(_scale, _scale, 1.0);
        }
      });
    } else if (!_isZoomMode && currentStroke != null) {
      try {
        final renderBox = _canvasContainerKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        
        final localPoint = renderBox.globalToLocal(details.focalPoint);
        
        final inverseMatrix = Matrix4.inverted(_transform);
        final transformedPoint = MatrixUtils.transformPoint(
          inverseMatrix, 
          localPoint
        );
        
        if (_isPointInCanvas(transformedPoint)) {
          setState(() {
            currentStroke!.points.add(transformedPoint);
          });
        } else {
          setState(() {
            strokes.add(currentStroke!);
            undoStack.clear();
            currentStroke = null;
          });
        }
      } catch (e) {
        debugPrint('Error in scale update: $e');
        if (currentStroke != null) {
          setState(() {
            strokes.add(currentStroke!);
            undoStack.clear();
            currentStroke = null;
          });
        }
      }
    }
  }

  bool _isPointInCanvas(Offset point) {
    return point.dx >= 0 && 
           point.dx <= canvasSize.width &&
           point.dy >= 0 && 
           point.dy <= canvasSize.height;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isZoomMode) {
      _lastFocalPoint = null;
      _isPanning = false;
    } else if (currentStroke != null) {
      setState(() {
        strokes.add(currentStroke!);
        undoStack.clear();
        currentStroke = null;
      });
    }
  }

  void _toggleZoomMode() {
    setState(() {
      _isZoomMode = !_isZoomMode;
      if (_isZoomMode) {
        _scale = 1.5;
        _transform = Matrix4.identity()
          ..translate(_offset.dx, _offset.dy, 0.0)
          ..scale(_scale, _scale, 1.0);
      }
    });
  }

  Future<void> _saveToPostgreSQL(String imageUrl, String caption) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        _showMessage('Требуется авторизация', isError: true);
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': caption,
          'description': '',
          'firebaseImageUrl': imageUrl,
          'canvasWidth': canvasSize.width.toInt(),
          'canvasHeight': canvasSize.height.toInt(),
          'strokeCount': strokes.length,
        }),
      );

      if (response.statusCode == 201) {
        _showMessage('Пост сохранен в базе данных');
      } else {
        throw Exception('Failed to save post: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saving to PostgreSQL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          
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
        });
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(''),
          automaticallyImplyLeading: false,
          centerTitle: true,
          toolbarHeight: 50,
        ),
        body: Stack(
          children: [
            // ХОЛСТ
            Positioned.fill(
              top: 110,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onScaleEnd: _handleScaleEnd,
                child: Transform(
                  transform: _transform,
                  child: Center(
                    child: Container(
                      key: _canvasContainerKey,
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
                      width: canvasSize.width,
                      height: canvasSize.height,
                      child: CustomPaint(
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

            // Панель инструментов
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(242, 40, 40, 40),
                  border: const Border(
                    bottom: BorderSide(color: Colors.white12, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 50,
                      child: Scrollbar(
                        controller: _toolsScrollController,
                        thumbVisibility: true,
                        child: ListView(
                          controller: _toolsScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: [
                            _compactToolBtn(Icons.undo, 'Отменить', _undo),
                            const SizedBox(width: 8),
                            _compactToolBtn(Icons.redo, 'Повторить', _redo),
                            const SizedBox(width: 16),
                            _compactToolBtnTool(Tool.brush, Icons.brush, 'Кисть'),
                            const SizedBox(width: 8),
                            _compactToolBtnTool(Tool.pencil, Icons.edit, 'Карандаш'),
                            const SizedBox(width: 8),
                            _compactToolBtnTool(Tool.eraser, Icons.auto_fix_high, 'Ластик'),
                            const SizedBox(width: 16),
                            _compactToolBtnZoom(Icons.zoom_in_map, 'Масштаб', _toggleZoomMode),
                            const SizedBox(width: 16),
                            _compactToolBtn(Icons.public, 'В ленту', _showPublishDialog),
                            const SizedBox(width: 8),
                            _compactToolBtn(Icons.color_lens, 'Палитра', () => setState(() => showPanel = !showPanel)),
                            const SizedBox(width: 8),
                            _compactToolBtn(Icons.grid_on, 'Сетка', () {}),
                            const SizedBox(width: 8),
                            _compactToolBtn(Icons.layers, 'Слои', () {}),
                            const SizedBox(width: 8),
                            _compactToolBtn(Icons.text_fields, 'Текст', () {}),
                            const SizedBox(width: 8),
                            _compactToolBtn(Icons.shape_line, 'Фигуры', () {}),
                          ],
                        ),
                      ),
                    ),
                    
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(230, 30, 30, 30),
                        border: Border(
                          top: BorderSide(color: Colors.white12, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveImage,
                              icon: const Icon(Icons.save_alt, size: 22),
                              label: const Text('Сохранить', style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(204, 60, 60, 60),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: selectedColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  _getToolIcon(tool),
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${strokeWidth.round()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getToolName(tool),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isZoomMode)
              Positioned(
                top: 120,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(153, 0, 0, 0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.zoom_in_map, color: Colors.yellow, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Режим панорамирования',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        bottomSheet: showPanel
            ? Container(
                height: 150,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(242, 0, 0, 0),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.delta.dy > 10) {
                          setState(() => showPanel = false);
                        }
                      },
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
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          ...[
                            Colors.black,
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
                            Colors.indigo,
                            Colors.teal,
                            Colors.amber,
                            Colors.lightBlue,
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
                                child: selectedColor == color
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 10),
                      child: Row(
                        children: [
                          const Text(
                            'Толщина:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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
                              inactiveColor: Colors.grey[700],
                              onChanged: (value) =>
                                  setState(() => strokeWidth = value),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(179, 103, 58, 183),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${strokeWidth.round()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _compactToolBtn(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _compactToolBtnTool(Tool t, IconData icon, String tooltip) {
    bool selected = tool == t;
    Color iconColor;
    switch (t) {
      case Tool.brush:
        iconColor = const Color(0xFF90CAF9);
        break;
      case Tool.pencil:
        iconColor = const Color(0xFFA5D6A7);
        break;
      case Tool.eraser:
        iconColor = const Color(0xFFEF9A9A);
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? Color.fromARGB(51, iconColor.red, iconColor.green, iconColor.blue) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
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
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 24, color: selected ? iconColor : Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _compactToolBtnZoom(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _isZoomMode ? const Color.fromARGB(51, 255, 255, 0) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(_isZoomMode ? Icons.brush : icon, size: 24, color: _isZoomMode ? Colors.yellow : Colors.white),
          ),
        ),
      ),
    );
  }

  IconData _getToolIcon(Tool tool) {
    switch (tool) {
      case Tool.brush:
        return Icons.brush;
      case Tool.pencil:
        return Icons.edit;
      case Tool.eraser:
        return Icons.auto_fix_high;
    }
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

  Future<void> _saveImage() async {
    if (!mounted) return;
    
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
      
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      await _saveToGallery(bytes);

    } catch (e) {
      _hideLoadingIndicator();
      _showMessage('Ошибка сохранения: $e', isError: true);
    }
  }

  Future<void> _saveToGallery(Uint8List bytes) async {
    try {
      String? galleryPath;
      
      final possiblePaths = [
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/DCIM',
        '/sdcard/Pictures',
        '/sdcard/DCIM',
      ];

      for (final path in possiblePaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          galleryPath = path;
          break;
        }
      }

      if (galleryPath == null) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          galleryPath = externalDir.path;
        }
      }

      if (galleryPath == null) {
        final appDir = await getApplicationDocumentsDirectory();
        galleryPath = appDir.path;
      }

      final appGalleryDir = Directory('$galleryPath/SketchShare');
      if (!await appGalleryDir.exists()) {
        await appGalleryDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final width = canvasSize.width.toInt();
      final height = canvasSize.height.toInt();
      final fileName = 'sketch_${width}x${height}_$timestamp.png';
      final filePath = '${appGalleryDir.path}/$fileName';
      final file = File(filePath);
      
      await file.writeAsBytes(bytes);

      _hideLoadingIndicator();
      
      _showSuccessDialog(filePath, fileName, width, height);

    } catch (e) {
      await _saveToDocuments(bytes);
    }
  }

  Future<void> _saveToDocuments(Uint8List bytes) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final width = canvasSize.width.toInt();
      final height = canvasSize.height.toInt();
      final fileName = 'sketch_${width}x${height}_$timestamp.png';
      final filePath = '${appDir.path}/$fileName';
      final file = File(filePath);
      
      await file.writeAsBytes(bytes);

      _hideLoadingIndicator();
      
      _showSaveDialog(filePath, fileName, 'память приложения', width, height);

    } catch (e) {
      _hideLoadingIndicator();
      _showMessage('Не удалось сохранить: $e', isError: true);
    }
  }

  void _showSuccessDialog(String filePath, String fileName, int width, int height) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Сохранено!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Рисунок сохранен в галерее.'),
            const SizedBox(height: 12),
            _buildInfoRow('Размер:', '${width}x$height пикселей'),
            _buildInfoRow('Файл:', fileName),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Найдите файл в папке "SketchShare" в галерее устройства.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отлично!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(String filePath, String fileName, String location, int width, int height) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранено'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Рисунок сохранен в $location.'),
            const SizedBox(height: 10),
            _buildInfoRow('Размер:', '${width}x$height пикселей'),
            _buildInfoRow('Файл:', fileName),
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

  void _showLoadingIndicator() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      ),
    );
  }

  void _hideLoadingIndicator() {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _showPublishDialog() async {
    if (!mounted) return;
    
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

      // 1. Создаем изображение
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
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // 2. Сохраняем в Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'sketches/sketch_$timestamp.png';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'author': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        },
      );
      
      await ref.putData(bytes, metadata);
      final imageUrl = await ref.getDownloadURL();

      // 3. Сохраняем в PostgreSQL
      await _saveToPostgreSQL(imageUrl, caption);

      // 4. Показываем успех
      _hideLoadingIndicator();
      _showMessage('Успешно опубликовано в ленту!');
      
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      _hideLoadingIndicator();
      _showMessage('Ошибка публикации: $e', isError: true);
      debugPrint('Publish error details: $e');
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

    final allStrokes = [...strokes];
    if (currentStroke != null) {
      allStrokes.add(currentStroke!);
    }

    for (final stroke in allStrokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke
        ..color = stroke.isEraser ? Colors.white : stroke.color;

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