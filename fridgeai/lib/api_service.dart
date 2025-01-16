import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static Future<List<String>> analyzeImage(File imageFile) async {
    // Correct API endpoint for Groq
    const apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
    final apiKey = dotenv.env['GROQ_API_KEY'];

    if (apiKey == null) {
      throw Exception('GROQ_API_KEY not found in environment variables');
    }

    // Read the image file and encode it as base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Prepare the request payload
    final payload = {
      'model':
          'llama-3.2-11b-vision-preview', // Use the correct model name from Groq's documentation
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'List all the ingredients you can see in this image. Return only a comma-separated list of ingredient names, nothing else.'
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
            }
          ]
        }
      ],
      'max_tokens': 150, // Adjust as needed
    };

    // Make the API request
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    // Handle the response
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;

      // Clean up the response and split into a list
      return content
          .split(',')
          .map((ingredient) => ingredient.trim())
          .where((ingredient) => ingredient.isNotEmpty)
          .toList();
    } else {
      throw Exception('Failed to analyze image: ${response.body}');
    }
  }

  static Future<List<dynamic>> fetchRecipes(
    List<String> ingredients, {
    int minUsedIngredients = 2, // Default to 2, but can be adjusted
  }) async {
    const apiUrl = 'https://api.spoonacular.com/recipes/findByIngredients';
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];

    if (apiKey == null) {
      throw Exception('SPOONACULAR_API_KEY not found in environment variables');
    }

    final queryParams = {
      'ingredients': ingredients.join(','),
      'apiKey': apiKey,
      'number': '10', // Fetch up to 10 recipes
      'ranking': '2', // Rank by ingredient matches
      'ignorePantry': 'true', // Ignore pantry staples
      'limitLicense': 'false',
      'instructionsRequired': 'true',
    };

    final uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      // Filter recipes based on the minimum number of used ingredients
      return data
          .where(
              (recipe) => recipe['usedIngredientCount'] >= minUsedIngredients)
          .toList();
    } else {
      throw Exception('Failed to fetch recipes: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> fetchRecipeDetails(int recipeId) async {
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];

    if (apiKey == null) {
      throw Exception('SPOONACULAR_API_KEY not found in environment variables');
    }

    final queryParams = {
      'apiKey': apiKey,
      // Added parameters for additional information
      'includeNutrition': 'true',
      'addWinePairing': 'true',
      'includeTaste': 'true',
    };

    final uri =
        Uri.parse('https://api.spoonacular.com/recipes/$recipeId/information')
            .replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch recipe details: ${response.body}');
    }
  }

  // New method to get nutritional information
  static Future<Map<String, dynamic>> fetchNutritionalInfo(int recipeId) async {
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];

    if (apiKey == null) {
      throw Exception('SPOONACULAR_API_KEY not found in environment variables');
    }

    final uri = Uri.parse(
            'https://api.spoonacular.com/recipes/$recipeId/nutritionWidget.json')
        .replace(queryParameters: {'apiKey': apiKey});

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to fetch nutritional information: ${response.body}');
    }
  }
}
