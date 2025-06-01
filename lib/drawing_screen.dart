import 'dart:developer';
import 'dart:html' as html; // Only used on web
import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:drawing_app_flutter/drawline.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<DrawnLine> _lines = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 6.0;

  final _globalKey = GlobalKey();

  /*  void _undo() {
    for (int i = _lines.length - 1; i >= 0; i--) {
      if (_lines[i].isNewLine) {
        _lines.removeAt(i);
        break;
      } else {
        _lines.removeAt(i);
      }
    }
    setState(() {});
  } */
  void _undo() {
    if (_lines.isNotEmpty) {
      _lines.removeLast();
    }
  }

  void _save() async {
    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        // Web: Use dart:html for download
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor =
            html.AnchorElement(href: url)
              ..download =
                  'drawing_${DateTime.now().millisecondsSinceEpoch}.png'
              ..style.display = 'none';
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile/Desktop: Use path_provider and dart:io
        final dir = await getApplicationDocumentsDirectory();
        final file = io.File(
          '${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(pngBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Saved to: ${file.path}")));
      }
    } catch (e) {
      log("Error saving image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _globalKey,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _lines.add(
                      DrawnLine(
                        points: [details.localPosition],
                        color: _selectedColor,
                        strokeWidth: _strokeWidth,
                        isNewLine: true,
                      ),
                    );
                  });
                },
                onPanUpdate: (details) {
                  if (_lines.isNotEmpty) {
                    setState(() {
                      _lines.last.points.add(details.localPosition);
                    });
                  }
                },
                child: CustomPaint(
                  painter: DrawingPainter(lines: _lines),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...[
                Colors.black,
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.purple,
              ].map(
                (color) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: _selectedColor == color ? 3 : 1,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Brush: ${_strokeWidth.toInt()}"),
              Slider(
                value: _strokeWidth,
                onChanged: (val) => setState(() => _strokeWidth = val),
                min: 2,
                max: 30,
                divisions: 14,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _lines.clear()),
                child: const Text("Clear"),
              ),
              ElevatedButton(onPressed: _undo, child: const Text("Undo")),
              ElevatedButton(
                onPressed: _save,
                child: const Text("Save to PNG"),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
