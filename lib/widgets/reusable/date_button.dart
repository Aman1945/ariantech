import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';

class DateButton extends StatelessWidget {
  final String label;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  bool isRequired = false;
  final ValueChanged<String> onChanged;
  // final String? errorText;
  final String? dateErrorText;
  final String? timeErrorText;

  DateButton({
    super.key,
    required this.label,
    required this.dateController,
    required this.timeController,
    required this.onDateTap,
    required this.onTimeTap,
    required this.isRequired,
    required this.onChanged, this.dateErrorText, this.timeErrorText,
    
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Text(label, style: AppFont.dropDowmLabel(context)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.fontBlack,
              ),
              children: [
                TextSpan(text: label),
                if (isRequired)
                  const TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPickerField(
            errorText: dateErrorText,
            controller: dateController,
            onTap: onDateTap,
            icon: Icons.calendar_month_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPickerField(
            errorText: timeErrorText,
            controller: timeController,
            onTap: onTimeTap,
            icon: Icons.watch_later_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField({
    required TextEditingController controller,
    required VoidCallback onTap,
    required IconData icon,
    required errorText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        width: double.infinity,
        decoration: BoxDecoration(
          border: errorText != null
              ? Border.all(color: Colors.red, width: 1.0)
              : null,
          borderRadius: BorderRadius.circular(8),
          color: const Color.fromARGB(255, 248, 247, 247),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                controller.text.isEmpty ? "Select" : controller.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: controller.text.isEmpty ? Colors.grey : Colors.black,
                ),
              ),
            ),
            Icon(icon, color: AppColors.fontColor),
          ],
        ),
      ),
    );
  }
}
