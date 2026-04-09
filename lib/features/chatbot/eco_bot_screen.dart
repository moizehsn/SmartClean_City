import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/mock/mock_data.dart';
import '../../shared/widgets/app_text_field.dart';

class EcoBotScreen extends StatefulWidget {
  const EcoBotScreen({super.key});

  @override
  State<EcoBotScreen> createState() => _EcoBotScreenState();
}

class _EcoBotScreenState extends State<EcoBotScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<MockMessage> _messages = List.from(kMockMessages);

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(MockMessage(texte: text, isUser: true, heure: '09:15'));
      _messages.add(const MockMessage(
        texte:
            "Je n'ai pas compris votre question. Pouvez-vous reformuler ? 🌿",
        isUser: false,
        heure: '09:15',
      ));
    });
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Eco-Bot',
                    style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface)),
                Text('IA',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _ChatBubble(message: _messages[i]),
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              boxShadow: AppColors.botanicalShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    hintText: 'Demander à Eco-Bot…',
                    controller: _msgCtrl,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final MockMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.primaryGradient : null,
          color: isUser ? null : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: AppColors.botanicalShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.texte,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isUser ? Colors.white : AppColors.onSurface,
                    height: 1.5)),
            const SizedBox(height: 4),
            Text(message.heure,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isUser
                        ? Colors.white60
                        : AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
