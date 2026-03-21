import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'User';
  bool _isObscure = true;

  void _register() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final success = await authProvider.register(name, email, password, _selectedRole);
    if (success) {
      Navigator.popUntil(context, ModalRoute.withName('/login'));
      if (_selectedRole.toLowerCase() == 'vendor') {
        Navigator.pushReplacementNamed(context, '/vendor_home');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join NearNest',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Sign up to find or list properties',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                dropdownColor: AppTheme.cardColor,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: AppTheme.textSecondaryColor),
                ),
                items: ['User', 'Vendor'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRole = val ?? 'User';
                  });
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _register,
                child: const Text('REGISTER'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text("Already have an account? ", style: TextStyle(color: AppTheme.textSecondaryColor)),
                   GestureDetector(
                     onTap: () {
                       Navigator.pop(context);
                     },
                     child: const Text('Login', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
