import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/api_key_storage.dart';
import '../theme/app_theme.dart';

class ApiKeyScreen extends StatefulWidget {
  final String returnPath;
  final Object? returnExtra;

  const ApiKeyScreen({
    super.key,
    required this.returnPath,
    this.returnExtra,
  });

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _validating = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final key = _ctrl.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Please enter your API key.');
      return;
    }

    setState(() { _validating = true; _error = null; });

    try {
      // Quick test call to verify the key works
      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: key);
      await model.generateContent([Content.text('Hi')]);
      await ApiKeyStorage.save(key);
      if (mounted) {
        context.pushReplacement(widget.returnPath, extra: widget.returnExtra);
      }
    } on GenerativeAIException catch (e) {
      setState(() => _error = e.message.contains('API_KEY_INVALID')
          ? 'Invalid API key. Please check and try again.'
          : 'Error: ${e.message}');
    } catch (_) {
      setState(() => _error = 'Could not connect. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Set Up AI Assistant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF2471A3)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ClinicalShark AI',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text(
                          'Powered by Google Gemini 2.0 Flash',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('How to get a free API key',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ..._steps(),
            const SizedBox(height: 28),
            Text('Your Gemini API Key',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              obscureText: _obscure,
              style: GoogleFonts.robotoMono(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'AIza...',
                hintStyle: GoogleFonts.robotoMono(
                    fontSize: 13, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _error != null
                        ? Colors.red
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryColor, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _validate(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_error!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.red[700])),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _validating ? null : _validate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _validating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Save & Start Chatting',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBDD3F5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 15, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your key is stored locally on this device and never sent to our servers. It is only used to communicate directly with Google Gemini.',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.blueGrey[700],
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _steps() {
    const steps = [
      ('1', 'Go to', 'aistudio.google.com/app/apikey', 'in your browser'),
      ('2', 'Sign in with your Google account', '', ''),
      ('3', 'Click "Create API key" — it\'s completely free', '', ''),
      ('4', 'Copy the key and paste it below', '', ''),
    ];

    return steps.map((s) {
      final (num, before, highlight, after) = s;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                  children: [
                    TextSpan(text: before),
                    if (highlight.isNotEmpty)
                      TextSpan(
                        text: ' $highlight ',
                        style: GoogleFonts.robotoMono(
                            fontSize: 13,
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w600),
                      ),
                    TextSpan(text: after),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
