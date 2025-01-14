import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static Future<List<String>> analyzeImage(File imageFile) async {
    final apiUrl = 'https://api.groq.com/v1/models/llama-3.2-11b-vision-preview/analyze';
    final apiKey = dotenv.env['GROQ_API_KEY'];

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'image': base64Image}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['ingredients']);
    } else {
      throw Exception('Failed to analyze image');
    }
  }

  static Future<List<dynamic>> fetchRecipes(List<String> ingredients) async {
    final apiUrl = 'https://api.spoonacular.com/recipes/findByIngredients';
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];

    final response = await http.get(
      Uri.parse('$apiUrl?ingredients=${ingredients.join(",")}&apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch recipes');
    }
  }
}