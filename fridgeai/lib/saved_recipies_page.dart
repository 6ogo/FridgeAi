import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'recipe_details_page.dart';

class SavedRecipesPage extends StatefulWidget {
  const SavedRecipesPage({super.key});

  @override
  SavedRecipesPageState createState() => SavedRecipesPageState();
}

class SavedRecipesPageState extends State<SavedRecipesPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> savedRecipes = [];
  List<Map<String, dynamic>> mealPlan = [];
  late TabController _tabController;
  final List<String> weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedRecipes();
    _loadMealPlan();
  }

  Future<void> _loadSavedRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = prefs.getStringList('saved_recipes') ?? [];
    setState(() {
      savedRecipes = recipesJson.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _loadMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final mealPlanJson = prefs.getStringList('meal_plan') ?? [];
    setState(() {
      mealPlan = mealPlanJson.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _saveMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final mealPlanJson = mealPlan.map((e) => json.encode(e)).toList();
    await prefs.setStringList('meal_plan', mealPlanJson);
  }

  Future<void> _addToMealPlan(Map<String, dynamic> recipe, String day) async {
    setState(() {
      mealPlan.add({
        ...recipe,
        'day': day,
      });
    });
    await _saveMealPlan();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showMealPlanDialog(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Meal Plan'),
        content: SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: weekDays.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(weekDays[index]),
                onTap: () => _addToMealPlan(recipe, weekDays[index]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSavedRecipesList() {
    if (savedRecipes.isEmpty) {
      return const Center(
        child: Text(
          'No saved recipes yet!\nTap the bookmark icon on any recipe to save it.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: savedRecipes.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final recipe = savedRecipes[index];
        return Slidable(
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _showMealPlanDialog(recipe),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: Icons.calendar_today,
                label: 'Plan',
              ),
              SlidableAction(
                onPressed: (_) async {
                  setState(() {
                    savedRecipes.removeAt(index);
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setStringList(
                    'saved_recipes',
                    savedRecipes.map((e) => json.encode(e)).toList(),
                  );
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: Card(
            child: ListTile(
              leading: recipe['image'] != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(recipe['image']),
                    )
                  : const CircleAvatar(child: Icon(Icons.restaurant)),
              title: Text(recipe['title']),
              subtitle: Text(
                'Ready in ${recipe['readyInMinutes']} minutes',
                style: TextStyle(color: Colors.grey[600]),
              ),
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
          ),
        );
      },
    );
  }

  Widget _buildMealPlanTab() {
    if (mealPlan.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No meals planned yet!\nSwipe left on saved recipes to add them to your meal plan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: weekDays.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, dayIndex) {
        final dayRecipes = mealPlan.where((recipe) => recipe['day'] == weekDays[dayIndex]).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                weekDays[dayIndex],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (dayRecipes.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text('No meals planned for ${weekDays[dayIndex]}'),
                  subtitle: const Text('Swipe left on saved recipes to add them'),
                ),
              )
            else
              ...dayRecipes.map((recipe) => Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) async {
                            setState(() {
                              mealPlan.remove(recipe);
                            });
                            await _saveMealPlan();
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Remove',
                        ),
                      ],
                    ),
                    child: Card(
                      child: ListTile(
                        leading: recipe['image'] != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(recipe['image']),
                              )
                            : const CircleAvatar(child: Icon(Icons.restaurant)),
                        title: Text(recipe['title']),
                        subtitle: Text(
                          'Ready in ${recipe['readyInMinutes']} minutes',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecipeDetailsPage(recipeId: recipe['id']),
                            ),
                          );
                        },
                      ),
                    ),
                  )),
            const Divider(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bookmark), text: 'Saved Recipes'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Meal Plan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedRecipesList(),
          _buildMealPlanTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const MealPrepTipsSheet(),
                );
              },
              icon: const Icon(Icons.lightbulb),
              label: const Text('Meal Prep Tips'),
            )
          : null,
    );
  }
}

class MealPrepTipsSheet extends StatelessWidget {
  const MealPrepTipsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          children: [
            const Text(
              'Meal Prep Tips',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTipCard(
              'Plan Your Menu',
              'Choose recipes with similar ingredients to minimize waste and prep time.',
              Icons.menu_book,
            ),
            _buildTipCard(
              'Prep in Batches',
              'Cook multiple portions of proteins, grains, and vegetables at once.',
              Icons.rice_bowl,
            ),
            _buildTipCard(
              'Smart Storage',
              'Invest in good quality containers and label them with dates.',
              Icons.inventory_2,
            ),
            _buildTipCard(
              'Prep Order',
              'Start with items that take longest to cook, then work on others while they\'re cooking.',
              Icons.schedule,
            ),
            _buildTipCard(
              'Variety is Key',
              'Include different colors and textures to keep meals interesting.',
              Icons.color_lens,
            ),
            _buildTipCard(
              'Food Safety',
              'Cool food properly before storing and follow safe storage guidelines.',
              Icons.security,
            ),
            const SizedBox(height: 16),
            const Text(
              'Weekly Prep Checklist',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildChecklist(),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(content),
      ),
    );
  }

  Widget _buildChecklist() {
    return Column(
      children: [
        _buildChecklistItem('Wash and chop vegetables'),
        _buildChecklistItem('Cook grains and legumes'),
        _buildChecklistItem('Prepare proteins'),
        _buildChecklistItem('Make sauces and dressings'),
        _buildChecklistItem('Portion meals into containers'),
        _buildChecklistItem('Label containers with dates'),
        _buildChecklistItem('Clean and organize workspace'),
      ],
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}