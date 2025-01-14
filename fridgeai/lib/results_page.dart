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
        // Add search functionality here
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search dialog
            },
          ),
        ],
      ),
      // Replace ListView.builder with improved Card design
      body: RefreshIndicator(
        onRefresh: () async {
          // Implement refresh logic
        },
        child: ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (recipe['image'] != null)
                    Image.network(
                      recipe['image'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ListTile(
                    title: Text(
                      recipe['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Matching Ingredients: ${recipe['usedIngredientCount']}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailsPage(
                            recipeId: recipe['id'],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}