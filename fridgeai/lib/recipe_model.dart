class Recipe {
  final String title;
  final List<String> usedIngredients;
  final String instructions;

  Recipe({
    required this.title,
    required this.usedIngredients,
    required this.instructions,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'],
      usedIngredients: List<String>.from(json['usedIngredients']),
      instructions: json['instructions'] ?? 'No instructions available.',
    );
  }
}