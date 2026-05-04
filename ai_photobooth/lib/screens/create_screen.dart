import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/generation_store.dart';
import '../utils/share_helper.dart';

const List<String> kPromptSuggestions = [
  'Make it more cinematic with dramatic lighting',
  'Change background to cyberpunk city at night',
  'Turn it into Studio Ghibli anime style',
  'Add warm golden hour sunset glow',
  'Make it look like an oil painting',
  'Make the subject smiling and confident',
  'Add futuristic neon lights',
  'Convert to black and white moody style',
];

class CreateScreen extends StatefulWidget {
  final Uint8List? initialImage;      // For Remix
  final String? initialPrompt;
  final String? originalRecordId;

  const CreateScreen({
    super.key,
    this.initialImage,
    this.initialPrompt,
    this.originalRecordId,
  });

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _prompt = TextEditingController();
  final AIService _ai = AIService();

  Uint8List? _input;
  Uint8List? _output;
  String? _lastRecordId;
  String? _error;
  bool _busy = false;
  Timer? _debounceTimer;

  bool get isRemixMode => widget.initialImage != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _input = widget.initialImage;
      if (widget.initialPrompt != null) {
        _prompt.text = widget.initialPrompt!;
      }
    }
  }

  @override
  void dispose() {
    _prompt.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_busy) return;

    final promptText = _prompt.text.trim();
    if (promptText.isEmpty) {
      setState(() => _error = 'Please enter a prompt');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _lastRecordId = null;
    });

    try {
      Uint8List? result;

      if (isRemixMode && _input != null) {
        result = await _ai.generateEditedPhoto(imageBytes: _input!, prompt: promptText);
      } else {
        result = await _ai.generateImage(prompt: promptText);
      }

      if (result == null || result.isEmpty) throw Exception('Empty response');

      final id = await GenerationStore.instance.addSuccessfulGeneration(
        createdByEmail: AuthService.instance.currentEmail!,
        prompt: promptText,
        outputBase64: base64Encode(result),
        originalImageBase64: isRemixMode ? base64Encode(_input!) : null,
      );

      if (!mounted) return;
      setState(() {
        _output = result;
        _lastRecordId = id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _ai.errorMessage ?? 'Generation failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onGeneratePressed() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), _generate);
  }

  Future<void> _toggleFavorite() async {
    final id = _lastRecordId;
    final email = AuthService.instance.currentEmail;
    if (id == null || email == null || _output == null) return;
    await GenerationStore.instance.toggleFavorite(recordId: id, userEmail: email);
    setState(() {});
  }

  Future<void> _share() async {
    final id = _lastRecordId;
    final bytes = _output;
    if (id == null || bytes == null) return;
    final link = 'boothai://generation/$id';
    await sharePngBytes(bytes, caption: 'Made with Booth AI\n"${_prompt.text.trim()}"\n$link');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final email = AuthService.instance.currentEmail!;
    final store = GenerationStore.instance;
    final fav = _lastRecordId != null && store.isFavorite(recordId: _lastRecordId!, userEmail: email);
    final loading = _busy || _ai.isLoading;

    return AnimatedBuilder(
      animation: Listenable.merge([_ai, GenerationStore.instance]),
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRemixMode ? 'Remixing Image' : 'Create New Image',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isRemixMode ? 'Add instructions to modify the image' : 'Describe the image you want',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Suggestions
              Text('Suggestions', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kPromptSuggestions.map((s) {
                  return ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      _prompt.text = s;
                      setState(() => _error = null);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              if (isRemixMode && _input != null) ...[
                const Text('Original Image', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_input!, height: 220, fit: BoxFit.cover),
                ),
                const SizedBox(height: 20),
              ],

              TextField(
                controller: _prompt,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Your prompt',
                  hintText: 'Make it cyberpunk style...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: loading ? null : _onGeneratePressed,
                  icon: loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(loading ? 'Generating...' : (isRemixMode ? 'Remix Image' : 'Generate Image')),
                ),
              ),

              if (_output != null) ...[
                const SizedBox(height: 24),
                const Text('Result', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(_output!, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleFavorite,
                        icon: Icon(fav ? Icons.star : Icons.star_border),
                        label: Text(fav ? 'Saved' : 'Favorite'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, style: TextStyle(color: cs.error)),
                ),
            ],
          ),
        );
      },
    );
  }
}