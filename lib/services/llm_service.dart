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
    Identify the item name, an item category, a typical unit of measure, and the quantity to purchase.
    If the unit or quantity is not specified, use a typical value.  If you cannot
    parse what the user wants return the user input as is under the name field.
    Return the information in a JSON format like: {"name": "item", "category": "category", 
    "unit": "unit", "quantity": number}.
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

  ParsedShoppingItem({required this.name, this.category, this.unit, this.quantity});

  factory ParsedShoppingItem.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse a number that might be int or double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ParsedShoppingItem(
      name: json['name'] as String, // Assuming name is always present as per prompt
      category: json['category'] as String?, // Allow null if 'category' is missing or null
      unit: json['unit'] as String?, // Allow null if 'unit' is missing or null
      quantity: parseDouble(json['quantity']), // Allow null if 'quantity' is missing or not a number
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'unit': unit,
        'quantity': quantity,
      };
}
