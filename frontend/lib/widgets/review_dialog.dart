import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ReviewDialog extends StatefulWidget {
  final String propertyId;

  const ReviewDialog({Key? key, required this.propertyId}) : super(key: key);

  @override
  _ReviewDialogState createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _base64Images = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(limit: 3);
    for (var file in pickedFiles) {
      if (_base64Images.length >= 3) break;
      final bytes = await file.readAsBytes();
      final base64String = "data:${file.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}";
      setState(() {
        _base64Images.add(base64String);
      });
    }
  }

  void _submit() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a review')));
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.post('/properties/${widget.propertyId}/reviews', {
      'rating': _rating,
      'review': _commentController.text,
      'images': _base64Images,
    });

    setState(() => _isLoading = false);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Submitted!')));
      Navigator.pop(context, true);
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Write a Review', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Rating: '),
                ...List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ],
            ),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Comment', hintText: 'Share details of your experience...'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _base64Images.isEmpty
                    ? const Center(child: Text('+ Add Photos (max 3)', style: TextStyle(color: AppTheme.accentColor)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _base64Images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(base64Decode(_base64Images[index].split(',').last), width: 80, height: 80, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
