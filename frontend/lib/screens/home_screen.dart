import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/property_model.dart';
import '../widgets/property_card.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'PG',
    'Room',
    'Lodge',
    'Shared Stay',
    'Traveling Stay',
    'Restaurant'
  ];

  List<Property> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    try {
      final response = await ApiService.get('/properties');
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

  @override
  Widget build(BuildContext context) {
    List<Property> filteredProperties = _selectedFilter == 'All'
        ? _properties
        : _properties.where((p) => p.propertyType == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NearNest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.textPrimaryColor),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline, color: AppTheme.textPrimaryColor),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                );
              } else if (value == 'logout') {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('My Profile'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search locations or properties...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryColor),
                suffixIcon: const Icon(Icons.tune, color: AppTheme.accentColor),
              ),
            ),
            const SizedBox(height: 20),
            // Welcome text
            Text(
              'Find your ideal stay',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  bool isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.accentColor,
                      backgroundColor: AppTheme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppTheme.accentColor : Colors.transparent,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Listings
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : filteredProperties.isEmpty
                    ? const Center(child: Text('No properties found!'))
                    : ListView.builder(
                        itemCount: filteredProperties.length,
                        itemBuilder: (context, index) {
                          return PropertyCard(property: filteredProperties[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
