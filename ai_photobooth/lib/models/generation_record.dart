class GenerationRecord {
  GenerationRecord({
    required this.id,
    required this.createdByEmail,
    required this.prompt,
    required this.outputImageBase64,
    required this.createdAtIso,
    required this.likedByEmails,
    this.originalImageBase64,
  });

  final String id;
  final String createdByEmail;
  final String prompt;
  final String outputImageBase64;
  final String createdAtIso;
  final List<String> likedByEmails;
  final String? originalImageBase64;

  int get likeCount => likedByEmails.length;

  bool isLikedBy(String email) {
    final e = email.trim().toLowerCase();
    return likedByEmails.any((x) => x.toLowerCase() == e);
  }

  GenerationRecord copyWith({
    List<String>? likedByEmails,
    String? originalImageBase64,
  }) {
    return GenerationRecord(
      id: id,
      createdByEmail: createdByEmail,
      prompt: prompt,
      outputImageBase64: outputImageBase64,
      createdAtIso: createdAtIso,
      likedByEmails: likedByEmails ?? this.likedByEmails,
      originalImageBase64: originalImageBase64 ?? this.originalImageBase64,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdByEmail': createdByEmail,
    'prompt': prompt,
    'outputImageBase64': outputImageBase64,
    'createdAtIso': createdAtIso,
    'likedByEmails': likedByEmails,
    if (originalImageBase64 != null) 'originalImageBase64': originalImageBase64,
  };

  factory GenerationRecord.fromJson(Map<String, dynamic> json) {
    final likes = json['likedByEmails'];
    return GenerationRecord(
      id: json['id'] as String,
      createdByEmail: json['createdByEmail'] as String,
      prompt: json['prompt'] as String,
      outputImageBase64: json['outputImageBase64'] as String,
      createdAtIso: json['createdAtIso'] as String,
      likedByEmails: likes is List
          ? likes.map((e) => e.toString()).toList()
          : <String>[],
      originalImageBase64: json['originalImageBase64'] as String?,
    );
  }
}