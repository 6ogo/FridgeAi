import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ApiService {
  static const int maxIngredients = 20;
  static const int maxRecipes = 15;
  static const Duration cacheDuration = Duration(hours: 24);

  // API Endpoints
  static const String groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String spoonacularBaseUrl = 'https://api.spoonacular.com';

  // Cache instance
  static final DefaultCacheManager _cacheManager = DefaultCacheManager();

  // Error handling wrapper
  static Future<T> _handleApiError<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on http.ClientException catch (e) {
      // Handle network-related errors
      throw ApiException('Network error: ${e.message}');
    } on SocketException catch (e) {
      // Handle no internet connection
      throw ApiException('No internet connection: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> fetchNutritionalInfo(int recipeId) async {
    return _handleApiError(() async {
      final apiKey = dotenv.env['SPOONACULAR_API_KEY'];
      if (apiKey == null) {
        throw const ApiException('SPOONACULAR_API_KEY not found');
      }

      // Try to get cached data first
      final cacheKey = 'nutritional_info_$recipeId';
      final cachedData = await _cacheManager.getFileFromCache(cacheKey);
      if (cachedData != null) {
        final cachedContent = await cachedData.file.readAsString();
        return jsonDecode(cachedContent);
      }

      final queryParams = {
        'apiKey': apiKey,
        'includeNutrition': 'true',
      };

      final uri = Uri.parse(
              '$spoonacularBaseUrl/recipes/$recipeId/nutritionWidget.json')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Cache the response
        await _cacheManager.putFile(
          cacheKey,
          Uint8List.fromList(jsonEncode(data).codeUnits),
          maxAge: cacheDuration,
        );

        return data;
      } else {
        _handleHttpError(response);
        throw ApiException(
            'Failed to fetch nutritional info: ${response.body}');
      }
    });
  }

  static Future<List<String>> analyzeImage(File imageFile) async {
    return _handleApiError(() async {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null) throw const ApiException('GROQ_API_KEY not found');

      // Validate image size
      final imageSize = await imageFile.length();
      if (imageSize > 10 * 1024 * 1024) {
        // 10MB limit
        throw const ApiException(
            'Image size too large. Please use an image under 10MB.');
      }

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final payload = {
        'model': 'llama-3.2-11b-vision-preview',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'List up to $maxIngredients ingredients you can see in this image. '
                    'Return only a comma-separated list of ingredient names, nothing else. '
                    'Focus on main ingredients and exclude common pantry items.'
              },
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
              }
            ]
          }
        ],
        'max_tokens': 200,
        'temperature': 0.7,
      };

      final response = await http.post(
        Uri.parse(groqApiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        final ingredients = content
            .split(',')
            .map((ingredient) => ingredient.trim().toLowerCase())
            .where((ingredient) =>
                ingredient.isNotEmpty &&
                ingredient.length >= 2 &&
                !_commonPantryItems.contains(ingredient))
            .take(maxIngredients)
            .toList();

        if (ingredients.isEmpty) {
          throw const ApiException('No ingredients detected in the image');
        }

        return ingredients;
      } else {
        _handleHttpError(response);
        throw ApiException('Failed to analyze image: ${response.body}');
      }
    });
  }

  static Future<List<dynamic>> fetchRecipes(
    List<String> ingredients, {
    int minUsedIngredients = 2,
  }) async {
    return _handleApiError(() async {
      final apiKey = dotenv.env['SPOONACULAR_API_KEY'];
      if (apiKey == null) {
        throw const ApiException('SPOONACULAR_API_KEY not found');
      }

      // Create cache key based on ingredients and filters
      final cacheKey = 'recipes_${ingredients.join('_')}_$minUsedIngredients';

      // Try to get cached data first
      final cachedData = await _cacheManager.getFileFromCache(cacheKey);
      if (cachedData != null) {
        final cachedContent = await cachedData.file.readAsString();
        return jsonDecode(cachedContent);
      }

      final queryParams = {
        'ingredients': ingredients.join(','),
        'apiKey': apiKey,
        'number': maxRecipes.toString(),
        'ranking': '2',
        'ignorePantry': 'true',
        'limitLicense': 'false',
        'instructionsRequired': 'true',
      };

      final uri = Uri.parse('$spoonacularBaseUrl/recipes/findByIngredients')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final filteredData = data
            .where(
                (recipe) => recipe['usedIngredientCount'] >= minUsedIngredients)
            .toList();

        // Cache the filtered results
        await _cacheManager.putFile(
          cacheKey,
          Uint8List.fromList(jsonEncode(filteredData).codeUnits),
          maxAge: cacheDuration,
        );

        return filteredData;
      } else {
        _handleHttpError(response);
        throw ApiException('Failed to fetch recipes: ${response.body}');
      }
    });
  }

  static Future<Map<String, dynamic>> fetchRecipeDetails(int recipeId) async {
    return _handleApiError(() async {
      final apiKey = dotenv.env['SPOONACULAR_API_KEY'];
      if (apiKey == null) {
        throw const ApiException('SPOONACULAR_API_KEY not found');
      }

      // Try to get cached data first
      final cacheKey = 'recipe_details_$recipeId';
      final cachedData = await _cacheManager.getFileFromCache(cacheKey);
      if (cachedData != null) {
        final cachedContent = await cachedData.file.readAsString();
        return jsonDecode(cachedContent);
      }

      final queryParams = {
        'apiKey': apiKey,
        'includeNutrition': 'true',
        'addWinePairing': 'true',
        'includeTaste': 'true',
      };

      final uri = Uri.parse('$spoonacularBaseUrl/recipes/$recipeId/information')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Cache the response
        await _cacheManager.putFile(
          cacheKey,
          Uint8List.fromList(jsonEncode(data).codeUnits),
          maxAge: cacheDuration,
        );

        return data;
      } else {
        _handleHttpError(response);
        throw ApiException('Failed to fetch recipe details: ${response.body}');
      }
    });
  }

  // Common pantry items to filter out
  static const Set<String> _commonPantryItems = {
    // Basic staples
    'salt',
    'pepper',
    'water',
    'flour',
    'sugar',
    'salt and pepper',

    // Fats and oils
    'oil',
    'olive oil',
    'cooking oil',
    'butter',
    'margarine',

    // Acids and condiments
    'vinegar',
    'ketchup',
    'mustard',
    'mayonnaise',
    'soy sauce',
    'hot sauce',

    // Baking ingredients
    'baking powder',
    'baking soda',
    'yeast',
    'cornstarch',
    'vanilla extract',
    'brown sugar',
    'powdered sugar',

    // Dried herbs and spices
    'seasoning',
    'garlic powder',
    'onion powder',
    'cinnamon',
    'paprika',
    'oregano',
    'basil',
    'thyme',
    'cumin',
    'chili powder',
    'black pepper',
    'white pepper',
    'cayenne pepper',
  };

  // HTTP error handler
  static void _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        throw const ApiException('Unauthorized: Invalid API key');
      case 402:
        throw const ApiException('API quota exceeded');
      case 429:
        throw const ApiException('Too many requests. Please try again later');
      case 500:
        throw const ApiException('Server error. Please try again later');
      default:
        throw ApiException('HTTP error ${response.statusCode}');
    }
  }
}

// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
