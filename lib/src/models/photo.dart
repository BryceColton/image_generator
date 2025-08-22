class Photo {
  final String id;
  final String thumbUrl;
  final String fullUrl;
  final String altDescription;
  final String author;

  Photo({
    required this.id,
    required this.thumbUrl,
    required this.fullUrl,
    required this.altDescription,
    required this.author,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    final urls = (json['urls'] as Map?) ?? {};
    final user = (json['user'] as Map?) ?? {};
    return Photo(
      id: (json['id'] ?? '') as String,
      thumbUrl: (urls['small'] ?? '') as String,
      fullUrl: (urls['regular'] ?? '') as String,
      altDescription: (json['alt_description'] ?? '').toString().trim(),
      author: (user['name'] ?? 'Unknown').toString().trim(),
    );
  }
}
