import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/generation_store.dart';
import '../widgets/generation_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final store = GenerationStore.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([auth, store]),
      builder: (context, _) {
        final user = auth.currentEmail;
        if (user == null) {
          return const SizedBox.shrink();
        }

        if (store.history.isEmpty) {
          return Center(
            child: Text(
              'No generations yet.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: store.history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final r = store.history[index];
            return GenerationTile(record: r, userEmail: user);
          },
        );
      },
    );
  }
}
