import 'package:flutter/material.dart';

class TooltipHelper {
  static void showBubbleTooltip(
    BuildContext context,
    GlobalKey key,
    String message,
  ) {
    final overlay = Overlay.of(context);
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size;
    final offset = renderBox?.localToGlobal(Offset.zero);

    if (overlay == null ||
        renderBox == null ||
        offset == null ||
        size == null) {
      return;
    }

    const double tooltipPadding = 20.0;
    final double estimatedTooltipWidth = message.length * 7.0 + tooltipPadding;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy - 35,
        left: offset.dx + size.width / 2 - estimatedTooltipWidth / 2,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
  }
}
