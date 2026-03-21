import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : AppTheme.accentColor),
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : AppTheme.textPrimaryColor, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondaryColor),
      onTap: onTap,
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature module is under active development.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                    child: Text(
                      user?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?['name'] ?? 'User Name', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(user?['email'] ?? 'user@email.com', style: const TextStyle(color: AppTheme.textSecondaryColor)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accentColor),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 14, color: AppTheme.accentColor),
                              SizedBox(width: 4),
                              Text('Trusted User', style: TextStyle(fontSize: 12, color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Statistics Row
            Row(
              children: [
                _buildStatCard('0', 'Bookings'),
                const SizedBox(width: 16),
                _buildStatCard('0', 'Favorites'),
                const SizedBox(width: 16),
                _buildStatCard('0', 'Reviews'),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Options
            _buildMenuOption(Icons.person_outline, 'Personal Information', () => _showComingSoon('Personal Info')),
            const Divider(color: AppTheme.cardColor, indent: 60),
            _buildMenuOption(Icons.history, 'Booking History', () => _showComingSoon('Bookings')),
            const Divider(color: AppTheme.cardColor, indent: 60),
            _buildMenuOption(Icons.favorite_border, 'Saved Properties', () => _showComingSoon('Saved')),
            const Divider(color: AppTheme.cardColor, indent: 60),
            _buildMenuOption(Icons.star_border, 'My Reviews', () => _showComingSoon('Reviews')),
            const SizedBox(height: 24),

            // Support & Settings
            const Align(alignment: Alignment.centerLeft, child: Text('Support & Settings', style: TextStyle(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: 12),
            _buildMenuOption(Icons.report_problem_outlined, 'My Complaints', () => _showComingSoon('Complaints')),
            const Divider(color: AppTheme.cardColor, indent: 60),
            _buildMenuOption(Icons.settings_outlined, 'Account Settings', () => _showComingSoon('Settings')),
            const Divider(color: AppTheme.cardColor, indent: 60),
            _buildMenuOption(Icons.notifications_outlined, 'Notification Settings', () => _showComingSoon('Notifications')),
            const Divider(color: AppTheme.cardColor, indent: 60),
            _buildMenuOption(Icons.shield_outlined, 'Identity Verification (KYC)', () => _showComingSoon('KYC')),
            const SizedBox(height: 24),

            // Logout
            _buildMenuOption(Icons.logout, 'Log Out', _logout, isDestructive: true),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}
