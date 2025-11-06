import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag ?? imageUrl,
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: _buildImage(),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl.startsWith('data:')) {
      return Image.memory(
        base64Decode(imageUrl.split(',')[1]),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 300,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Text(
            "Error loading image",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 300,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Text(
            "Error loading image",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 300,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Text(
            "Error loading image",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}

// Reusable Clickable Image Widget
class ClickableMessageImage extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const ClickableMessageImage({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                FullScreenImageViewer(imageUrl: imageUrl, heroTag: heroTag),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                    reverseCurve: Curves.easeInOut,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.95,
                        end: 1.0,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
          ),
        );
      },
      child: Hero(
        tag: heroTag ?? imageUrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl.startsWith('data:')) {
      return Image.memory(
        base64Decode(imageUrl.split(',')[1]),
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 150,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Text("Error loading image"),
        ),
      );
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 150,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Text("Error loading image"),
        ),
      );
    } else {
      return Image.file(
        File(imageUrl),
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 150,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Text("Error loading image"),
        ),
      );
    }
  }
}
