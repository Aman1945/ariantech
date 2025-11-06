import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

void showErrorMessage(BuildContext context, {required String message}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.red, // Change this to any color you like
      content: Text(
        message,
        style: GoogleFonts.poppins(
          color: Colors.white,
        ), // Ensure text is readable
      ),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating, // Optional: Makes it float above UI
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Optional: rounded corners
      ),
    ),
  );
}

void showErrorMessageGetx({required String message}) {
  Get.snackbar(
    'Error', // Title (empty to match single-line error message style)
    message,
    backgroundColor: Colors.red,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP, // Display from top
    duration: const Duration(seconds: 2),
    borderRadius: 10, // Rounded corners
    margin: const EdgeInsets.all(16), // Margin for floating effect
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    isDismissible: true, // Allow user to swipe to dismiss
    messageText: Text(
      message,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 14, // Adjust size as needed
      ),
    ),
    snackStyle: SnackStyle.FLOATING,
  );
}

void showSuccessMessage(BuildContext context, {required String message}) {
  final snackBar = SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
  );
  // ScaffoldMessenger.of(context).showSnackBar(snackBar);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.green, // Change this to any color you like
      content: Text(
        message,
        style: GoogleFonts.poppins(
          color: Colors.white,
        ), // Ensure text is readable
      ),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating, // Optional: Makes it float above UI
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Optional: rounded corners
      ),
    ),
  );
}
