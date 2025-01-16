import 'package:flutter/material.dart';

class IngredientsPage extends StatelessWidget {
  final List<String> ingredients;

  const IngredientsPage({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detected Ingredients'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ingredients.isEmpty
          ? const Center(
              child: Text('No ingredients detected'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant),
                    title: Text(
                      ingredients[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.check_circle_outline),
                  ),
                );
              },
            ),
    );
  }
}
