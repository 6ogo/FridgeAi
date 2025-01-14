import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class RecipeDetailsPage extends StatefulWidget {
  final int recipeId;

  const RecipeDetailsPage({super.key, required this.recipeId});

  @override
  RecipeDetailsPageState createState() => RecipeDetailsPageState();
}

class RecipeDetailsPageState extends State<RecipeDetailsPage> {
  Map<String, dynamic>? recipe;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      final Map<String, dynamic> recipeDetails;
      try {
        recipeDetails = await ApiService.fetchRecipeDetails(widget.recipeId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch recipe details: $e')),
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          recipe = recipeDetails;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch recipe details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe?['title'] ?? 'Recipe Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Recipe Image
                  if (recipe?['image'] != null) Image.network(recipe!['image']),
                  const SizedBox(height: 20),

                  // Display Ingredients
                  const Text(
                    'Ingredients:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...recipe!['extendedIngredients']
                      .map((ingredient) => Text('- ${ingredient['original']}'))
                      .toList(),
                  const SizedBox(height: 20),

                  // Display Instructions
                  const Text(
                    'Instructions:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(recipe?['instructions'] ?? 'No instructions available.'),
                  const SizedBox(height: 20),

                  // Display Source URL
                  const Text(
                    'Source:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final url = recipe!['sourceUrl'];
                      if (await canLaunchUrl(url)) {
                        await launchUrl(Uri.parse(url));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch $url')),
                        );
                      }
                    },
                    child: Text(
                      recipe!['sourceUrl'],
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
