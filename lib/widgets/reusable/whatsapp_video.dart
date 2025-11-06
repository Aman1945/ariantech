import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WhatsappVideo extends StatefulWidget {
  final String videoUrl;
  final String? heroTag;
  final bool isVideo; // Add this to distinguish between video and image

  const WhatsappVideo({
    super.key,
    required this.videoUrl,
    this.heroTag,
    this.isVideo = false, // Default to false for backward compatibility
  });

  @override
  State<WhatsappVideo> createState() => _WhatsappVideoState();
}

class _WhatsappVideoState extends State<WhatsappVideo> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializeVideoPlayer();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      if (widget.videoUrl.startsWith('http')) {
        _videoController = VideoPlayerController.network(widget.videoUrl);
      } else {
        _videoController = VideoPlayerController.file(File(widget.videoUrl));
      }

      await _videoController!.initialize();

      setState(() {
        _isLoading = false;
      });

      _videoController!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _videoController!.value.isPlaying;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error loading video: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: widget.heroTag ?? widget.videoUrl,
              child: widget.isVideo ? _buildVideoPlayer() : _buildImageViewer(),
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
          // Video controls overlay
          if (widget.isVideo &&
              _videoController != null &&
              _videoController!.value.isInitialized)
            _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error loading video',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: Text(
          'Video not available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4.0,
      child: _buildImage(),
    );
  }

  Widget _buildVideoControls() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Progress bar
            VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(height: 10),
            // Play/Pause button and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_videoController!.value.position),
                  style: const TextStyle(color: Colors.white),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                ),
                Text(
                  _formatDuration(_videoController!.value.duration),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  Widget _buildImage() {
    if (widget.videoUrl.startsWith('data:')) {
      return Image.memory(
        base64Decode(widget.videoUrl.split(',')[1]),
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
    } else if (widget.videoUrl.startsWith('http')) {
      return Image.network(
        widget.videoUrl,
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
        File(widget.videoUrl),
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

// Updated Clickable Message Image Widget
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
                WhatsappVideo(
                  videoUrl: imageUrl,
                  heroTag: heroTag,
                  isVideo: false, // This is for images
                ),
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

// New Clickable Video Widget
class ClickableMessageVideo extends StatelessWidget {
  final String videoUrl;
  final String? heroTag;

  const ClickableMessageVideo({
    super.key,
    required this.videoUrl,
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
                WhatsappVideo(
                  videoUrl: videoUrl,
                  heroTag: heroTag,
                  isVideo: true, // This is for videos
                ),
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
        tag: heroTag ?? videoUrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildVideoThumbnail(),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video thumbnail placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.videocam, size: 40, color: Colors.white),
          ),
          // Play button overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow, color: Colors.white, size: 30),
          ),
          // Duration badge (optional)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Video',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
