import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/property_model.dart';
import '../theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
class AddPropertyScreen extends StatefulWidget {
  final Property? property;

  const AddPropertyScreen({Key? key, this.property}) : super(key: key);

  @override
  _AddPropertyScreenState createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '', description = '', location = '';
  double price = 0;
  String propertyType = 'PG';
  int beds = 1;
  bool _isLoading = false;
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  final List<String> propertyTypes = ['PG', 'Room', 'Lodge', 'Shared Stay', 'Traveling Stay', 'Restaurant'];
  
  // States for facilities
  bool hasWifi = false;
  bool hasWater = false;
  bool hasMeals = false;
  bool hasLightBillInclude = false;
  bool hasAC = false;
  bool hasWashroom = false;
  bool hasWashingMachine = false;
  bool hasParking = false;
  bool hasGallery = false;

  final ImagePicker _picker = ImagePicker();
  List<String> _base64Images = [];

  // Offer State
  double discountPercentage = 0;
  DateTime? offerStartDate;
  DateTime? offerEndDate;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      title = widget.property!.title;
      description = widget.property!.description;
      location = widget.property!.location;
      price = widget.property!.price;
      propertyType = widget.property!.propertyType;
      beds = widget.property!.availableBeds;
      _base64Images = List.from(widget.property!.images);
      
      hasWifi = widget.property!.facilities.contains('Wi-Fi');
      hasWater = widget.property!.facilities.contains('Water');
      hasMeals = widget.property!.facilities.contains('Meals');
      hasLightBillInclude = widget.property!.facilities.contains('Light Bill Incl.');
      hasAC = widget.property!.facilities.contains('AC');
      hasWashroom = widget.property!.facilities.contains('Washroom');
      hasWashingMachine = widget.property!.facilities.contains('Washing Machine');
      hasParking = widget.property!.facilities.contains('Parking');
      hasGallery = widget.property!.facilities.contains('Gallery');
      
      if (widget.property!.lat != 0.0 || widget.property!.lng != 0.0) {
        _selectedLocation = LatLng(widget.property!.lat, widget.property!.lng);
      }
      
      if (widget.property!.offer != null) {
        discountPercentage = widget.property!.offer!.discountPercentage;
        if (widget.property!.offer!.startDate != null) {
          offerStartDate = DateTime.tryParse(widget.property!.offer!.startDate!);
        }
        if (widget.property!.offer!.endDate != null) {
          offerEndDate = DateTime.tryParse(widget.property!.offer!.endDate!);
        }
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 50, limit: 5);
    for (var file in pickedFiles) {
      if (_base64Images.length >= 5) break; 
      final bytes = await file.readAsBytes();
      final base64String = "data:${file.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}";
      setState(() {
        _base64Images.add(base64String);
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      
      List<String> activeFacilities = [];
      if (hasWifi) activeFacilities.add('Wi-Fi');
      if (hasWater) activeFacilities.add('Water');
      if (hasMeals) activeFacilities.add('Meals');
      if (hasLightBillInclude) activeFacilities.add('Light Bill Incl.');
      if (hasAC) activeFacilities.add('AC');
      if (hasWashroom) activeFacilities.add('Washroom');
      if (hasWashingMachine) activeFacilities.add('Washing Machine');
      if (hasParking) activeFacilities.add('Parking');
      if (hasGallery) activeFacilities.add('Gallery');

      final payload = {
        'title': title,
        'description': description,
        'location': location,
        'price': price,
        'propertyType': propertyType,
        'availableBeds': beds,
        'facilities': activeFacilities,
        'images': _base64Images.isNotEmpty ? _base64Images : ['https://via.placeholder.com/400x200.png?text=Property+Photo'],
        'lat': _selectedLocation?.latitude ?? 18.5204,
        'lng': _selectedLocation?.longitude ?? 73.8567,
        'offer': {
          'discountPercentage': discountPercentage,
          'startDate': offerStartDate?.toIso8601String(),
          'endDate': offerEndDate?.toIso8601String(),
        }
      };

      final response = widget.property == null 
          ? await ApiService.post('/properties', payload)
          : await ApiService.put('/properties/${widget.property!.id}', payload);

      setState(() => _isLoading = false);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        _showPopup('Success', widget.property == null ? 'Property Added Successfully!' : 'Property Updated Successfully!');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        _showPopup('Error', 'Failed to save property: ${response.body}');
      }
    }
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: title == 'Success' ? Colors.green : Colors.red)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
        ],
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    try {
      final response = await ApiService.getRaw('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        if (mounted) {
          setState(() {
            _selectedLocation = LatLng(lat, lon);
            _mapController.move(_selectedLocation!, 15.0);
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }
  }

  List<String> _getActiveFacilities() {
    List<String> active = [];
    if (hasWifi) active.add('Wi-Fi');
    if (hasWater) active.add('Water');
    if (hasMeals) active.add('Meals');
    if (hasLightBillInclude) active.add('Light Bill Incl.');
    if (hasAC) active.add('AC');
    if (hasWashroom) active.add('Washroom');
    if (hasWashingMachine) active.add('Washing Machine');
    if (hasParking) active.add('Parking');
    if (hasGallery) active.add('Gallery');
    return active;
  }

  void _showFacilitiesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Facilities'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDialogCheckbox('Wi-Fi', hasWifi, (v) { setState(() => hasWifi = v!); setDialogState(() {}); }),
                    _buildDialogCheckbox('Water', hasWater, (v) { setState(() => hasWater = v!); setDialogState(() {}); }),
                    _buildDialogCheckbox('Meals', hasMeals, (v) { setState(() => hasMeals = v!); setDialogState(() {}); }),
                    _buildDialogCheckbox('Light Bill Incl.', hasLightBillInclude, (v) { setState(() => hasLightBillInclude = v!); setDialogState(() {}); }),
                    _buildDialogCheckbox('AC', hasAC, (v) { setState(() => hasAC = v!); setDialogState(() {}); }),
                    _buildDialogCheckbox('Washroom', hasWashroom, (v) { setState(() => hasWashroom = v!); setDialogState(() {}); }),
                    _buildDialogCheckbox('Washing Machine', hasWashingMachine, (v) { setState(() => hasWashingMachine = v!); setDialogState(() {}); }),
                    _buildDialogCheckbox('Parking', hasParking, (v) { setState(() => hasParking = v!); setDialogState(() {}); }),
                    _buildDialogCheckbox('Gallery', hasGallery, (v) { setState(() => hasGallery = v!); setDialogState(() {}); }),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogCheckbox(String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.property == null ? 'Post New Property' : 'Edit Property')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: title,
                    decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
                    onSaved: (v) => title = v!,
                    validator: (v) => v!.isEmpty ? 'Enter property title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
                    maxLines: 3,
                    onSaved: (v) => description = v!,
                    validator: (v) => v!.isEmpty ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: location,
                    decoration: const InputDecoration(labelText: 'Location Text (City/Area)', prefixIcon: Icon(Icons.location_on)),
                    onSaved: (v) => location = v!,
                    validator: (v) => v!.isEmpty ? 'Enter location' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Pin Location on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => location = val,
                          decoration: const InputDecoration(
                            hintText: 'Search city/area to pin...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: (val) => _searchLocation(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () => _searchLocation(location),
                        icon: const Icon(Icons.location_searching),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation ?? const LatLng(18.5204, 73.8567), // Default Pune
                        initialZoom: 12.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _selectedLocation = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (_selectedLocation == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Please tap on the map to pin property location.', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: price == 0 ? '' : price.toString(),
                          decoration: const InputDecoration(labelText: 'Price (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => price = double.tryParse(v!) ?? 0,
                          validator: (v) => v!.isEmpty ? 'Enter price' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: propertyType,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category)),
                          items: propertyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => propertyType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: beds.toString(),
                    decoration: InputDecoration(
                      labelText: propertyType == 'Restaurant' ? 'Available Tables' : 'Available Beds/Units',
                      prefixIcon: Icon(propertyType == 'Restaurant' ? Icons.restaurant : Icons.bed),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => beds = int.tryParse(v!) ?? 1,
                    validator: (v) => v!.isEmpty ? 'Enter count' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Facilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showFacilitiesDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.cardColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getActiveFacilities().isEmpty ? 'Select Facilities' : _getActiveFacilities().join(', '),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _getActiveFacilities().isEmpty ? Colors.grey : Colors.black),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Special Offers (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.orange.shade50,
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: discountPercentage == 0 ? '' : discountPercentage.toString(),
                          decoration: const InputDecoration(labelText: 'Discount Percentage (%)', prefixIcon: Icon(Icons.local_offer)),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => discountPercentage = double.tryParse(v ?? '') ?? 0,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(context: context, initialDate: offerStartDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                                  if (date != null) setState(() => offerStartDate = date);
                                },
                                icon: const Icon(Icons.calendar_today),
                                label: Text(offerStartDate != null ? "${offerStartDate!.day}/${offerStartDate!.month}/${offerStartDate!.year}" : 'Start Date'),
                              ),
                            ),
                            const Text('to'),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(context: context, initialDate: offerEndDate ?? (offerStartDate ?? DateTime.now()), firstDate: offerStartDate ?? DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                                  if (date != null) setState(() => offerEndDate = date);
                                },
                                icon: const Icon(Icons.calendar_today),
                                label: Text(offerEndDate != null ? "${offerEndDate!.day}/${offerEndDate!.month}/${offerEndDate!.year}" : 'End Date'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Property Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  // Image Uploader UI
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _base64Images.isEmpty 
                      ? InkWell(
                          onTap: _pickImages,
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 48, color: AppTheme.primaryColor),
                                SizedBox(height: 12),
                                Text('Upload Property Photos (Max 5)', style: TextStyle(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                                Text('Tap to select images', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(12),
                                itemCount: _base64Images.length + (_base64Images.length < 5 ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _base64Images.length) {
                                    return GestureDetector(
                                      onTap: _pickImages,
                                      child: Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
                                        ),
                                        child: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryColor, size: 32),
                                      ),
                                    );
                                  }

                                  final imgSource = _base64Images[index];
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: imgSource.startsWith('http')
                                              ? Image.network(imgSource, width: 120, height: 120, fit: BoxFit.cover)
                                              : Image.memory(base64Decode(imgSource.split(',').last), width: 120, height: 120, fit: BoxFit.cover),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 16,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _base64Images.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(widget.property == null ? 'POST PROPERTY' : 'UPDATE PROPERTY'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

}
