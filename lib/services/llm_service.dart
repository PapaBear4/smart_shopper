import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:smart_shopper/tools/logger.dart';

class LlmService {
  static const String _apiKeyEnvName = 'GEMINI_API_KEY';
  GenerativeModel? _model;

  LlmService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await dotenv.load(fileName: ".env");
    final apiKey = dotenv.env[_apiKeyEnvName];
    if (apiKey == null) {
      // Consider logging this error or informing the user more gracefully
      logError('API Key not found. Please set $_apiKeyEnvName in your .env file');
      return;
    }
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  Future<String?> parseShoppingListItem(String userInput) async {
    if (_model == null) {
      logError('LLM model is not initialized.');
      return null;
    }

    // This is a basic prompt. You'll need to refine this to get the desired JSON output structure.
    // Consider providing few-shot examples within the prompt for better results.
    final prompt = '''Parse the following user input for a shopping list item.
    Identify the item name, an item category, a typical unit of measure, the quantity 
    to purchase, and any desired attributes (like brand, flavor, organic, gluten-free, 2-pack, etc.).
    If the unit or quantity is not specified, use a typical value or omit them.
    If you cannot parse what the user wants, return the user input as is under the name field.
    Return the information in a JSON format like: {
      "name": "item", 
      "category": "category", 
      "unit": "unit", 
      "quantity": number, 
      "desiredAttributes": "attribute1, attribute2, attribute3"
    }.
    User input: "$userInput"''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text;
    } catch (e) {
      // Consider more robust error handling
      logError('Error communicating with the LLM: $e');
      return null;
    }
  }

  // Placeholder for a method to switch LLM providers in the future
  Future<void> switchLlmProvider(String providerName, {String? newApiKey}) async {
    // This is a simplified example. In a real scenario, you might have different
    // initialization logic and SDKs for different providers.
    logInfo("Switching LLM provider to: $providerName");
    if (providerName.toLowerCase() == 'gemini') {
      final apiKey = newApiKey ?? dotenv.env[_apiKeyEnvName];
      if (apiKey == null) {
        logError('API Key for Gemini not found.');
        return;
      }
      _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
      logInfo("Switched to Gemini.");
    } else {
      logError("Provider $providerName is not supported yet.");
      _model = null; // Or initialize a default/fallback if any
    }
  }
}

// Example of how you might structure the expected output from the LLM
class ParsedShoppingItem {
  final String name;
  final String? category; // Made nullable
  final String? unit; // Made nullable
  final double? quantity; // Made nullable
  final List<String>? desiredAttributes; // New field

  ParsedShoppingItem({
    required this.name, 
    this.category, 
    this.unit, 
    this.quantity, 
    this.desiredAttributes, // Added to constructor
  });

  factory ParsedShoppingItem.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse a number that might be int or double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    List<String>? parseAttributes(dynamic attributesValue) {
      if (attributesValue == null) return null;
      if (attributesValue is String) {
        if (attributesValue.isEmpty) return null;
        return attributesValue.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      if (attributesValue is List) {
        return attributesValue.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      return null;
    }

    return ParsedShoppingItem(
      name: json['name'] as String, // Assuming name is always present as per prompt
      category: json['category'] as String?,
      unit: json['unit'] as String?,
      quantity: parseDouble(json['quantity']),
      desiredAttributes: parseAttributes(json['desiredAttributes']), // Parse new field
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'unit': unit,
        'quantity': quantity,
        'desiredAttributes': desiredAttributes?.join(', '), // Convert list to comma-separated string for JSON
      };
}
