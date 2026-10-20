import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// [AIService] es la capa de servicio encargada de la comunicación
/// entre la aplicación móvil y el servidor de IA (Ollama) instalado en la PC.
class AIService {

  /// Envía una pregunta al modelo de IA y retorna la respuesta.
  /// Se implementa un "System Prompt" para forzar a la IA a comportarse
  /// exclusivamente como un tutor de química y ajustar su lenguaje a la edad del niño.
  Future<String> askChemistryAI(String prompt, String userName, int age) async {

    // 1. Construcción del Prompt de Sistema (Instrucciones de seguridad y comportamiento)
    // Esto evita que el niño use la IA para hacer tareas de otras materias.
    final String systemInstruction =
        "Eres 'ChemIA', un agente educativo experto en Química para niños de entre 11 y 13 años. "
        "El usuario se llama $userName y tiene $age años. "
        "REGLAS ESTRICTAS:\n"
        "1. Responde ÚNICAMENTE a preguntas relacionadas con la química.\n"
        "2. Si el usuario pregunta algo que NO sea de química, responde amablemente: "
        "'Lo siento, soy un agente especializado exclusivamente en química. ¿Tienes alguna duda sobre la tabla periódica o los elementos?'\n"
        "3. Usa un lenguaje sencillo, divertido y motivador, adecuado para un niño de $age años.\n"
        "4. Si la pregunta es muy compleja, intenta explicarla con analogías sencillas.";

    try {
      // 2. Petición HTTP al servidor (ngrok -> Ollama)
      final response = await http.post(
        Uri.parse(AppConstants.aiApiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": AppConstants.aiModel,
          "prompt": "$systemInstruction\n\nEstudiante: $prompt\nIA:",
          "stream": false, // Desactivamos el streaming para simplificar el manejo de la respuesta
        }),
      ).timeout(const Duration(seconds: 30)); // Timeout de seguridad para evitar que la app se congele

      // 3. Validación de la respuesta del servidor
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Ollama devuelve la respuesta en la llave 'response'
        return data['response'] ?? "La IA no pudo generar una respuesta.";
      } else {
        return "Error del servidor: ${response.statusCode}. Verifica que la PC esté encendida.";
      }
    } on Exception catch (e) {
      return "Error de conexión ($e): No se pudo contactar con el servidor de IA. "
             "Asegúrate de que la PC esté encendida y ngrok esté activo.";
    }
  }
}