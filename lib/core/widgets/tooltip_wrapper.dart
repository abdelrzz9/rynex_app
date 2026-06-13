import 'package:flutter/material.dart';

class TooltipWrapper extends StatelessWidget {
  final String message;
  final Widget child;

  const TooltipWrapper({
    required this.message,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      preferBelow: false,
      child: child,
    );
  }
}
