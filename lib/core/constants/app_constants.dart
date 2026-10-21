import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Configuración de la API de Gemini (protegida con .env)
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Modelo oficial vigente
  static const String geminiModel = "gemini-3.8-flash";
  
  static const String geminiBaseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent";

  // Colores de categorías para la tabla periódica (Tipados como Color)
  static const Map<String, Color> categoryToColor = {
    "alkali": Colors.redAccent,
    "alkaline": Colors.orangeAccent,
    "transition": Colors.amber,
    "post-transition": Colors.lightGreen,
    "metalloid": Colors.tealAccent,
    "non-metal": Colors.lightBlueAccent,
    "noble": Colors.purpleAccent,
    "lanthanide": Colors.pinkAccent,
    "actinide": Colors.deepOrangeAccent,
  };

  /// Método utilitario para obtener el color de una categoría de forma segura
  static Color getCategoryColor(String category) {
    return categoryToColor[category.toLowerCase()] ?? Colors.cyanAccent;
  }
}