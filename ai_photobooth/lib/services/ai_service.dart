import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService extends ChangeNotifier {
  final String _apiKey = 'AIzaSyDq8wDXXqvGLynlNZE3FYypwTZRN6VstF0';
  static const String _model = 'gemini-2.5-flash-image';
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<http.Response> _sendGenerateRequest({
    required Uint8List imageBytes,
    required String cleanPrompt,
  }) {
    return http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$_model:generateContent?key=$_apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Photobooth editing task: keep the person from the uploaded photo. '
                        'Replace only the background based on this user prompt: $cleanPrompt',
              },
              {
                'inlineData': {
                  'mimeType': 'image/png',
                  'data': base64Encode(imageBytes),
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
        },
      }),
    );
  }

  String _extractApiMessage(String body) {
    try {
      final err = jsonDecode(body) as Map<String, dynamic>;
      final inner = err['error'] as Map<String, dynamic>?;
      if (inner != null && inner['message'] != null) {
        return inner['message'] as String;
      }
    } catch (_) {
      // Fallback to raw response body.
    }
    return body;
  }

  Duration _parseRetryDelay(String message) {
    final match = RegExp(r'Please retry in ([0-9]+(?:\.[0-9]+)?)s').firstMatch(message);
    if (match == null) {
      return const Duration(seconds: 8);
    }
    final seconds = double.tryParse(match.group(1) ?? '') ?? 8;
    final milliseconds = (seconds * 1000).round();
    return Duration(milliseconds: milliseconds);
  }

  Future<Uint8List?> generateEditedPhoto({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw Exception('Missing API key. Add your Google Gemini key in ai_service.dart');
    }
    if (!_apiKey.trim().startsWith('AIza')) {
      throw Exception('Invalid Gemini key format. It should start with AIza.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanPrompt = prompt.trim().isEmpty
        ? 'A professional photobooth background with good lighting.'
        : prompt.trim();

    try {
      var response = await _sendGenerateRequest(
        imageBytes: imageBytes,
        cleanPrompt: cleanPrompt,
      );

      if (response.statusCode == 429) {
        final firstMessage = _extractApiMessage(response.body);
        final retryDelay = _parseRetryDelay(firstMessage);
        await Future<void>.delayed(retryDelay);
        response = await _sendGenerateRequest(
          imageBytes: imageBytes,
          cleanPrompt: cleanPrompt,
        );
      }

      if (response.statusCode != 200) {
        final apiMessage = _extractApiMessage(response.body);
        if (response.statusCode == 429) {
          throw Exception(
            'Quota exceeded for Gemini. Please enable billing or wait for quota reset, then try again.',
          );
        }
        throw Exception(
          'Gemini request failed (${response.statusCode}): $apiMessage',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>? ?? [];
      if (candidates.isEmpty) {
        throw Exception('Gemini $_model returned no candidates.');
      }

      final parts = candidates.first['content']?['parts'] as List<dynamic>? ?? [];
      for (final part in parts) {
        final inlineData = part['inlineData'] ?? part['inline_data'];
        if (inlineData is Map<String, dynamic> && inlineData['data'] != null) {
          return base64Decode(inlineData['data'] as String);
        }
      }
      throw Exception('Gemini $_model returned no generated image data.');
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}