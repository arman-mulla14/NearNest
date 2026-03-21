import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  final String title;
  const SettingsScreen({super.key, required this.title});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushEnabled = true;
  bool emailEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pushEnabled = prefs.getBool('push_notifications') ?? true;
      emailEnabled = prefs.getBool('email_notifications') ?? true;
    });
  }

  void _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.title.contains('Notification')) ...[
            SwitchListTile(
              title: const Text('Push Notifications'),
              activeColor: AppTheme.accentColor,
              value: pushEnabled,
              onChanged: (val) {
                setState(() => pushEnabled = val);
                _saveSetting('push_notifications', val);
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              activeColor: AppTheme.accentColor,
              value: emailEnabled,
              onChanged: (val) {
                setState(() => emailEnabled = val);
                _saveSetting('email_notifications', val);
              },
            ),
          ] else ...[
            SwitchListTile(
              title: const Text('Dark Theme'),
              activeColor: AppTheme.accentColor,
              value: themeProvider.isDarkMode,
              onChanged: (val) {
                themeProvider.toggleTheme(val);
              },
            ),
            ListTile(
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondaryColor),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent to email!')));
              },
            ),
          ],
        ],
      ),
    );
  }
}
