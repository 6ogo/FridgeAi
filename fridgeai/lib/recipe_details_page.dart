class Recipe {
  final String label;
  final List<String> ingredientLines;
  final String url;

  Recipe({
    required this.label,
    required this.ingredientLines,
    required this.url,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      label: json['label'],
      ingredientLines: List<String>.from(json['ingredientLines']),
      url: json['url'] ?? 'No instructions available.',
    );
  }
}