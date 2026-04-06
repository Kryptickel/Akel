import 'package:flutter/material.dart';
import 'voice_recording_widget.dart';

class VoiceNoteDialog extends StatelessWidget {
  const VoiceNoteDialog({super.key});

  static Future<String?> show(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => const VoiceNoteDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(20),
      content: VoiceRecordingWidget(
        maxDurationSeconds: 60,
        onRecordingComplete: (path) {
          debugPrint('✅ Voice note recorded: $path');
        },
      ),
    );
  }
}