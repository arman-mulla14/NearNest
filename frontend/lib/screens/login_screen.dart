import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;
  
  late AnimationController _mainController;
  late AnimationController _imageController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _imageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await authProvider.login(email, password);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final String role = (authProvider.user?['role']?.toString().trim().toLowerCase()) ?? 'user';
      if (role == 'vendor') {
        Navigator.pushReplacementNamed(context, '/vendor_home');
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials or network error occurred.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (isDesktop)
            Expanded(
              flex: 5,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _imageController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_imageController.value * 0.1),
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1560518883-ce09059eeffa?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(64.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.home_work, color: Colors.white, size: 64),
                            const SizedBox(height: 24),
                            const Text(
                              'Find Your\nPerfect Nest.',
                              style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold, height: 1.1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Premium stays, shared spaces, and more.',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          Expanded(
            flex: 4,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64.0 : 24.0, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isDesktop) ...[
                          _StaggeredAnimation(
                            controller: _mainController,
                            index: 0,
                            child: const Icon(Icons.home_work, color: AppTheme.primaryColor, size: 64),
                          ),
                          const SizedBox(height: 24),
                        ],
                        _StaggeredAnimation(
                          controller: _mainController,
                          index: 1,
                          child: const Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _StaggeredAnimation(
                          controller: _mainController,
                          index: 2,
                          child: Text(
                            'Please enter your details to sign in.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        _StaggeredAnimation(
                          controller: _mainController,
                          index: 3,
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _StaggeredAnimation(
                          controller: _mainController,
                          index: 4,
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _isObscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _isObscure = !_isObscure),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StaggeredAnimation(
                          controller: _mainController,
                          index: 5,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _StaggeredAnimation(
                          controller: _mainController,
                          index: 6,
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _StaggeredAnimation(
                          controller: _mainController,
                          index: 7,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600])),
                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                                child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.white,
        child: const Icon(Icons.settings_ethernet, color: AppTheme.primaryColor),
        onPressed: () {
          _showIpConfigDialog(context);
        },
      ),
    );
  }

  void _showIpConfigDialog(BuildContext context) {
    final ipController = TextEditingController(text: '192.168.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server IP Configuration'),
        content: TextField(
          controller: ipController,
          decoration: const InputDecoration(
            hintText: 'Enter Local IP (e.g. 192.168.x.x)',
            labelText: 'Backend IP Address',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ipController.text.isNotEmpty) {
                await ApiService.setCustomIp(ipController.text.trim());
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('IP Set to ${ipController.text}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StaggeredAnimation extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggeredAnimation({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = 0.1 * index;
    final end = start + 0.3;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final curve = CurvedAnimation(
          parent: controller,
          curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutBack),
        );

        return Opacity(
          opacity: curve.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - curve.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}


