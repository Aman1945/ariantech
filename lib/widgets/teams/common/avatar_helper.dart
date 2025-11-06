import 'package:flutter/material.dart'; 
import '../../../config/component/color/colors.dart';

class AvatarHelper {
  static const List<Color> _bgColors = [
    Colors.red,
    Colors.green,
    AppColors.colorsBlue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.purpleAccent,
  ];

  static Color getConsistentColor(String seed) {
    final int hash = seed.codeUnits.fold(0, (prev, el) => prev + el);
    return _bgColors[hash % _bgColors.length].withOpacity(0.8);
  }

  static Widget buildAvatar({
    required String name,
    String? imageUrl,
    double radius = 12,
    double fontSize = 12,
  }) {
    final String initials = name.isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: (imageUrl == null || imageUrl.isEmpty)
          ? getConsistentColor(name)
          : Colors.transparent,
      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
          ? NetworkImage(imageUrl)
          : null,
      child: (imageUrl == null || imageUrl.isEmpty)
          ? Text(
              initials,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
