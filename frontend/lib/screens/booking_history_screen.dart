import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final endpoint = user?['role'] == 'Vendor' ? '/bookings/vendor' : '/bookings/user';
      final response = await ApiService.get(endpoint);
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(child: Text('No bookings found.', style: TextStyle(color: AppTheme.textSecondaryColor)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final propertyNode = booking['property'] ?? {};
                    final title = propertyNode['title'] ?? 'Unknown Property';
                    final price = booking['totalPrice'] ?? 0;
                    final status = booking['status'] ?? 'pending';
                    final checkIn = booking['checkInDate'] != null ? DateTime.parse(booking['checkInDate']).toLocal().toString().split(' ')[0] : 'N/A';
                    
                    return Card(
                      color: AppTheme.cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.book_online, color: AppTheme.accentColor, size: 36),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                        subtitle: Text('Check-in: $checkIn\nStatus: ${status.toUpperCase()}', style: const TextStyle(color: AppTheme.textSecondaryColor)),
                        trailing: Text('₹$price', style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    );
                  },
                ),
    );
  }
}
