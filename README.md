# 🍽️ Fridge Recipe App

A Flutter-based mobile application that helps users discover recipes based on ingredients they have at home. Simply take a photo of your ingredients, and let the app suggest delicious recipes. Save favorites, plan meals, and access nutritional information all in one place.

## ✨ Features

* **Ingredient Analysis**: Snap a photo of your ingredients for automatic detection and listing
* **Recipe Suggestions**: Get personalized recipe recommendations based on detected ingredients
* **Recipe Details**: Access comprehensive recipe information including ingredients, instructions, and nutritional facts
* **Save Recipes**: Bookmark your favorite recipes for quick future reference
* **Meal Planning**: Organize your weekly meals by scheduling recipes for specific days
* **Nutritional Information**: View detailed nutritional breakdown for each recipe
* **Shopping List**: Generate shopping lists from your planned meals' ingredients

## 🚀 Getting Started

### Prerequisites

* **Flutter SDK**: Required for development. [Install Flutter](https://flutter.dev/docs/get-started/install)
* **Dart SDK**: Included with Flutter installation
* **API Keys**: Required for core functionality:
  * [Spoonacular API](https://spoonacular.com/food-api) - Recipe and nutritional data
  * [Groq API](https://groq.com/) - Image analysis capabilities

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/6ogo/fridge-recipe-app.git
   cd fridge-recipe-app
   ```

2. Configure API keys:
   * Create a `.env` file in the project root
   * Add your API keys:
     ```env
     SPOONACULAR_API_KEY=your_spoonacular_api_key
     GROQ_API_KEY=your_groq_api_key
     ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Launch the app:
   ```bash
   flutter run
   ```

## 📦 Dependencies

Key packages used in this project:

* `flutter_dotenv`: Environment variable management
* `http`: API request handling
* `image_picker`: Camera and gallery image capture
* `shared_preferences`: User preferences and recipe storage
* `flutter_cache_manager`: API response caching
* `flutter_slidable`: Swipeable list items

For a complete list of dependencies, refer to `pubspec.yaml`.

## 📁 Project Structure

```
lib/
├── main.dart              # Application entry point
├── home_page.dart         # Main screen with photo capture
├── results_page.dart      # Recipe suggestions display
├── recipe_details_page.dart # Detailed recipe information
├── saved_recipes_page.dart # Saved recipes management
├── api_service.dart       # API integration handling
└── ingredients_page.dart  # Detected ingredients display
```

## 🎯 Usage Guide

### Ingredient Detection
1. Launch the app
2. Tap "Add Photo" on the home screen
3. Take a photo of your ingredients
4. Wait for automatic ingredient detection

### Recipe Discovery
1. Browse suggested recipes based on detected ingredients
2. Tap any recipe for detailed information

### Recipe Management
* **Save**: Tap the bookmark icon on recipe details
* **Access Saved**: Navigate to "Saved Recipes" tab
* **Meal Planning**: Swipe left on saved recipes to add to meal plan
* **Nutritional Info**: Available on recipe details screen

## 🤝 Contributing

We welcome contributions! To contribute:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

* [Spoonacular API](https://spoonacular.com/food-api) - Recipe and nutritional data
* [Groq API](https://groq.com/) - Image analysis capabilities
* [Flutter](https://flutter.dev) - Development framework

---

Built with using Flutter
