import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_capture_screen.dart';
import '../services/ai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AIService _aiService = AIService();

  Uint8List? _inputImageBytes;
  Uint8List? _resultImageBytes;
  bool _loading = false;
  String? _error;
  ImageSource _lastSource = ImageSource.gallery;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _error = null;
      _lastSource = ImageSource.gallery;
    });

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _inputImageBytes = bytes;
      _resultImageBytes = null;
    });
  }

  Future<void> _capturePhoto() async {
    try {
      final bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
      );
      if (bytes == null) return;
      setState(() {
        _error = null;
        _lastSource = ImageSource.camera;
        _inputImageBytes = bytes;
        _resultImageBytes = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Camera is not available on this device/browser. Use gallery as fallback.';
      });
    }
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();

    if (_inputImageBytes == null) {
      setState(() => _error = 'Please take or upload a photo first.');
      return;
    }
    if (prompt.isEmpty) {
      setState(() => _error = 'Please enter a background prompt.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _aiService.generateEditedPhoto(
        imageBytes: _inputImageBytes!,
        prompt: prompt,
      );

      setState(() {
        _resultImageBytes = result;
      });
    } catch (e) {
      setState(() {
        _error =
            _aiService.errorMessage ??
            e.toString().replaceFirst('Exception: ', '');
        // Keep the UI usable for demos when API quota/network fails.
        _resultImageBytes = _inputImageBytes;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _imagePanel({
    required String label,
    required Uint8List? imageBytes,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: imageBytes == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 40, color: Colors.grey.shade500),
                    const SizedBox(height: 8),
                    Text(label, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Photobooth Setup'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _promptController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Background prompt',
                  hintText: 'Describe any background you want',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _capturePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(kIsWeb ? 'Open webcam' : 'Open camera'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.upload),
                    label: const Text('Use gallery (fallback)'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Last input source: ${_lastSource == ImageSource.camera ? 'Camera' : 'Upload'}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 220,
                child: Row(
                  children: [
                    _imagePanel(
                      label: 'Input photo',
                      imageBytes: _inputImageBytes,
                      icon: Icons.person,
                    ),
                    const SizedBox(width: 10),
                    _imagePanel(
                      label: 'AI output',
                      imageBytes: _resultImageBytes,
                      icon: Icons.auto_awesome,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_loading || _aiService.isLoading) ? null : _generate,
                  icon: (_loading || _aiService.isLoading)
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(
                    (_loading || _aiService.isLoading)
                        ? 'Generating...'
                        : 'Generate photobooth result',
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}