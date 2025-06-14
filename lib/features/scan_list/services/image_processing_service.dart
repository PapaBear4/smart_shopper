import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // To use XFile

// TODO: Implement image processing service
// This service will handle communication with Google Cloud Vision API

class ImageProcessingService {
  final String _googleCloudVisionApiKey;

  ImageProcessingService() : _googleCloudVisionApiKey = dotenv.env['GOOGLE_CLOUD_VISION_API_KEY'] ?? '' {
    if (_googleCloudVisionApiKey.isEmpty) {
      // It's better to throw an error or handle this case explicitly
      // rather than letting the API call fail silently later.
      throw Exception('GOOGLE_CLOUD_VISION_API_KEY not found in .env file or is empty');
    }
  }

  Future<String> processImageForText(XFile imageFile) async {
    try {
      // 1. Read image bytes and convert to base64
      final imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // 2. Prepare the request body for Google Cloud Vision API
      final requestBody = jsonEncode({
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'DOCUMENT_TEXT_DETECTION', // More robust for dense text/handwriting
                'maxResults': 1, // We want the full text block
              }
            ],
            // Optional: Add imageContext for language hints if needed
            // 'imageContext': {
            //   'languageHints': ['en'] // Example: English
            // }
          }
        ]
      });

      // 3. Make the POST request
      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_googleCloudVisionApiKey'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: requestBody,
      );

      // 4. Handle the response
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        // print('Google Vision API Response: $responseJson'); // For debugging

        if (responseJson['responses'] != null &&
            responseJson['responses'].isNotEmpty &&
            responseJson['responses'][0]['fullTextAnnotation'] != null) {
          return responseJson['responses'][0]['fullTextAnnotation']['text'] ?? '';
        } else if (responseJson['responses'] != null &&
                   responseJson['responses'].isNotEmpty &&
                   responseJson['responses'][0]['error'] != null) {
          // Handle API-specific errors
          final error = responseJson['responses'][0]['error'];
          throw Exception('Google Vision API Error: ${error['message']} (Code: ${error['code']})');
        } else {
          // No text found or unexpected response structure
          return ''; // Or throw Exception('No text found or unexpected response format');
        }
      } else {
        // Handle HTTP errors
        // print('Google Vision API Error Response: ${response.body}'); // For debugging
        throw Exception(
            'Failed to call Google Vision API. Status code: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      // Rethrow the exception to be caught by the caller
      // print('Error in processImageForText: $e'); // For debugging
      rethrow;
    }
  }
}
