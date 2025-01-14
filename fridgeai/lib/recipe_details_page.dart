import 'package:flutter/material.dart';
import 'api_service.dart';

class RecipeDetailsPage extends StatefulWidget {
  final int recipeId;

  const RecipeDetailsPage({super.key, required this.recipeId});

  @override
  RecipeDetailsPageState createState() => RecipeDetailsPageState();
}

class RecipeDetailsPageState extends State<RecipeDetailsPage> {
  Map<String, dynamic>? recipe;
  Map<String, dynamic>? nutritionInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllRecipeData();
  }

  Future<void> _fetchAllRecipeData() async {
    try {
      final recipeDetails =
          await ApiService.fetchRecipeDetails(widget.recipeId);
      final nutritionalDetails =
          await ApiService.fetchNutritionalInfo(widget.recipeId);

      if (!mounted) return;

      setState(() {
        recipe = recipeDetails;
        nutritionInfo = nutritionalDetails;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch recipe details: $e')),
      );
    }
  }

  Widget _buildNutritionSection() {
    if (nutritionInfo == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition Facts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _nutritionItem(
                  'Calories',
                  nutritionInfo!['calories'] ?? '0',
                  Icons.local_fire_department,
                ),
                _nutritionItem(
                  'Protein',
                  nutritionInfo!['protein'] ?? '0g',
                  Icons.fitness_center,
                ),
                _nutritionItem(
                  'Carbs',
                  nutritionInfo!['carbs'] ?? '0g',
                  Icons.grain,
                ),
                _nutritionItem(
                  'Fat',
                  nutritionInfo!['fat'] ?? '0g',
                  Icons.opacity,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    if (recipe == null) return const SizedBox.shrink();

    // Parse the analyzedInstructions if available
    final analyzedInstructions = recipe!['analyzedInstructions'] as List?;

    if (analyzedInstructions == null || analyzedInstructions.isEmpty) {
      // Fallback to plain text instructions
      return Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Instructions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Text(recipe!['instructions'] ?? 'No instructions available.'),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cooking Instructions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: analyzedInstructions[0]['steps'].length,
              itemBuilder: (context, index) {
                final step = analyzedInstructions[0]['steps'][index];
                final equipment = step['equipment'] as List?;
                final ingredients = step['ingredients'] as List?;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step['step'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                if (step['length'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${step['length']['number']} ${step['length']['unit']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (equipment != null &&
                                    equipment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: equipment.map<Widget>((e) {
                                      return Chip(
                                        avatar:
                                            const Icon(Icons.kitchen, size: 16),
                                        label: Text(e['name']),
                                        backgroundColor: Colors.grey[200],
                                      );
                                    }).toList(),
                                  ),
                                ],
                                if (ingredients != null &&
                                    ingredients.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: ingredients.map<Widget>((i) {
                                      return Chip(
                                        avatar: const Icon(Icons.food_bank,
                                            size: 16),
                                        label: Text(i['name']),
                                        backgroundColor: Colors.green[100],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (index < analyzedInstructions[0]['steps'].length - 1)
                        const Divider(height: 24),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryInfo() {
    if (recipe == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dietary Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Wrap(
              spacing: 8.0,
              children: [
                if (recipe!['vegetarian'] == true)
                  _dietaryChip('Vegetarian', Colors.green),
                if (recipe!['vegan'] == true)
                  _dietaryChip('Vegan', Colors.green),
                if (recipe!['glutenFree'] == true)
                  _dietaryChip('Gluten Free', Colors.orange),
                if (recipe!['dairyFree'] == true)
                  _dietaryChip('Dairy Free', Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            _buildHealthScore(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScore() {
    final healthScore = recipe?['healthScore'] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Score: $healthScore/100',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: healthScore / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            healthScore > 70
                ? Colors.green
                : healthScore > 40
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildCookingInfo() {
    if (recipe == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cooking Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _cookingInfoItem(
                  'Prep Time',
                  '${recipe!['preparationMinutes']} min',
                  Icons.access_time,
                ),
                _cookingInfoItem(
                  'Cook Time',
                  '${recipe!['cookingMinutes']} min',
                  Icons.outdoor_grill,
                ),
                _cookingInfoItem(
                  'Servings',
                  '${recipe!['servings']}',
                  Icons.people,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutritionItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _cookingInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _dietaryChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
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
                  if (recipe?['image'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        recipe!['image'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text('Failed to load image'),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildNutritionSection(),
                  _buildDietaryInfo(),
                  _buildCookingInfo(),
                  _buildInstructionsSection(),

                  // Original content
                  const Text(
                    'Ingredients:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...recipe!['extendedIngredients']
                      .map<Widget>((ingredient) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.fiber_manual_record, size: 8),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(ingredient['original']),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  const SizedBox(height: 16),

                  const Text(
                    'Instructions:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(recipe?['instructions'] ?? 'No instructions available.'),
                ],
              ),
            ),
    );
  }
}
