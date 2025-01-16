import 'package:flutter/material.dart';
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
  int minUsedIngredients = 2; // Default filter
  List<dynamic> filteredRecipes = [];

  @override
  void initState() {
    super.initState();
    filteredRecipes = widget.recipes
        .where((recipe) => recipe['usedIngredientCount'] >= minUsedIngredients)
        .toList();
  }

  void _updateFilter(int value) {
    setState(() {
      minUsedIngredients = value;
      filteredRecipes = widget.recipes
          .where((recipe) => recipe['usedIngredientCount'] >= value)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list), // Button to view ingredients
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IngredientsPage(
                    ingredients: widget.ingredients,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<int>(
            onSelected: _updateFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Show recipes with at least 1 matching ingredient'),
              ),
              const PopupMenuItem(
                value: 2,
                child:
                    Text('Show recipes with at least 2 matching ingredients'),
              ),
              const PopupMenuItem(
                value: 3,
                child:
                    Text('Show recipes with at least 3 matching ingredients'),
              ),
              const PopupMenuItem(
                value: 0,
                child: Text('Show all recipes'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Implement refresh logic
        },
        child: ListView.builder(
          itemCount: filteredRecipes.length,
          itemBuilder: (context, index) {
            final recipe = filteredRecipes[index];
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
