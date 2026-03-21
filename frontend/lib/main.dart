import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/vendor_home_screen.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.loadUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const NearNestApp(),
    ),
  );
}

class NearNestApp extends StatelessWidget {
  const NearNestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/vendor_home': (context) => const VendorHomeScreen(),
      },
    );
  }
}
