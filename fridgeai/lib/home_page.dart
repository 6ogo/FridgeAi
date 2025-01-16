import 'package:flutter/material.dart';
import 'package:fridgeai/saved_recipies_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'results_page.dart';
import 'api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  File? _image;
  bool _isProcessing = false;
  String? _errorMessage;

  Widget _buildHomeContent() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Analyzing ingredients...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            'Take a photo of your ingredients',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'We\'ll suggest recipes based on what you have',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _showImageSourceDialog,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add Photo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 15,
              ),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedRecipesPage(),
                ),
              );
            },
            icon: const Icon(Icons.bookmark),
            label: const Text('View Saved Recipes'),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _showImageSourceDialog,
          textColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isProcessing = true;
        });

        final ingredients = await ApiService.analyzeImage(_image!);

        if (ingredients.isEmpty) {
          throw Exception('No ingredients detected in the image');
        }

        final recipes = await ApiService.fetchRecipes(ingredients);

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsPage(
                recipes: recipes,
                ingredients: ingredients,
              ),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      // Handle no internet connection or API errors
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.message;
        });
        showError(e.message); // Show a SnackBar with the error message
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
        showError('Error: ${e.toString()}'); // Show a SnackBar with the error message
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Finder'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedRecipesPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildHomeContent(),
    );
  }
}