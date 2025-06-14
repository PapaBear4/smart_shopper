import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanListPage extends StatefulWidget {
  const ScanListPage({super.key});

  static const String routeName = '/scan-list';

  @override
  State<ScanListPage> createState() => _ScanListPageState();
}

class _ScanListPageState extends State<ScanListPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        // TODO: Navigate to review screen or start processing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selected: ${pickedFile.path}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (e) {
      // TODO: Handle exceptions more gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan New List'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_selectedImage != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.file(_selectedImage!),
                ),
              )
            else
              const Text('No image selected.'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from Gallery'),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 20),
            // TODO: Add instructional message for taking good photos
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Tip: Ensure good lighting, lay the list flat, and hold the camera steady for best results.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
