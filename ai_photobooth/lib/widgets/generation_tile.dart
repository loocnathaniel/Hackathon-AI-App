import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/generation_record.dart';
import '../screens/create_screen.dart';
import '../services/generation_store.dart';
import '../utils/share_helper.dart';

class GenerationTile extends StatelessWidget {
  const GenerationTile({
    super.key,
    required this.record,
    required this.userEmail,
    this.dense = false,
  });

  final GenerationRecord record;
  final String userEmail;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final store = GenerationStore.instance;

    Uint8List bytes;
    try {
      bytes = base64Decode(record.outputImageBase64);
    } catch (_) {
      bytes = Uint8List(0);
    }

    final liked = record.isLikedBy(userEmail);
    final fav = store.isFavorite(recordId: record.id, userEmail: userEmail);

    final Widget image = dense
        ? ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 92,
        height: 92,
        child: bytes.isEmpty
            ? Container(color: cs.surfaceContainerHighest)
            : Image.memory(bytes, fit: BoxFit.cover),
      ),
    )
        : ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: bytes.isEmpty
            ? Container(color: cs.surfaceContainerHighest)
            : Image.memory(bytes, fit: BoxFit.cover),
      ),
    );

    final actions = Row(
      children: [
        IconButton(
          tooltip: 'Like',
          onPressed: () => store.toggleLike(recordId: record.id, userEmail: userEmail),
          icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? cs.primary : null),
        ),
        Text('${record.likeCount}'),
        const SizedBox(width: 8),

        IconButton(
          tooltip: 'Remix this image',
          onPressed: () {
            final originalBytes = record.originalImageBase64 != null
                ? base64Decode(record.originalImageBase64!)
                : bytes;

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateScreen(
                  initialImage: originalBytes,
                  initialPrompt: "Remix of: ${record.prompt}",
                ),
              ),
            );
          },
          icon: const Icon(Icons.auto_fix_high),
        ),

        const Spacer(),

        IconButton(
          tooltip: 'Favorite',
          onPressed: () => store.toggleFavorite(recordId: record.id, userEmail: userEmail),
          icon: Icon(fav ? Icons.star : Icons.star_border, color: fav ? cs.primary : null),
        ),

        IconButton(
          tooltip: 'Share',
          onPressed: bytes.isEmpty
              ? null
              : () => sharePngBytes(
            bytes,
            caption: 'Made with Booth AI\n"${record.prompt}"\nboothai://generation/${record.id}',
          ),
          icon: const Icon(Icons.ios_share),
        ),
      ],
    );

    if (dense) {
      return Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 92, child: image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.prompt, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(record.createdByEmail, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    actions,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            image,
            const SizedBox(height: 10),
            Text(record.prompt, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text('by ${record.createdByEmail}'),
            const SizedBox(height: 10),
            actions,
          ],
        ),
      ),
    );
  }
}