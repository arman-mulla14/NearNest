import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'personal_info_screen.dart';
import 'settings_screen.dart';
import 'complaints_screen.dart';
import 'placeholder_list_screen.dart';
import 'kyc_screen.dart';
import 'booking_history_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    });
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : theme.colorScheme.primary),
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.hintColor),
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Text(
                      (user?['name'] != null && user!['name'].isNotEmpty)
                          ? user['name'].substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?['name'] ?? 'User Name', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(user?['email'] ?? 'user@email.com', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Theme.of(context).colorScheme.primary),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 14, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text('Trusted User', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
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
            _buildMenuOption(Icons.person_outline, 'Personal Information', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()))),
            const Divider(color: AppTheme.cardColor, indent: 60),
            _buildMenuOption(Icons.history, 'Booking History', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen()))),
            const Divider(color: AppTheme.cardColor, indent: 60),
            _buildMenuOption(Icons.favorite_border, 'Saved Properties', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderListScreen(title: 'Saved Properties', icon: Icons.favorite, emptyMessage: 'No saved properties found.')))),
            const Divider(color: AppTheme.cardColor, indent: 60),
            _buildMenuOption(Icons.star_border, 'My Reviews', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderListScreen(title: 'My Reviews', icon: Icons.star, emptyMessage: 'You haven\'t left any reviews yet.')))),
            const SizedBox(height: 24),

            // Support & Settings
            Align(alignment: Alignment.centerLeft, child: Text('Support & Settings', style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: 12),
            _buildMenuOption(Icons.report_problem_outlined, 'My Complaints', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintsScreen()))),
            Divider(color: Theme.of(context).cardColor, indent: 60),
            _buildMenuOption(Icons.settings_outlined, 'Account Settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(title: 'Account Settings')))),
            Divider(color: Theme.of(context).cardColor, indent: 60),
            _buildMenuOption(Icons.notifications_outlined, 'Notification Settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(title: 'Notification Settings')))),
            Divider(color: Theme.of(context).cardColor, indent: 60),
            _buildMenuOption(Icons.shield_outlined, 'Identity Verification (KYC)', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()))),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}
