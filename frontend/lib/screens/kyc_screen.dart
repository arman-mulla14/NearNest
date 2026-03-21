import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KycScreen extends StatelessWidget {
  const KycScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: AppTheme.accentColor),
            const SizedBox(height: 16),
            const Text('Your identity is securely verified!', style: TextStyle(fontSize: 18, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Profile', style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      ),
    );
  }
}
