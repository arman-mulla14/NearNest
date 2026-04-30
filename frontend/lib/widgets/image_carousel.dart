import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final bool isInteractive;

  const ImageCarousel({Key? key, required this.images, this.isInteractive = true}) : super(key: key);

  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;

  Widget _buildImage(String imageStr) {
    if (imageStr.isEmpty) {
      return _buildPlaceholder();
    }

    try {
      if (imageStr.startsWith('data:image')) {
        return Image.memory(
          base64Decode(imageStr.split(',').last),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
      return Image.network(
        imageStr,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: AppTheme.accentColor,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } catch (e) {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1000&q=80'),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_work_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('Image Coming Soon', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: AppTheme.cardColor,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: AppTheme.textSecondaryColor),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final image = _buildImage(widget.images[index]);
            if (!widget.isInteractive) return image;
            return GestureDetector(
              onTap: () => _showFullScreenImage(context, index),
              child: image,
            );
          },
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                    color: _currentIndex == index ? AppTheme.accentColor : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: PageView.builder(
          itemCount: widget.images.length,
          controller: PageController(initialPage: initialIndex),
          itemBuilder: (context, index) {
            return Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: _buildImage(widget.images[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}
