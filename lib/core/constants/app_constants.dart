class AppConstants {
  // URL de ngrok para conectar la app con tu PC vía Internet
  static const String aiApiUrl = "https://TU-URL-DE-NGROK.ngrok-free.app/api/generate";
  static const String aiModel = "llama3";

  // Colores de categorías para la tabla (Uso global)
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