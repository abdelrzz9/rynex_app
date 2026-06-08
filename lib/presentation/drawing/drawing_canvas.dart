import 'package:flutter/material.dart';

import 'canvas_painter.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({required this.isDarkMode, super.key});

  final bool isDarkMode;

  @override
  DrawingCanvasState createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void clear() {
    setState(() {
      _strokes = [];
      _currentStroke = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canvasColor = widget.isDarkMode ? const Color(0xFF101318) : Colors.white;
    final strokeColor = widget.isDarkMode ? Colors.white : Colors.black;

    return ColoredBox(
      color: canvasColor,
      child: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              setState(() => _currentStroke = [details.localPosition]);
            },
            onPanUpdate: (details) {
              setState(() {
                _currentStroke = [..._currentStroke, details.localPosition];
              });
            },
            onPanEnd: (_) {
              setState(() {
                if (_currentStroke.length > 1) {
                  _strokes.add(List.from(_currentStroke));
                }
                _currentStroke = [];
              });
            },
            child: CustomPaint(
              painter: CanvasPainter(
                strokes: _strokes,
                currentStroke: _currentStroke,
                strokeColor: strokeColor,
              ),
              size: Size.infinite,
            ),
          ),
          if (_strokes.isEmpty && _currentStroke.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Draw anywhere to start',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
