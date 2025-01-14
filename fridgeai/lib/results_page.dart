import 'package:flutter/material.dart';
import 'recipe_details_page.dart';

class ResultsPage extends StatelessWidget {
  final List<dynamic> recipes;

  const ResultsPage({super.key, required this.recipes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
      ),
      body: ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return ListTile(
            title: Text(recipe['title']),
            subtitle: Text('Used Ingredients: ${recipe['usedIngredientCount']}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailsPage(recipeId: recipe['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}