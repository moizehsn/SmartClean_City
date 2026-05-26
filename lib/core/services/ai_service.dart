import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/api_keys.dart';

/// Eco-Bot chatbot service — powered by Google Gemini 1.5 Flash.
class AiService {
  AiService._();

  // ── Gemini model (singleton, lazily initialised) ───────────────────────────
  static GenerativeModel? _model;
  static ChatSession? _chat;

  static const String _systemInstruction = '''
Tu es Eco-Bot, l'assistant officiel de l'application SmartClean City à Laghouat.

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
- Sois bref, utile et très poli.
''';

  static void _ensureInitialised() {
    if (_model != null) return;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: ApiKeys.geminiApiKey,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 512,
      ),
    );
    _chat = _model!.startChat();
  }

  /// Sends a message and returns the bot's response text.
  /// Never throws — returns a localised error string on failure.
  static Future<String> sendMessage(String text) async {
    try {
      _ensureInitialised();
      final response = await _chat!
          .sendMessage(Content.text(text))
          .timeout(const Duration(seconds: 30));
      return response.text?.trim() ??
          'Désolé, je rencontre des problèmes de connexion. Veuillez réessayer.';
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ GEMINI CHAT ERROR: $e');
      return 'Désolé, je rencontre des problèmes de connexion. Veuillez réessayer.';
    }
  }

  /// Resets the conversation to a fresh chat session.
  static void resetChat() {
    _ensureInitialised();
    _chat = _model!.startChat();
  }
}
