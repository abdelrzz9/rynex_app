import 'package:flutter/material.dart';

void main() => runApp(const DrawingApp());

class DrawingApp extends StatelessWidget {
  const DrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DrawingCanvas());
  }
}

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  // your scene graph — starts empty
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _currentStroke = [details.localPosition];
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _currentStroke.add(details.localPosition);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _strokes.add(List.from(_currentStroke));
            _currentStroke = [];
          });
        },
        child: CustomPaint(
          painter: CanvasPainter(
            strokes: _strokes,
            currentStroke: _currentStroke,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  const CanvasPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // draw all completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    // draw the stroke currently being drawn
    _drawStroke(canvas, currentStroke, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) => true;
}
