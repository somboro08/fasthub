class PublicationModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorFiliere;
  final String authorLevel;
  final String authorStatus; // "Cam", "Res", "Bue", "Prof"
  final String authorAvatarUrl;
  final String content;
  final DateTime publishedAt;
  final String? imageUrl; // Optional image for the publication

  PublicationModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorFiliere,
    required this.authorLevel,
    required this.authorStatus,
    required this.authorAvatarUrl,
    required this.content,
    required this.publishedAt,
    this.imageUrl,
  });

  factory PublicationModel.fromJson(Map<String, dynamic> json) {
    return PublicationModel(
      id: json['id'],
      authorId: json['author_id'],
      authorName: json['author_name'],
      authorFiliere: json['author_filiere'],
      authorLevel: json['author_level'],
      authorStatus: json['author_status'],
      authorAvatarUrl: json['author_avatar_url'],
      content: json['content'],
      publishedAt: DateTime.parse(json['published_at']),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'author_filiere': authorFiliere,
      'author_level': authorLevel,
      'author_status': authorStatus,
      'author_avatar_url': authorAvatarUrl,
      'content': content,
      'published_at': publishedAt.toIso8601String(),
      'image_url': imageUrl,
    };
  }
}