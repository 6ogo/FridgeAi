import 'package:flutter/material.dart';

class RecipeDetailsPage extends StatelessWidget {
  final dynamic recipe;

  RecipeDetailsPage({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['title']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingredients:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(recipe['usedIngredients'].join("\n")),
            const SizedBox(height: 20),
            const Text('Instructions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(recipe['instructions'] ?? 'No instructions available.'),
          ],
        ),
      ),
    );
  }
}