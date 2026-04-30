import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    Timer(const Duration(seconds: 3), () {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        final String role = (authProvider.user?['role']?.toString().trim().toLowerCase()) ?? 'user';
        if (role == 'vendor') {
           Navigator.pushReplacementNamed(context, '/vendor_home');
        } else {
           Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_work_rounded,
                size: 100,
                color: AppTheme.accentColor,
              ),
              const SizedBox(height: 20),
              Text(
                'NearNest',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Find your next stay effortlessly',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
