enum StoryAuthorType { community, business }

class Story {
  const Story({
    required this.id,
    required this.authorType,
    required this.authorId,
    required this.authorName,
    required this.mediaUrl,
    required this.createdAt,
    required this.expiresAt,
    this.caption,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final type = (json['author_type'] as String) == 'business'
        ? StoryAuthorType.business
        : StoryAuthorType.community;
    final authorId = type == StoryAuthorType.business
        ? json['business_id'] as String
        : json['group_id'] as String;
    return Story(
      id: json['id'] as String,
      authorType: type,
      authorId: authorId,
      authorName: json['author_name'] as String,
      mediaUrl: json['media_url'] as String,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final String id;
  final StoryAuthorType authorType;
  final String authorId;
  final String authorName;
  final String mediaUrl;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isActive => DateTime.now().isBefore(expiresAt);
}
