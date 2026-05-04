/// Blocks unsafe / explicit prompts before calling the model (best-effort filter).
class ContentModeration {
  ContentModeration._();

  static final RegExp _nonAlphaNum = RegExp(r'[^a-z0-9]+');

  static final Set<String> _blockedTokens = {
    'nude',
    'nudes',
    'naked',
    'nsfw',
    'porn',
    'sex',
    'sexual',
    'erotic',
    'fetish',
    'hentai',
    'rape',
    'child',
    'minor',
    'cp',
    'explicit',
    'genitals',
    'penis',
    'vagina',
    'breast',
    'boobs',
    'asshole',
    'pussy',
    'dick',
    'cum',
    'bdsm',
    'incest',
    'strip',
    'stripper',
    'xxx',
    'onlyfans',
    'deepfake',
    'undress',
    'no clothes',
    'without clothes',
    'blood',
    'gore',
    'kill',
    'murder',
    'terror',
    'terrorist',
    'suicide',
    'drug deal',
    'cocaine',
    'heroin',
    'meth',
  };

  /// Returns null if OK, otherwise a short reason shown to the user.
  static String? validatePrompt(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return 'Please enter what you want the AI to change.';
    }
    if (text.length > 800) {
      return 'Prompt is too long. Keep it under 800 characters.';
    }

    final normalized = text.toLowerCase().replaceAll(_nonAlphaNum, ' ');
    final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();

    for (final w in words) {
      if (_blockedTokens.contains(w)) {
        return 'That kind of request isn’t allowed. Please describe a safe, appropriate edit.';
      }
    }

    for (final phrase in _blockedTokens) {
      if (phrase.contains(' ')) {
        if (normalized.contains(phrase)) {
          return 'That kind of request isn’t allowed. Please describe a safe, appropriate edit.';
        }
      }
    }

    return null;
  }
}
