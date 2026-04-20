class Match {
  final String userId;
  final String username;
  final String bio;
  final List<String> tags;
  final int score;
  final List<String> sharedTags;

  const Match({
    required this.userId,
    required this.username,
    required this.bio,
    required this.tags,
    required this.score,
    required this.sharedTags,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((t) => t.toString())
          .toList(growable: false),
      score: (json['score'] as num? ?? 0).round(),
      sharedTags: (json['sharedTags'] as List<dynamic>? ?? const [])
          .map((t) => t.toString())
          .toList(growable: false),
    );
  }
}