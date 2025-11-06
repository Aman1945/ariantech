import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final bool isSelected;
  final Color backgroundColor;
  final Color textColor;
  final bool isUserSelected;

  const MetricCard({
    Key? key,
    required this.value,
    required this.label,
    required this.valueColor,
    this.isSelected = false,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.isUserSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.5, horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isSelected && !isUserSelected)
              ? Colors.transparent
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            textAlign: TextAlign.left,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: backgroundColor == Colors.white ? valueColor : textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: textColor.withOpacity(0.7),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
