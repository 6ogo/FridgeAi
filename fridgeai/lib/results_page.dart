import 'package:flutter/material.dart';
import 'package:fridgeai/ingredients_page.dart';
import 'recipe_details_page.dart';

class ResultsPage extends StatefulWidget {
  final List<dynamic> recipes;
  final List<String> ingredients;

  const ResultsPage({
    super.key,
    required this.recipes,
    required this.ingredients,
  });

  @override
  ResultsPageState createState() => ResultsPageState();
}

class ResultsPageState extends State<ResultsPage> {
  int minUsedIngredients = 2;
  late List<dynamic> filteredRecipes;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _filterRecipes();
  }

  void _filterRecipes() {
    setState(() {
      filteredRecipes = widget.recipes
          .where(
              (recipe) => recipe['usedIngredientCount'] >= minUsedIngredients)
          .toList();
    });
  }

  Widget _buildRecipeCard(dynamic recipe) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recipe['image'] != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              child: Image.network(
                recipe['image'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${recipe['usedIngredientCount']} matching ingredients',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RecipeDetailsPage(recipeId: recipe['id']),
                      ),
                    );
                  },
                  child: const Text('View Recipe'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      IngredientsPage(ingredients: widget.ingredients),
                ),
              );
            },
          ),
          PopupMenuButton<int>(
            onSelected: (value) {
              setState(() {
                minUsedIngredients = value;
                _filterRecipes();
              });
            },
            itemBuilder: (context) => [
              for (var i = 0; i <= 3; i++)
                PopupMenuItem(
                  value: i,
                  child: Text(
                    i == 0
                        ? 'Show all recipes'
                        : 'Show recipes with at least $i matching ingredients',
                  ),
                ),
            ],
          ),
        ],
      ),
      body: filteredRecipes.isEmpty
          ? const Center(
              child: Text(
                'No recipes found with the selected criteria',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) =>
                  _buildRecipeCard(filteredRecipes[index]),
            ),
    );
  }
}
