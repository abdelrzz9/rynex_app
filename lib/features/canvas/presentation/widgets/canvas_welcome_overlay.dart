import 'package:flutter/material.dart';

// FEATURE 2 DONE — Welcome overlay shown briefly on canvas entry
class CanvasWelcomeOverlay {
  static void show(BuildContext context, String canvasName) {
    final overlay = Overlay.of(context);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => _CanvasWelcomeOverlayWidget(
        canvasName: canvasName,
        onDismiss: () => entry?.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _CanvasWelcomeOverlayWidget extends StatefulWidget {
  final String canvasName;
  final VoidCallback onDismiss;

  const _CanvasWelcomeOverlayWidget({
    required this.canvasName,
    required this.onDismiss,
  });

  @override
  State<_CanvasWelcomeOverlayWidget> createState() => _CanvasWelcomeOverlayWidgetState();
}

class _CanvasWelcomeOverlayWidgetState extends State<_CanvasWelcomeOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _controller.reverse().then((_) => widget.onDismiss());
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Text(
            widget.canvasName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
