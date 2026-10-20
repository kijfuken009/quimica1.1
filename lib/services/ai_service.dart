import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../data/models/element_model.dart';
import '../data/models/reaction_model.dart';

class AIService {
  List<ElementModel> _localElements = [];
  List<ReactionModel> _localReactions = [];
  bool _dataLoaded = false;

  // Modelos vigentes oficiales indicados por el endpoint
  static const List<String> _candidateModels = [
    "gemini-3.8-flash",
    "gemini-3.5-flash-lite",
  ];

  Future<void> _ensureLocalDataLoaded() async {
    if (_dataLoaded) return;
    try {
      final String elemStr = await rootBundle.loadString('assets/data/elements.json');
      final List<dynamic> elemJson = jsonDecode(elemStr);
      _localElements = elemJson.map((e) => ElementModel.fromJson(e)).toList();

      final String reacStr = await rootBundle.loadString('assets/data/reactions.json');
      final List<dynamic> reacJson = jsonDecode(reacStr);
      _localReactions = reacJson.map((e) => ReactionModel.fromJson(e)).toList();

      _dataLoaded = true;
    } catch (e) {
      debugPrint("Error precargando base local: $e");
    }
  }

  String _clean(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  String? _resolveOffline(String query, String userName) {
    final q = _clean(query);

    if (q == 'hola' || q == 'buenas' || q == 'buenos dias' || q == 'buenas tardes') {
      return "¡Hola $userName! 👋 Soy ChemIA, tu tutor escolar de química. Puedes consultarme sobre cualquier elemento de la tabla periódica o reacciones químicas.";
    }

    // Palabras comunes en español que coinciden con símbolos químicos y no deben activar elementos a ciegas
    const stopwords = {'se', 'no', 'as', 'in', 'at', 'es', 'al', 'o', 'y', 'he'};

    for (final el in _localElements) {
      final nameClean = _clean(el.nombre);
      final symClean = _clean(el.simbolo);

      final bool matchName = q.contains(nameClean);
      final bool matchNumber = q.contains("numero ${el.numero}");
      
      // Si el símbolo es una palabra común ('se', 'no', etc.), solo se activa si el usuario escribe explícitamente "simbolo"
      final bool matchSymbol = (!stopwords.contains(symClean) && q.split(' ').contains(symClean)) ||
                               (q.contains("simbolo") && q.split(' ').contains(symClean));

      if (matchName || matchNumber || matchSymbol) {
        return "🔬 **${el.nombre} (${el.simbolo})** [N° ${el.numero}]:\n\n"
               "• **Categoría:** ${el.categoria}\n"
               "• **Peso Atómico:** ${el.peso} u\n"
               "• **Uso cotidiano:** ${el.uso}\n"
               "• **Dato Curioso:** ${el.datoCurioso}";
      }
    }

    for (final r in _localReactions) {
      final reacClean = _clean(r.nombre);
      if (q.contains(reacClean) || (q.contains("reaccion") && q.contains(_clean(r.tipo)))) {
        return "⚗️ **${r.nombre}** (${r.tipo}):\n\n"
               "• **Ecuación:** ${r.ecuacion}\n"
               "• **Reactivos y Productos:** ${r.reactivos} ➔ ${r.productos}\n"
               "• **Explicación:** ${r.explicacion}\n"
               "• **Energía:** ${r.energia}\n"
               "${r.esPeligrosa ? '\n⚠️ **Advertencia:** ${r.advertenciaSeguridad}' : '\n✅ Segura para estudio escolar.'}";
      }
    }

    if (q.contains("tabla periodica")) {
      return "La Tabla Periódica ordena los 118 elementos químicos conocidos según su número atómico creciente y sus propiedades químicas. Fue ideada en su forma moderna por Dmitri Mendeléyev.";
    }
    if (q.contains("atomo")) {
      return "El átomo es la unidad estructural básica de toda la materia. Contiene un núcleo central con protones (carga positiva) y neutrones, alrededor del cual orbitan los electrones (carga negativa).";
    }

    return null;
  }

  Future<String> askChemistryAI(String prompt, String userName, int age) async {
    await _ensureLocalDataLoaded();

    // 1. Prioridad Offline Instantánea
    final localAnswer = _resolveOffline(prompt, userName);
    if (localAnswer != null) {
      return "$localAnswer\n\n*(Respuesta local instantánea ⚡)*";
    }

    if (AppConstants.geminiApiKey.isEmpty || AppConstants.geminiApiKey.contains("PEGA_AQUI")) {
      return "💡 Estoy funcionando en modo local. Puedes preguntarme por los 118 elementos o reacciones químicas.";
    }

    final String systemInstruction =
        "Eres 'ChemIA', un tutor pedagógico de Química amigable y didáctico para estudiantes de secundaria de $age años en Bolivia. "
        "El estudiante se llama $userName. "
        "REGLAS OBLIGATORIAS:\n"
        "1. Responde de manera clara, entusiasta y concisa (máximo 2 párrafos cortos).\n"
        "2. Solo responde dudas relacionadas con Química, elementos, enlaces, reacciones y ciencia molecular. Si preguntan otra materia, recházalo con amabilidad.\n"
        "3. Usa analogías sencillas y formato Markdown con viñetas para lectura ágil en móvil.\n"
        "4. Si la consulta involucra sustancias de riesgo, recalca la supervisión de un profesor o adulto.";

    // 2. Consulta a los modelos vigentes con soporte para 503/alta demanda
    for (final model in _candidateModels) {
      for (int intento = 1; intento <= 2; intento++) {
        try {
          final url = Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${AppConstants.geminiApiKey}",
          );

          final response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "system_instruction": {
                "parts": [
                  {"text": systemInstruction}
                ]
              },
              "contents": [
                {
                  "parts": [
                    {"text": prompt}
                  ]
                }
              ],
              "generationConfig": {
                "temperature": 0.5,
                "maxOutputTokens": 450,
              }
            }),
          ).timeout(const Duration(seconds: 25));

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = jsonDecode(response.body);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'];
              final parts = content['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                return parts[0]['text'] ?? "No pude formular la respuesta.";
              }
            }
          } else if (response.statusCode == 503 || response.statusCode == 429) {
            debugPrint("Modelo $model ocupado ($response.statusCode), reintentando o cambiando...");
            await Future.delayed(const Duration(milliseconds: 700));
            continue;
          } else {
            debugPrint("Error HTTP ${response.statusCode} en modelo $model: ${response.body}");
            break;
          }
        } catch (e) {
          debugPrint("Fallo de red en $model: $e");
          break;
        }
      }
    }

    // 3. Respuesta de contingencia offline si Google sigue saturado
    return "⚡ Los servidores remotos están temporalmente congestionados, pero mi base local está 100% activa. Pregúntame sobre cualquier elemento químico (ej. 'Hierro', 'Litio', 'Oxígeno') o sobre reacciones químicas.";
  }
}