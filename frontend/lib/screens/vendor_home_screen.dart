import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../models/property_model.dart';
import '../widgets/property_card.dart';
import '../services/api_service.dart';
import 'add_property_screen.dart';
import 'chats_list_screen.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({Key? key}) : super(key: key);

  @override
  _VendorHomeScreenState createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const VendorDashboardView(),
    const VendorPropertiesView(),
    const VendorBookingsView(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        backgroundColor: AppTheme.cardColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.home_work), label: 'Properties'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------------- DASHBOARD VIEW ----------------
class VendorDashboardView extends StatefulWidget {
  const VendorDashboardView({Key? key}) : super(key: key);

  @override
  _VendorDashboardViewState createState() => _VendorDashboardViewState();
}

class _VendorDashboardViewState extends State<VendorDashboardView> {
  int _activeListings = 0;
  int _totalBookings = 0;
  double _totalEarnings = 0;
  int _pendingBookings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final vendorId = authProvider.user?['_id'];
    if (vendorId == null) return;
    
    try {
      final propertiesRes = await ApiService.get('/properties?vendor=$vendorId');
      if (propertiesRes.statusCode == 200) {
        final List<dynamic> data = jsonDecode(propertiesRes.body);
        _activeListings = data.length;
      }
      
      final bookingsRes = await ApiService.get('/bookings/vendor');
      if (bookingsRes.statusCode == 200) {
        final List<dynamic> bData = jsonDecode(bookingsRes.body);
        int total = 0;
        double earnings = 0;
        int pending = 0;
        for (var b in bData) {
          if (b['status'] == 'accepted') {
            total++;
            earnings += (b['totalPrice'] ?? 0).toDouble();
          } else if (b['status'] == 'pending') {
            pending++;
          }
        }
        _totalBookings = total;
        _totalEarnings = earnings;
        _pendingBookings = pending;
      }
      setState(() {});
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final vendorName = authProvider.user?['name'] ?? 'Vendor';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Vendor Dashboard'),
          floating: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatsListScreen()));
              },
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Welcome back, $vendorName!', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              // Analytics Cards
              Row(
                children: [
                  Expanded(child: _buildMetricCard(context, 'Active Listings', _isLoading ? '-' : '$_activeListings', Icons.home_work, AppTheme.primaryColor)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard(context, 'Total Bookings', _isLoading ? '-' : '$_totalBookings', Icons.check_circle, AppTheme.accentColor)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMetricCard(context, 'Total Earnings', _isLoading ? '-' : '₹$_totalEarnings', Icons.currency_rupee, Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard(context, 'Pending Requests', _isLoading ? '-' : '$_pendingBookings', Icons.pending_actions, AppTheme.secondaryColor)),
                ],
              ),
              const SizedBox(height: 30),
              Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              const Padding(padding: EdgeInsets.all(16), child: Text("No recent activity.", style: TextStyle(color: AppTheme.textSecondaryColor))),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24, color: color)),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(String title, String subtitle, String time, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: AppTheme.cardColor, child: Icon(icon, color: AppTheme.accentColor)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondaryColor)),
        trailing: Text(time, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
      ),
    );
  }
}

// ---------------- PROPERTIES VIEW ----------------
class VendorPropertiesView extends StatefulWidget {
  const VendorPropertiesView({Key? key}) : super(key: key);

  @override
  _VendorPropertiesViewState createState() => _VendorPropertiesViewState();
}

class _VendorPropertiesViewState extends State<VendorPropertiesView> {
  List<Property> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final vendorId = authProvider.user?['_id'];
    if (vendorId == null) return;
    
    try {
      final response = await ApiService.get('/properties?vendor=$vendorId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _properties = data.map((json) {
            return Property.fromJson(json);
          }).toList();
        });
      }
    } catch (e) {
      // Ignored for UI
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProperty(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text('Are you sure you want to delete this property? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final response = await ApiService.delete('/properties/$id');
      if (response.statusCode == 200) {
        _fetchProperties();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property deleted')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete property')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Properties')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? const Center(child: Text('You have no properties listed. Click Add to start!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final property = _properties[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PropertyCard(property: property),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyScreen(property: property)));
                                if (result == true) _fetchProperties();
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                            ),
                            TextButton.icon(
                              onPressed: () => _deleteProperty(property.id),
                              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                              label: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        const Divider(thickness: 2),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
          if (result == true) {
            _fetchProperties(); // Refresh properties after add
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Property'),
      ),
    );
  }
}

// ---------------- BOOKINGS VIEW ----------------
class VendorBookingsView extends StatefulWidget {
  const VendorBookingsView({Key? key}) : super(key: key);

  @override
  _VendorBookingsViewState createState() => _VendorBookingsViewState();
}

class _VendorBookingsViewState extends State<VendorBookingsView> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final response = await ApiService.get('/bookings/vendor');
      if (response.statusCode == 200) {
        setState(() {
          _bookings = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // Ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String bookingId, String status) async {
    final response = await ApiService.put('/bookings/$bookingId/status', {'status': status});
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking $status!')));
      _fetchBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Requests')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _bookings.isEmpty 
          ? const Center(child: Text('No incoming booking requests yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                final propTitle = booking['property']?['title'] ?? 'Unknown Property';
                final userName = booking['user']?['name'] ?? 'Unknown User';
                final userEmail = booking['user']?['email'] ?? 'No email provided';
                final status = booking['status'] ?? 'pending';
                final price = booking['totalPrice'] ?? 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(propTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'accepted' ? Colors.green.withOpacity(0.1) : status == 'rejected' ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)
                              ),
                              child: Text(
                                status.toUpperCase(), 
                                style: TextStyle(color: status == 'accepted' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)
                              ),
                            )
                          ],
                        ),
                        const Divider(height: 24),
                        // User Profile Section
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primaryColor,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor)),
                                  Text(userEmail, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.accentColor),
                              tooltip: 'Chat with User',
                              onPressed: () {
                                if (booking['user'] != null && booking['user']['_id'] != null) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                                    otherUserId: booking['user']['_id'],
                                    otherUserName: userName,
                                  )));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User details unavailable')));
                                }
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Booking Value:', style: TextStyle(color: AppTheme.textSecondaryColor)),
                            Text('₹$price', style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (status == 'pending') Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                              onPressed: () => _updateStatus(booking['_id'], 'rejected'),
                              child: const Text('REJECT'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () => _updateStatus(booking['_id'], 'accepted'),
                              child: const Text('ACCEPT'),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                );
              },
            ),
    );
  }
}

// ---------------- PROFILE VIEW ----------------
class VendorProfileView extends StatelessWidget {
  const VendorProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          Center(
            child: Text(authProvider.user?['name'] ?? 'Vendor Name', 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))
          ),
          Center(child: Text(authProvider.user?['email'] ?? 'vendor@example.com', style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.currency_rupee, color: Colors.green),
            title: const Text('Earnings & Payments'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.report, color: Colors.red),
            title: const Text('Raise Complaint'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text('Logout'),
            onTap: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
