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
  List<String>? _parsedListItems; // Changed from _extractedText
  String? _errorMessage;

  Future<void> _pickAndProcessImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _selectedXFile = null;
      _selectedImageFile = null;
      _parsedListItems = null; // Clear previous list items
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
        
        final String rawExtractedText = await _imageProcessingService.processImageForText(pickedFile);
        
        if (rawExtractedText.isNotEmpty) {
          final List<String> lines = rawExtractedText.split('\n');
          final List<String> processedItems = lines
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();
          
          setState(() {
            _parsedListItems = processedItems.isNotEmpty ? processedItems : ["No list items found after parsing."];
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(processedItems.isNotEmpty ? "Text processed." : "No text found after parsing.")),
          );
        } else {
          setState(() {
            _parsedListItems = ["No text detected in the image."];
            _isLoading = false;
          });
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No text detected in the image.")),
          );
        }

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
      body: SingleChildScrollView(
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: Image.file(_selectedImageFile!),
                  ),
                ),
              // Display Parsed List Items
              if (_parsedListItems != null && _parsedListItems!.isNotEmpty && !_isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detected Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true, // Important for ListView inside Column
                          physics: const NeverScrollableScrollPhysics(), // If inside SingleChildScrollView
                          itemCount: _parsedListItems!.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              dense: true,
                              title: Text(_parsedListItems![index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
               if (_parsedListItems != null && _parsedListItems!.isEmpty && !_isLoading) // Case where parsing results in empty list but no error
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No list items found after parsing the image.',
                     textAlign: TextAlign.center,
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
                      'Tip: Ensure good lighting, lay the list flat, and hold the camera steady for best results. Place on a dark background if possible to avoid text from the other side showing through.',
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
