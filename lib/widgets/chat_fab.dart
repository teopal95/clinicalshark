import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/clinical_trial.dart';
import '../services/api_key_storage.dart';
import '../theme/app_theme.dart';

class ChatFab extends StatefulWidget {
  final ClinicalTrial? trial;
  const ChatFab({super.key, this.trial});

  @override
  State<ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<ChatFab> {
  bool _busy = false;

  Future<void> _onTap() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final key = await ApiKeyStorage.get();
      if (!mounted) return;

      if (key == null || key.isEmpty) {
        context.push('/setup-api-key', extra: widget.trial);
      } else {
        context.push('/chat', extra: widget.trial);
      }
    } catch (_) {
      // SharedPreferences failed — go to setup screen as fallback
      if (mounted) context.push('/setup-api-key', extra: widget.trial);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _busy ? null : _onTap,
      backgroundColor: AppTheme.accentColor,
      foregroundColor: Colors.white,
      elevation: 3,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome, size: 20),
      label: const Text(
        'Ask AI',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}
