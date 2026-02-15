import 'auth_service.dart';
import '../models/news.dart';

class NewsService {
  NewsService(this.auth);

  final AuthService auth;

  Future<List<NewsModel>> getNews({String? source, int limit = 50}) async {
    final query = <String, dynamic>{'limit': limit};
    if (source != null && source.isNotEmpty) query['source'] = source;
    final response = await auth.dio.get('/news', queryParameters: query);
    final list = response.data is List ? response.data as List : [];
    return list.map((e) => NewsModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> getSources() async {
    final response = await auth.dio.get('/news/sources');
    final list = response.data is List ? response.data as List : [];
    return list.map((e) => e as String).toList();
  }

  /// GET /news/article?url=... — contenuto articolo per visualizzazione in-app.
  Future<ArticleDetailModel> getArticle(String articleUrl) async {
    final response = await auth.dio.get<Map<String, dynamic>>(
      '/news/article',
      queryParameters: {'url': articleUrl},
    );
    return ArticleDetailModel.fromJson(response.data ?? {});
  }
}
