import 'package:flutter/material.dart';

class RecipeDetailsPage extends StatelessWidget {
  final dynamic recipe;

  const RecipeDetailsPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['label']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingredients:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...recipe['ingredientLines'].map((ingredient) => Text(ingredient)).toList(),
            const SizedBox(height: 20),
            const Text('Instructions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(recipe['url'] ?? 'No instructions available.'),
          ],
        ),
      ),
    );
  }
}