import 'package:flutter/material.dart';
import 'package:smartassist/config/component/font/font.dart';

class InternetException extends StatelessWidget {
  final VoidCallback onRetry;

  const InternetException({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 80, color: Colors.grey[700]),
                const SizedBox(height: 20),
                Text(
                  'No Internet Connection',
                  style: AppFont.dropDowmLabel(context),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: AppFont.dropDowmLabelLightcolors(context),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text('Retry', style: AppFont.buttons(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
