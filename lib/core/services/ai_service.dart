import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_keys.dart';

class AiService {
  static final List<Map<String, String>> _messages = [
    {
      "role": "system",
      "content":
          '''Tu es Eco-Bot, l'assistant officiel de l'application SmartClean City à Laghouat.

RÈGLE ABSOLUE DE LANGUE :
Tu DOIS répondre EXACTEMENT dans la langue utilisée par l'utilisateur.
- S'il te parle en Arabe (ou Arabe Algérien/Darja), réponds en Arabe clair et naturel.
- S'il te parle en Français, réponds en Français.

BASE DE CONNAISSANCES DE L'APPLICATION (Ne parle QUE de ces fonctionnalités, n'invente rien d'autre) :
1. Signaler (Signalement) : Le citoyen prend une photo des déchets, le GPS localise l'endroit automatiquement, et le signalement est envoyé.
2. Traitement par les chauffeurs : Les chauffeurs de camions bennes voient le signalement sur leur carte, se rendent sur place, nettoient, et prennent une photo "Après" pour clôturer la mission.
3. Points de Citoyenneté : Le citoyen gagne des points de récompense à chaque fois qu'un de ses signalements est nettoyé et validé.
4. Chatbot : Toi (Eco-Bot) pour donner des conseils sur le recyclage et l'utilisation de l'application.

CONTRAINTES STRICTES :
- N'invente AUCUNE fonctionnalité (pas de boutique en ligne, pas de paiement, pas de livraison).
- Refuse poliment toute question sur la programmation (Flutter, Firebase, Code) en disant que c'est confidentiel.
- Refuse de parler de sport, politique ou religion. Reste concentré sur l'environnement et l'application.
- Sois bref, utile et très poli.''',
    },
  ];

  /// Sends a message and returns the response text.
  static Future<String> sendMessage(String text) async {
    _messages.add({"role": "user", "content": text});

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': _messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['choices'][0]['message']['content'] as String;
        _messages.add({"role": "assistant", "content": reply});
        return reply;
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
        return 'Désolé, je n\'ai pas pu générer une réponse. (Erreur serveur)';
      }
    } catch (e) {
      print('Groq Request Error: $e');
      return 'Désolé, j\'ai rencontré un problème de connexion.';
    }
  }

  /// Clears chat history except system prompt
  static void resetChat() {
    if (_messages.isNotEmpty) {
      final systemPrompt = _messages.first;
      _messages.clear();
      _messages.add(systemPrompt);
    }
  }
}
