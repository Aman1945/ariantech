import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';

class ActionButton extends StatefulWidget {
  final bool isRequired;
  final Map<String, String> options;
  final String groupValue;
  final String label;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const ActionButton({
    super.key,
    this.isRequired = false,
    required this.options,
    required this.groupValue,
    required this.label,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  @override
  Widget build(BuildContext context) {
    final optionKeys = widget.options.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 248, 247, 247),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            border: widget.errorText != null
                ? Border.all(color: Colors.red, width: 1.0)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label with asterisk if required
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0, left: 5),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.fontBlack,
                      ),
                      children: [
                        TextSpan(text: widget.label),
                        if (widget.isRequired)
                          const TextSpan(
                            text: " *",
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ),

                // Button list
                Wrap(
                  spacing: 5,
                  runSpacing: 10,
                  children: optionKeys.map((shortText) {
                    bool isSelected =
                        widget.groupValue == widget.options[shortText];

                    return GestureDetector(
                      onTap: () {
                        widget.onChanged(widget.options[shortText]!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? AppColors.colorsBlueButton
                                : AppColors.fontColor,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          color: isSelected
                              ? AppColors.colorsBlue.withOpacity(0.2)
                              : AppColors.innerContainerBg,
                        ),
                        child: Text(
                          shortText,
                          style: GoogleFonts.poppins(
                            color: isSelected
                                ? AppColors.colorsBlue
                                : AppColors.fontColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // Error text if any
        // if (widget.errorText != null)
        //   Padding(
        //     padding: const EdgeInsets.only(left: 5, top: 5),
        //     child: Text(
        //       widget.errorText!,
        //       style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
        //     ),
        //   ),
      ],
    );
  }
}
