import 'package:flutter/material.dart';

class FieldTooltipWidget extends StatelessWidget {
  final String text;
  final Widget child;
  
  const FieldTooltipWidget({
    super.key,
    required this.text,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      preferBelow: false,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        height: 1.4,
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: child,
    );
  }
}
