import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clinical_trial.dart';
import '../services/chat_service.dart';
import '../services/api_key_storage.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final ClinicalTrial? trial;
  const ChatScreen({super.key, this.trial});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();

  ChatService? _service;
  final List<_Msg> _messages = [];
  bool _loading = false;
  bool _initializing = true;
  String? _initError;

  bool get _isTrialMode => widget.trial != null;

  static const _generalSuggestions = [
    'What is a Phase 3 clinical trial?',
    'How do I know if I qualify for a trial?',
    'What does "double-blind" mean?',
    'What should I ask my doctor about a trial?',
  ];

  static const _trialSuggestions = [
    'Am I likely to be eligible?',
    'What will happen during this study?',
    'What are the potential risks?',
    'How long will participation take?',
  ];

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final key = await ApiKeyStorage.get();
    if (key == null || key.isEmpty) {
      if (mounted) {
        setState(() {
          _initError = 'No API key found.';
          _initializing = false;
        });
      }
      return;
    }
    try {
      _service = ChatService(key, trial: widget.trial);
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = 'Failed to initialize AI: $e';
          _initializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading || _service == null) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(_Msg(text: trimmed, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _service!.send(trimmed);
      if (mounted) {
        setState(() => _messages.add(_Msg(text: reply, isUser: false)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add(_Msg(
              text: 'Sorry, something went wrong. Please try again.\n\n'
                  '_Error: ${_friendlyError(e.toString())}_',
              isUser: false,
              isError: true,
            )));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('api_key_invalid') || lower.contains('api key not valid')) {
      return 'Invalid API key. Tap the 🔑 icon above to update it.';
    }
    if (lower.contains('quota') || lower.contains('exhausted') ||
        lower.contains('billing') || lower.contains('429') ||
        lower.contains('resource_exhausted')) {
      return 'Free quota exceeded for today. Your Gemini API key has a limit of '
          '1,500 requests/day on the free tier. The quota resets at midnight '
          'Pacific time.\n\nTip: regenerate your key at aistudio.google.com/app/apikey '
          'if you shared it publicly — exposed keys are often throttled by Google.';
    }
    if (lower.contains('network') || lower.contains('socketexception') ||
        lower.contains('failed host lookup')) {
      return 'Network error. Check your internet connection and try again.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final trial = widget.trial;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ClinicalShark AI',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            if (trial != null)
              Text(
                trial.briefTitle,
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text('General assistant',
                  style: GoogleFonts.inter(
                      color: Colors.white60, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_outlined, size: 20),
            tooltip: 'Change API key',
            onPressed: () => context.push('/setup-api-key',
                extra: {'returnPath': '/chat', 'returnExtra': trial}),
          ),
        ],
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : _initError != null
              ? _buildInitError()
              : _buildChat(),
    );
  }

  Widget _buildInitError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.key_off_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text('API key not set up',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('You need a free Google Gemini API key to use the AI assistant.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/setup-api-key',
                  extra: {'returnPath': '/chat', 'returnExtra': widget.trial}),
              icon: const Icon(Icons.key_outlined),
              label: const Text('Set Up API Key'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        // trial context banner
        if (widget.trial != null) _buildTrialBanner(),
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= _messages.length) return const _TypingIndicator();
                    return _MessageBubble(msg: _messages[i]);
                  },
                ),
        ),
        _buildInput(),
      ],
    );
  }

  Widget _buildTrialBanner() {
    final t = widget.trial!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.primaryColor.withValues(alpha: 0.07),
      child: Row(
        children: [
          const Icon(Icons.science_outlined,
              size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${t.nctId} · ${t.briefTitle}',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final suggestions =
        _isTrialMode ? _trialSuggestions : _generalSuggestions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            _isTrialMode
                ? 'Ask me about this trial'
                : 'Clinical Trial Assistant',
            style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _isTrialMode
                ? 'I can explain eligibility, what the study involves, locations, risks, and anything else about this specific trial.'
                : 'I can explain clinical trial concepts, help you understand eligibility, decode medical terms, and more.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: suggestions
                .map((q) => _SuggestionChip(
                      label: q,
                      onTap: () => _send(q),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              focusNode: _inputFocus,
              maxLines: 4,
              minLines: 1,
              style: GoogleFonts.inter(fontSize: 14),
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Ask a question…',
                hintStyle:
                    GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              onPressed:
                  _loading ? null : () => _send(_inputCtrl.text),
              style: IconButton.styleFrom(
                backgroundColor:
                    _loading ? Colors.grey[300] : AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _Msg {
  final String text;
  final bool isUser;
  final bool isError;
  _Msg({required this.text, required this.isUser, this.isError = false});
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _Msg msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 14, height: 1.45),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 2),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 16),
          ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 60),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isError
                    ? Colors.red.shade50
                    : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: msg.isError
                      ? Colors.red.shade200
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.55,
                    color: msg.isError ? Colors.red[800] : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 2),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 16),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.33;
                  final opacity = ((_ctrl.value - delay) % 1.0)
                      .clamp(0.0, 1.0);
                  final t = opacity < 0.5
                      ? opacity * 2
                      : (1.0 - opacity) * 2;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.grey
                          .withValues(alpha: 0.4 + t * 0.6),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
