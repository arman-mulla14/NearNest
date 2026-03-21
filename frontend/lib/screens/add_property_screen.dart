import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/property_model.dart';
import '../theme/app_theme.dart';
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

  final List<String> propertyTypes = ['PG', 'Room', 'Lodge', 'Shared Stay', 'Traveling Stay', 'Restaurant'];
  
  // Example states for facilities
  bool hasWifi = false;
  bool hasWater = false;
  bool hasMeals = false;

  final ImagePicker _picker = ImagePicker();
  List<String> _base64Images = [];

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
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(limit: 5);
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

      final payload = {
        'title': title,
        'description': description,
        'location': location,
        'price': price,
        'propertyType': propertyType,
        'availableBeds': beds,
        'facilities': activeFacilities,
        'images': _base64Images.isNotEmpty ? _base64Images : ['https://via.placeholder.com/400x200.png?text=Property+Photo'],
      };

      final response = widget.property == null 
          ? await ApiService.post('/properties', payload)
          : await ApiService.put('/properties/${widget.property!.id}', payload);

      setState(() => _isLoading = false);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.property == null ? 'Property Added Successfully!' : 'Property Updated!')));
        Navigator.pop(context, true); // true indicates a refresh is needed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
      }
    }
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
                    decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                    onSaved: (v) => location = v!,
                    validator: (v) => v!.isEmpty ? 'Enter location' : null,
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
                    decoration: const InputDecoration(labelText: 'Available Beds/Units', prefixIcon: Icon(Icons.bed)),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => beds = int.tryParse(v!) ?? 1,
                    validator: (v) => v!.isEmpty ? 'Enter count' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Facilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Checkbox(value: hasWifi, onChanged: (v) => setState(() => hasWifi = v!)),
                      const Text('Wi-Fi'),
                      Checkbox(value: hasWater, onChanged: (v) => setState(() => hasWater = v!)),
                      const Text('24/7 Water'),
                      Checkbox(value: hasMeals, onChanged: (v) => setState(() => hasMeals = v!)),
                      const Text('Meals'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Image Uploader UI
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
                      ),
                      child: _base64Images.isEmpty 
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload, size: 40, color: AppTheme.accentColor),
                                SizedBox(height: 8),
                                Text('Upload Photos/Videos (Max 5)', style: TextStyle(color: AppTheme.textSecondaryColor)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _base64Images.length,
                            itemBuilder: (context, index) {
                              final imgSource = _base64Images[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imgSource.startsWith('http')
                                      ? Image.network(imgSource, width: 120, height: 120, fit: BoxFit.cover)
                                      : Image.memory(base64Decode(imgSource.split(',').last), width: 120, height: 120, fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
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
