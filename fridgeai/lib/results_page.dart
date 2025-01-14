import 'package:flutter/material.dart';
import 'dart:io';
import 'api_service.dart';
import 'recipe_details_page.dart';

class ResultsPage extends StatefulWidget {
  final File image;

  const ResultsPage({super.key, required this.image});

  @override
  ResultsPageState createState() => ResultsPageState();
}

class ResultsPageState extends State<ResultsPage> {
  List<String>? ingredients;
  List<dynamic>? recipes;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    // Send the image to the API for analysis
    final detectedIngredients = await ApiService.analyzeImage(widget.image);
    final recipeSuggestions = await ApiService.fetchRecipes(detectedIngredients);

    setState(() {
      ingredients = detectedIngredients;
      recipes = recipeSuggestions;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Suggestions'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Text('Detected Ingredients: ${ingredients!.join(", ")}'),
                Expanded(
                  child: ListView.builder(
                    itemCount: recipes!.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes![index];
                      return ListTile(
                        title: Text(recipe['label']),
                        subtitle: Text('Ingredients: ${recipe['ingredientLines'].join(", ")}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailsPage(recipe: recipe),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}