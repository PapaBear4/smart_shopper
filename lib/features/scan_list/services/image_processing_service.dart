import 'dart:convert';
// import 'dart:io'; // Unused import
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // To use XFile
import 'package:flutter/foundation.dart'; // For debugPrint

class ImageProcessingService {
  final String _googleCloudVisionApiKey;
  static const double _wordConfidenceThreshold = 0.75; // Configurable threshold

  ImageProcessingService() : _googleCloudVisionApiKey = dotenv.env['GOOGLE_CLOUD_VISION_API_KEY'] ?? '' {
    if (_googleCloudVisionApiKey.isEmpty) {
      throw Exception('GOOGLE_CLOUD_VISION_API_KEY not found in .env file');
    }
  }

  Future<String> processImageForText(XFile imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final requestBody = jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {
                'type': 'DOCUMENT_TEXT_DETECTION',
                // 'maxResults': 1, // Not needed when parsing structure
              }
            ],
          }
        ]
      });

      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_googleCloudVisionApiKey'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        // debugPrint('Google Vision API Raw Response: ${response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length)}'); // For extensive debugging

        if (responseJson['responses'] != null &&
            responseJson['responses'].isNotEmpty) {
          final firstResponse = responseJson['responses'][0];
          if (firstResponse['error'] != null) {
            final error = firstResponse['error'];
            throw Exception('Google Vision API Error: ${error['message']} (Code: ${error['code']})');
          }
          if (firstResponse['fullTextAnnotation'] != null) {
            return _extractTextFromAnnotation(firstResponse['fullTextAnnotation']);
          } else {
            return ''; // No text annotation found
          }
        } else {
          return ''; // Empty or unexpected response structure
        }
      } else {
        // debugPrint('Google Vision API Error Response: ${response.body}');
        throw Exception(
            'Failed to call Google Vision API. Status code: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      // debugPrint('Error in processImageForText: $e');
      rethrow;
    }
  }

  String _extractTextFromAnnotation(Map<String, dynamic> annotation) {
    StringBuffer textBuffer = StringBuffer();
    final pages = annotation['pages'] as List<dynamic>?;

    if (pages != null) {
      for (var page in pages) {
        final blocks = page['blocks'] as List<dynamic>?;
        if (blocks != null) {
          for (var block in blocks) {
            final paragraphs = block['paragraphs'] as List<dynamic>?;
            if (paragraphs != null) {
              for (var paragraph in paragraphs) {
                final words = paragraph['words'] as List<dynamic>?;
                if (words != null) {
                  for (var wordData in words) {
                    final wordConfidence = wordData['confidence'] as double?;
                    String currentWordText = '';
                    final symbols = wordData['symbols'] as List<dynamic>?;
                    if (symbols != null) {
                       for (var symbolData in symbols) {
                         currentWordText += (symbolData['text'] as String? ?? '');
                       }
                    }

                    if (wordConfidence != null && wordConfidence >= _wordConfidenceThreshold && currentWordText.isNotEmpty) {
                      textBuffer.write(currentWordText);
                      // Handle breaks after words
                      final property = wordData['property'] as Map<String, dynamic>?;
                      if (property != null) {
                        final detectedBreak = property['detectedBreak'] as Map<String, dynamic>?;
                        if (detectedBreak != null) {
                          final breakType = detectedBreak['type'] as String?;
                          switch (breakType) {
                            case 'SPACE':
                            case 'SURE_SPACE':
                              textBuffer.write(' ');
                              break;
                            case 'EOL_SURE_SPACE':
                              textBuffer.write(' '); // Treat as space, new line handled by paragraph/block
                              break;
                            case 'LINE_BREAK':
                              textBuffer.write('\n');
                              break;
                            default:
                              // If no explicit break, but it's the end of a word, assume a space if not followed by punctuation.
                              // This might need more sophisticated logic based on symbol types.
                              // For now, relying on explicit break types.
                              break;
                          }
                        } else {
                           // If no detectedBreak, assume a space after a word if it's not the last word in a paragraph.
                           // This is a simplification. True line reconstruction is complex.
                           // We will rely on LINE_BREAK for newlines primarily.
                           textBuffer.write(' '); // Default to space if no break info, might over-space.
                        }
                      } else {
                        textBuffer.write(' '); // Default to space if no property info
                      }
                    }
                  } // end word loop
                }
                // textBuffer.write('\n'); // Add newline after each paragraph (might be too much if words already have line breaks)
              } // end paragraph loop
            }
             textBuffer.write('\n'); // Add newline after each block
          } // end block loop
        }
      } // end page loop
    }
    // Trim trailing newlines and spaces that might accumulate
    return textBuffer.toString().trim();
  }
}
