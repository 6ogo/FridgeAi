import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class RecipeDetailsPage extends StatefulWidget {
  final int recipeId;

  const RecipeDetailsPage({super.key, required this.recipeId});

  @override
  RecipeDetailsPageState createState() => RecipeDetailsPageState();
}

class RecipeDetailsPageState extends State<RecipeDetailsPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? recipe;
  Map<String, dynamic>? nutritionInfo;
  bool isLoading = true;
  bool isRecipeSaved = false;
  Set<int> completedSteps = {};
  Set<String> selectedIngredients = {};

  final Map<String, IconData> equipmentIcons = {
    'oven': Icons.microwave,
    'pan': Icons.soup_kitchen,
    'bowl': Icons.coffee,
    'knife': Icons.cut,
    'cutting board': Icons.grid_on,
    'spoon': Icons.soup_kitchen,
    'fork': Icons.restaurant_menu,
    'whisk': Icons.egg,
    'blender': Icons.blender,
    'grater': Icons.foundation,
    'pot': Icons.soup_kitchen,
    'baking sheet': Icons.rectangle_outlined,
    'measuring cups': Icons.local_drink,
    'measuring spoons': Icons.coffee_maker,
    'food processor': Icons.blender,
    'colander': Icons.filter_alt,
    'peeler': Icons.content_cut,
    'spatula': Icons.space_bar,
    'tongs': Icons.content_cut,
  };

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadCompletedSteps();
    _fetchAllRecipeData();
    _checkIfRecipeSaved();
    _loadSelectedIngredients();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfRecipeSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRecipes = prefs.getStringList('saved_recipes') ?? [];
    setState(() {
      isRecipeSaved = savedRecipes.any((recipeJson) {
        final recipe = json.decode(recipeJson);
        return recipe['id'] == widget.recipeId;
      });
    });
  }

  Future<void> _toggleSaveRecipe() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRecipes = prefs.getStringList('saved_recipes') ?? [];

    if (isRecipeSaved) {
      final updatedRecipes = savedRecipes.where((recipeJson) {
        final recipe = json.decode(recipeJson);
        return recipe['id'] != widget.recipeId;
      }).toList();
      await prefs.setStringList('saved_recipes', updatedRecipes);
    } else {
      if (recipe != null) {
        final recipeJson = json.encode({
          'id': widget.recipeId,
          'title': recipe!['title'],
          'image': recipe!['image'],
          'readyInMinutes': recipe!['readyInMinutes'],
        });
        savedRecipes.add(recipeJson);
        await prefs.setStringList('saved_recipes', savedRecipes);
      }
    }

    setState(() {
      isRecipeSaved = !isRecipeSaved;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            isRecipeSaved ? 'Recipe saved!' : 'Recipe removed from saved list'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: _toggleSaveRecipe,
        ),
      ),
    );
  }

  Future<void> _loadSelectedIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final selected =
        prefs.getStringList('selected_ingredients_${widget.recipeId}') ?? [];
    setState(() {
      selectedIngredients = selected.toSet();
    });
  }

  Future<void> _saveSelectedIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'selected_ingredients_${widget.recipeId}',
      selectedIngredients.toList(),
    );
  }

  Future<void> _loadCompletedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSteps =
        prefs.getStringList('completed_steps_${widget.recipeId}');
    if (savedSteps != null) {
      setState(() {
        completedSteps = savedSteps.map((s) => int.parse(s)).toSet();
      });
    }
  }

  Future<void> _saveCompletedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'completed_steps_${widget.recipeId}',
      completedSteps.map((s) => s.toString()).toList(),
    );
  }

  void _toggleStepCompletion(int index) async {
    await HapticFeedback.mediumImpact();

    setState(() {
      if (completedSteps.contains(index)) {
        completedSteps.remove(index);
      } else {
        completedSteps.add(index);
      }
    });

    _saveCompletedSteps();
    _animationController.reset();
    _animationController.forward();
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

  IconData getEquipmentIcon(String equipmentName) {
    String lowercaseName = equipmentName.toLowerCase();
    for (var entry in equipmentIcons.entries) {
      if (lowercaseName.contains(entry.key)) {
        return entry.value;
      }
    }
    return Icons.kitchen;
  }

  Widget _buildShoppingListButton() {
    if (recipe == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.shopping_cart, color: Colors.blue),
        title: const Text('Shopping List'),
        subtitle: Text(
            '${selectedIngredients.length}/${recipe!['extendedIngredients'].length} items selected'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (_, controller) => Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Shopping List',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedIngredients.clear();
                            });
                            _saveSelectedIngredients();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: recipe!['extendedIngredients'].length,
                        itemBuilder: (context, index) {
                          final ingredient =
                              recipe!['extendedIngredients'][index];
                          final isSelected = selectedIngredients
                              .contains(ingredient['id'].toString());

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedIngredients
                                      .add(ingredient['id'].toString());
                                } else {
                                  selectedIngredients
                                      .remove(ingredient['id'].toString());
                                }
                              });
                              _saveSelectedIngredients();
                            },
                            title: Text(ingredient['original']),
                            subtitle: Text(
                              '${ingredient['measures']['metric']['amount']} ${ingredient['measures']['metric']['unitShort']}',
                            ),
                            secondary: Icon(
                              Icons.shopping_basket,
                              color: isSelected ? Colors.green : Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _buildProgressFAB() {
    if (recipe == null) return const SizedBox.shrink();

    final analyzedInstructions = recipe!['analyzedInstructions'] as List?;
    if (analyzedInstructions == null || analyzedInstructions.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalSteps = analyzedInstructions[0]['steps'].length;
    final completedCount = completedSteps.length;
    final progress = totalSteps > 0 ? completedCount / totalSteps : 0.0;

    return FloatingActionButton.extended(
      onPressed: null,
      label: Text('$completedCount/$totalSteps steps'),
      icon: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            color: Colors.white,
          ),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
                  '${recipe!['preparationMinutes'] ?? 0} min',
                  Icons.access_time,
                ),
                _cookingInfoItem(
                  'Cook Time',
                  '${recipe!['cookingMinutes'] ?? 0} min',
                  Icons.outdoor_grill,
                ),
                _cookingInfoItem(
                  'Servings',
                  '${recipe!['servings'] ?? 1}',
                  Icons.people,
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

    final analyzedInstructions = recipe!['analyzedInstructions'] as List?;

    if (analyzedInstructions == null || analyzedInstructions.isEmpty) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cooking Instructions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await HapticFeedback.heavyImpact();
                    setState(() {
                      completedSteps.clear();
                    });
                    _saveCompletedSteps();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Steps'),
                ),
              ],
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
                final isCompleted = completedSteps.contains(index);

                return GestureDetector(
                  onTap: () => _toggleStepCompletion(index),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.grey[100] : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                                color: isCompleted
                                    ? Colors.green
                                    : Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : Text(
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color:
                                          isCompleted ? Colors.grey[600] : null,
                                    ),
                                  ),
                                  if (equipment != null &&
                                      equipment.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: equipment.map<Widget>((e) {
                                        return Chip(
                                          avatar: Icon(
                                            getEquipmentIcon(e['name']),
                                            size: 16,
                                            color: Colors.grey[700],
                                          ),
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
                                          avatar: const Icon(
                                            Icons.food_bank,
                                            size: 16,
                                            color: Colors.green,
                                          ),
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
                      ],
                    ),
                  ),
                );
              },
            ),
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

  // Existing widget build methods remain the same
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

  // ... [Previous _buildInstructionsSection(), _buildProgressFAB(), etc. remain the same] ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe?['title'] ?? 'Recipe Details'),
        actions: [
          IconButton(
            icon: Icon(
              isRecipeSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isRecipeSaved ? Colors.yellow : null,
            ),
            onPressed: _toggleSaveRecipe,
          ),
        ],
      ),
      floatingActionButton: _buildProgressFAB(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe?['image'] != null)
                    Stack(
                      children: [
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
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${recipe!['readyInMinutes']} min',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _buildShoppingListButton(),
                  _buildNutritionSection(),
                  _buildDietaryInfo(),
                  _buildCookingInfo(),
                  _buildInstructionsSection(),
                  const SizedBox(height: 16),
                  // Ingredients section
                  const Text(
                    'Ingredients:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (recipe != null)
                    ...recipe!['extendedIngredients']
                        .map<Widget>((ingredient) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.fiber_manual_record,
                                      size: 8),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(ingredient['original']),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  const SizedBox(height: 16),
                  // Instructions section
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
