import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> sharePngBytes(
  Uint8List bytes, {
  String? caption,
}) async {
  final xf = XFile.fromData(
    bytes,
    mimeType: 'image/png',
    name: 'booth_ai.png',
  );
  await Share.shareXFiles([xf], text: caption);
}
