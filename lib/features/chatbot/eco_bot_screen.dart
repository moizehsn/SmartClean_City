import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/ai_service.dart';
import '../../shared/widgets/app_text_field.dart';

// ─── Simple chat message model ───────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class EcoBotScreen extends StatefulWidget {
  const EcoBotScreen({super.key});

  @override
  State<EcoBotScreen> createState() => _EcoBotScreenState();
}

class _EcoBotScreenState extends State<EcoBotScreen>
    with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Welcome message added after first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        setState(() {
          _messages.add(
            _ChatMessage(
              text: l.t('ecobot_bienvenue'),
              isUser: false,
              time: _now(),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _now() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    final l = AppLocalizations.of(context);

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: _now()));
      _isLoading = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    try {
      final botReply = await AiService.sendMessage(text);
      setState(() {
        _messages.add(
          _ChatMessage(text: botReply, isUser: false, time: _now()),
        );
      });
    } catch (e) {
      debugPrint('AI API Error: $e');
      setState(() {
        _messages.add(
          _ChatMessage(text: l.t('ecobot_erreur'), isUser: false, time: _now()),
        );
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

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
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('ecobot_titre'),
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _isLoading ? l.t('ecobot_typing') : l.t('ecobot_en_ligne'),
                    key: ValueKey(_isLoading),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _isLoading
                          ? AppColors.tertiary
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Messages list ────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return _TypingIndicator(label: l.t('ecobot_reflexion'));
                }
                return _ChatBubble(message: _messages[i]);
              },
            ),
          ),

          // ── Input bar ────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              boxShadow: AppColors.botanicalShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    hintText: l.t('ecobot_hint'),
                    controller: _msgCtrl,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: _isLoading ? null : AppColors.primaryGradient,
                      color: _isLoading ? AppColors.surfaceContainerHigh : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _isLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.send_rounded,
                      color: _isLoading ? AppColors.outline : Colors.white,
                      size: 20,
                    ),
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

// ─── Chat bubble ─────────────────────────────────────────────────────────────
class _ChatBubble extends StatefulWidget {
  const _ChatBubble({required this.message});
  final _ChatMessage message;

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
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
                Text(
                  widget.message.text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isUser ? Colors.white : AppColors.onSurface,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.message.time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isUser ? Colors.white60 : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.label});
  final String label;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _dotControllers;

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _dotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: AppColors.botanicalShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_rounded,
              size: 14,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _dotControllers[i],
                builder: (_, _) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: 0.3 + _dotControllers[i].value * 0.7,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
