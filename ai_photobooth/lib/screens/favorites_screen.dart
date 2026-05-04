import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/generation_store.dart';
import '../widgets/generation_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final store = GenerationStore.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([auth, store]),
      builder: (context, _) {
        final user = auth.currentEmail;
        if (user == null) return const SizedBox.shrink();

        final favs = store.favoritesFor(user);
        if (favs.isEmpty) {
          return Center(
            child: Text(
              'No favorites yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: favs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return GenerationTile(
              record: favs[index],
              userEmail: user,
              dense: true,
            );
          },
        );
      },
    );
  }
}
