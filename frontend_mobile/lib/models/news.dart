/// Modello articolo news (GET /news).
class NewsModel {
  final int id;
  final String title;
  final String? summary;
  final String? url;
  final String? source;
  final String? imageUrl;
  final DateTime? publishedAt;

  const NewsModel({
    required this.id,
    required this.title,
    this.summary,
    this.url,
    this.source,
    this.imageUrl,
    this.publishedAt,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] as int,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      url: json['url'] as String?,
      source: json['source'] as String?,
      imageUrl: json['image_url'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
    );
  }
}

/// Dettaglio articolo da GET /news/article?url=...
class ArticleDetailModel {
  final String title;
  final String subtitle;
  final String author;
  final String date;
  final String imageUrl;
  final String bodyHtml;

  const ArticleDetailModel({
    this.title = '',
    this.subtitle = '',
    this.author = '',
    this.date = '',
    this.imageUrl = '',
    this.bodyHtml = '',
  });

  factory ArticleDetailModel.fromJson(Map<String, dynamic> json) {
    return ArticleDetailModel(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      author: json['author'] as String? ?? '',
      date: json['date'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      bodyHtml: json['body_html'] as String? ?? '',
    );
  }
}
