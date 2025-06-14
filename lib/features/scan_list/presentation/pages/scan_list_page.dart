import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_shopper/features/scan_list/services/image_processing_service.dart';
import 'package:smart_shopper/service_locator.dart';

class ScanListPage extends StatefulWidget {
  const ScanListPage({super.key});

  static const String routeName = '/scan-list';

  @override
  State<ScanListPage> createState() => _ScanListPageState();
}

class _ScanListPageState extends State<ScanListPage> {
  XFile? _selectedXFile; // Store XFile to pass to service
  File? _selectedImageFile; // Store File for display

  final ImagePicker _picker = ImagePicker();
  final ImageProcessingService _imageProcessingService = getIt<ImageProcessingService>();

  bool _isLoading = false;
  String? _extractedText;
  String? _errorMessage;

  Future<void> _pickAndProcessImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _selectedXFile = null;
      _selectedImageFile = null;
      _extractedText = null;
      _errorMessage = null;
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        _selectedXFile = pickedFile;
        _selectedImageFile = File(pickedFile.path); // For display
        setState(() {}); // Update UI to show selected image

        // Show a snackbar that processing has started
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing image: ${pickedFile.name}...')),
        );
        
        final String result = await _imageProcessingService.processImageForText(pickedFile);
        setState(() {
          _extractedText = result.isNotEmpty ? result : "No text found in the image.";
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractedText!)),
        );
      } else {
        setState(() {
          _errorMessage = 'No image selected.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing image: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan New List'),
      ),
      body: SingleChildScrollView( // Added SingleChildScrollView for long text
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              if (_selectedImageFile != null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ConstrainedBox( // Limit image height
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: Image.file(_selectedImageFile!),
                  ),
                ),
              if (_extractedText != null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Extracted Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(_extractedText!),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!_isLoading) // Only show buttons when not loading
                Column(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      onPressed: () => _pickAndProcessImage(ImageSource.camera),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pick from Gallery'),
                      onPressed: () => _pickAndProcessImage(ImageSource.gallery),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tip: Ensure good lighting, lay the list flat, and hold the camera steady for best results.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
