import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlaceholderListScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String emptyMessage;

  const PlaceholderListScreen({super.key, required this.title, required this.icon, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppTheme.cardColor),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}
