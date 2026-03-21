import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> images;

  const ImageCarousel({Key? key, required this.images}) : super(key: key);

  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;

  Widget _buildImage(String imageStr) {
    if (imageStr.startsWith('data:image')) {
      return Image.memory(base64Decode(imageStr.split(',').last), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Image.network(imageStr, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
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
            return _buildImage(widget.images[index]);
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
}
