import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'content_moderation.dart';

class AIService extends ChangeNotifier {
  static const String _manualApiKey = 'AIzaSyDCWk_-FWS6gqD1bGZdFHmp9fvT9avUNLo';
  static const String _dartDefineKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String _model = 'gemini-2.5-flash-image'; // Nano Banana

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get _effectiveKey {
    final fromDefine = _dartDefineKey.trim();
    return fromDefine.isNotEmpty ? fromDefine : _manualApiKey.trim();
  }

  Future<Uint8List?> generateImage({required String prompt}) async {
    return _callGemini(prompt: prompt, imageBytes: null);
  }

  Future<Uint8List?> generateEditedPhoto({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    return _callGemini(prompt: prompt, imageBytes: imageBytes);
  }

  Future<Uint8List?> _callGemini({
    required String prompt,
    Uint8List? imageBytes,
  }) async {
    final moderated = ContentModeration.validatePrompt(prompt);
    if (moderated != null) throw Exception(moderated);

    final cleanPrompt = prompt.trim().isEmpty
        ? (imageBytes != null ? 'Improve this image' : 'A beautiful high quality image')
        : prompt.trim();

    final key = _effectiveKey;
    if (key.isEmpty) throw Exception('No API key found');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> parts = [
        {
          'text': imageBytes != null
              ? 'Edit this image according to the instruction: $cleanPrompt'
              : 'Generate a high quality image: $cleanPrompt'
        }
      ];

      if (imageBytes != null) {
        parts.add({
          'inlineData': {
            'mimeType': 'image/png',
            'data': base64Encode(imageBytes),
          }
        });
      }

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$key',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {'parts': parts}
          ],
          'generationConfig': {
            'responseModalities': ['IMAGE'],
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List? ?? [];

        for (final candidate in candidates) {
          final partsList = candidate['content']?['parts'] as List? ?? [];
          for (final part in partsList) {
            final inlineData = part['inlineData'] ?? part['inline_data'];
            if (inlineData is Map && inlineData['data'] != null) {
              return base64Decode(inlineData['data'] as String);
            }
          }
        }
      }

      throw Exception('Generation failed (${response.statusCode})');
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}