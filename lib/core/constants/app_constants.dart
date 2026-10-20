import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Configuración de la API de Gemini
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Modelo actualizado según lo requerido por el endpoint
  static const String geminiModel = "gemini-3.8-flash";
  
  static const String geminiBaseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent";

  // Colores de categorías para la tabla periódica (Uso global)
  static const Map<String, String> categoryToColor = {
    "alkali": "Colors.red",
    "alkaline": "Colors.orange",
    "transition": "Colors.yellow",
    "post-transition": "Colors.green",
    "metalloid": "Colors.teal",
    "non-metal": "Colors.blue",
    "noble": "Colors.purple",
    "lanthanide": "Colors.pink",
    "actinide": "Colors.deepOrange",
  };
}