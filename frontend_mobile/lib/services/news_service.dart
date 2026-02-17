import 'auth_service.dart';
import '../models/news.dart';
import 'public_api_client.dart';

class NewsService {
  NewsService(this.auth);

  final AuthService auth;

  /// Endpoint pubblico: nessun token JWT. Usa publicApiClient.
  Future<List<NewsModel>> getNews({String? source, int limit = 50}) async {
    final query = <String, dynamic>{'limit': limit};
    if (source != null && source.isNotEmpty) query['source'] = source;
    try {
      final response = await publicApiClient.get('/news', queryParameters: query);
      final list = response.data is List ? response.data as List : [];
      return list.map((e) => NewsModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getSources() async {
    final response = await publicApiClient.get('/news/sources');
    final list = response.data is List ? response.data as List : [];
    return list.map((e) => e as String).toList();
  }

  /// GET /news/article?url=... — contenuto articolo (endpoint pubblico).
  Future<ArticleDetailModel> getArticle(String articleUrl) async {
    final response = await publicApiClient.get<Map<String, dynamic>>(
      '/news/article',
      queryParameters: {'url': articleUrl},
    );
    return ArticleDetailModel.fromJson(response.data ?? {});
  }
}
