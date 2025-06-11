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
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  }

  Future<String?> parseShoppingListItem(String userInput) async {
    if (_model == null) {
      logError('LLM model is not initialized.');
      return null;
    }

    // This is a basic prompt. You'll need to refine this to get the desired JSON output structure.
    // Consider providing few-shot examples within the prompt for better results.
    final prompt = '''Parse the following user input for a shopping list item.
    Identify the item name, a typical unit of measure, and a common quantity of purchase.
    Return the information in a JSON format like: {"name": "item", "unit": "unit", "quantity": number}.
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
  final String unit;
  final double quantity;

  ParsedShoppingItem({required this.name, required this.unit, required this.quantity});

  factory ParsedShoppingItem.fromJson(Map<String, dynamic> json) {
    return ParsedShoppingItem(
      name: json['name'] as String,
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'quantity': quantity,
      };
}
