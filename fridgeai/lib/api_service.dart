import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static Future<List<String>> analyzeImage(File imageFile) async {
    const apiUrl = 'https://api.groq.com/v1/models/llama-3.2-11b-vision-preview/analyze';
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
    const apiUrl = 'https://api.edamam.com/api/recipes/v2';
    final appId = dotenv.env['EDAMAM_APP_ID'];
    final appKey = dotenv.env['EDAMAM_APP_KEY'];

    final response = await http.get(
      Uri.parse(
        '$apiUrl?type=public&q=${ingredients.join(",")}&app_id=$appId&app_key=$appKey',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hits'].map((hit) => hit['recipe']).toList();
    } else {
      throw Exception('Failed to fetch recipes');
    }
  }
}