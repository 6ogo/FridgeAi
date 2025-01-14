import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class RecipeDetailsPage extends StatefulWidget {
  final int recipeId;

  const RecipeDetailsPage({super.key, required this.recipeId});

  @override
  RecipeDetailsPageState createState() => RecipeDetailsPageState();
}

class RecipeDetailsPageState extends State<RecipeDetailsPage> {
  Map<String, dynamic>? recipe;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    if (!mounted) return;
    
    try {
      final recipeDetails = await ApiService.fetchRecipeDetails(widget.recipeId);
      if (!mounted) return;
      
      setState(() {
        recipe = recipeDetails;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isLoading = false;
      });
      
      // Store the context before the async gap
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to fetch recipe details: $e')),
      );
    }
  }

  Future<void> _launchURL(String url, ScaffoldMessengerState messenger) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        
        messenger.showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      messenger.showSnackBar(
        SnackBar(content: Text('Error launching URL: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get ScaffoldMessenger once at the start of build
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
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
                    Image.network(
                      recipe!['image'],
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Failed to load image'),
                        );
                      },
                    ),
                  const SizedBox(height: 20),

                  const Text(
                    'Ingredients:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...recipe!['extendedIngredients']
                      .map<Widget>((ingredient) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('• ${ingredient['original']}'),
                          ))
                      .toList(),
                  const SizedBox(height: 20),

                  const Text(
                    'Instructions:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(recipe?['instructions'] ?? 'No instructions available.'),
                  const SizedBox(height: 20),

                  const Text(
                    'Source:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  InkWell(
                    onTap: () {
                      final url = recipe!['sourceUrl'];
                      // Pass the messenger to avoid BuildContext issues
                      _launchURL(url, scaffoldMessenger);
                    },
                    child: Text(
                      recipe!['sourceUrl'],
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}