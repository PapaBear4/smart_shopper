import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart'; // Removed
import 'package:smart_shopper/features/extended_image_utils/screens/extended_image_cropper_screen.dart'; 
import 'package:smart_shopper/features/scan_list/services/image_processing_service.dart';
import 'package:smart_shopper/service_locator.dart';
import 'dart:developer' as developer; 

class ScanListPage extends StatefulWidget {
  const ScanListPage({super.key});

  static const String routeName = '/scan-list';

  @override
  State<ScanListPage> createState() => _ScanListPageState();
}

class _ScanListPageState extends State<ScanListPage> {
  XFile? _processedXFile; // This will hold the file to be sent to OCR (potentially cropped)
  File? _displayImageFile; // This will hold the file for UI display (potentially cropped)

  final ImagePicker _picker = ImagePicker();
  // final ImageCropper _cropper = ImageCropper(); // Removed
  final ImageProcessingService _imageProcessingService = getIt<ImageProcessingService>();

  bool _isLoading = false;
  List<String>? _parsedListItems;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    developer.log('ScanListPage: initState', name: 'ScanListPage');
  }

  // Future<CroppedFile?> _cropImage(String sourcePath) async {
  //   return await _cropper.cropImage(
  //     sourcePath: sourcePath,
  //     compressFormat: ImageCompressFormat.jpg, // Or png
  //     compressQuality: 90, // Adjust quality as needed
  //     uiSettings: [
  //       AndroidUiSettings(
  //         toolbarTitle: 'Crop Image',
  //         toolbarColor: Colors.grey[900], // Use a very dark toolbar
  //         toolbarWidgetColor: Colors.white, // White icons and text on the toolbar
  //         initAspectRatio: CropAspectRatioPreset.original,
  //         lockAspectRatio: false,
  //         // All other color/UI properties are reset to default by not specifying them
  //       ),
  //       IOSUiSettings(
  //         title: 'Crop Image',
  //         aspectRatioPickerButtonHidden: false,
  //         resetAspectRatioEnabled: true,
  //         aspectRatioLockEnabled: false,
  //       ),
  //     ],
  //   );
  // }

  Future<File?> _navigateToExtendedCropper(XFile imageFile) async {
    developer.log('ScanListPage: Navigating to ExtendedImageCropperScreen with ${imageFile.path}', name: 'ScanListPage');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExtendedImageCropperScreen(imageFile: imageFile),
      ),
    );
    developer.log('ScanListPage: Result from ExtendedImageCropperScreen: $result', name: 'ScanListPage');
    if (result is File) {
      return result;
    }
    return null;
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    developer.log('ScanListPage: _pickAndProcessImage started with source: $source', name: 'ScanListPage');
    setState(() {
      _isLoading = true;
      _processedXFile = null;
      _displayImageFile = null;
      _parsedListItems = null;
      _errorMessage = null;
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      developer.log('ScanListPage: Picked file: ${pickedFile?.path}', name: 'ScanListPage');

      if (pickedFile != null) {
        // Show a temporary display of the picked image before cropping
        setState(() {
          _displayImageFile = File(pickedFile.path); 
        });
        developer.log('ScanListPage: Displaying picked file: ${pickedFile.path}', name: 'ScanListPage');

        // Ask user to crop the image using ExtendedImageCropperScreen
        final File? croppedImageFile = await _navigateToExtendedCropper(pickedFile);
        developer.log('ScanListPage: Cropped file from navigator: ${croppedImageFile?.path}', name: 'ScanListPage');

        if (croppedImageFile != null) {
          _processedXFile = XFile(croppedImageFile.path);
          _displayImageFile = croppedImageFile; // Update display image to cropped one
          developer.log('ScanListPage: Set _processedXFile to ${croppedImageFile.path}', name: 'ScanListPage');
          setState(() {}); // Update UI to show cropped image before processing

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Processing cropped image: ${croppedImageFile.path.split('/').last}...')),
          );
          developer.log('ScanListPage: Processing cropped image: ${croppedImageFile.path}', name: 'ScanListPage');
          
          final String rawExtractedText = await _imageProcessingService.processImageForText(_processedXFile!);
          developer.log('ScanListPage: Raw extracted text length: ${rawExtractedText.length}', name: 'ScanListPage');
          
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
            developer.log('ScanListPage: No text detected in the image.', name: 'ScanListPage');
            setState(() {
              _parsedListItems = ["No text detected in the image."];
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No text detected in the image.")),
            );
          }
        } else {
          // User cancelled cropping or an error occurred in the cropper screen
          setState(() {
            _isLoading = false;
            // Keep the initially picked image displayed if cropping is cancelled, 
            // or clear it if you prefer _displayImageFile = null;
            _errorMessage = 'Image cropping cancelled or failed.';
          });
          developer.log('ScanListPage: Image cropping cancelled or failed.', name: 'ScanListPage');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image cropping cancelled or failed.')),
          );
        }
      } else {
        developer.log('ScanListPage: No image selected.', name: 'ScanListPage');
        setState(() {
          _errorMessage = 'No image selected.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (e, s) { // Added stack trace
      developer.log('ScanListPage: Error in _pickAndProcessImage: $e\\n$s', name: 'ScanListPage', error: e, stackTrace: s);
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('ScanListPage: build method called. _displayImageFile: ${_displayImageFile?.path}, _isLoading: $_isLoading', name: 'ScanListPage');
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
              if (_isLoading && _displayImageFile == null) // Show general loading if no image yet
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              // Display image (picked or cropped)
              if (_displayImageFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: Image.file(_displayImageFile!),
                  ),
                ),
              // Show loading indicator over the image if processing after cropping
              if (_isLoading && _displayImageFile != null)
                 const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
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
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
              if (_parsedListItems != null && _parsedListItems!.isEmpty && !_isLoading)
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
              if (!_isLoading)
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
                      'Tip: Ensure good lighting, lay the list flat, and hold the camera steady for best results. Place on a dark background if possible to avoid text from the other side showing through. Use the crop tool to select only the list area.',
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
