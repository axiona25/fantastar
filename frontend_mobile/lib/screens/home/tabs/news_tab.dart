import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/news.dart';
import '../../../services/news_service.dart';
import '../../../utils/error_utils.dart';
import '../../../widgets/news_placeholder_image.dart';
import '../../../app/constants.dart';

String _articleImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
  return '$kBackendOrigin$imageUrl';
}

class NewsTab extends StatefulWidget {
  const NewsTab({super.key});

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  List<NewsModel> _articles = [];
  List<String> _sources = [];
  String? _selectedSource;
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final newsService = context.read<NewsService>();
      final sources = await newsService.getSources();
      final articles = await newsService.getNews(source: _selectedSource);
      if (mounted) {
        setState(() {
          _sources = sources;
          _articles = articles;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFriendlyErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_sources.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tutte'),
                    selected: _selectedSource == null,
                    onSelected: (_) {
                      setState(() => _selectedSource = null);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._sources.map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s),
                          selected: _selectedSource == s,
                          onSelected: (_) {
                            setState(() => _selectedSource = s);
                            _load();
                          },
                        ),
                      )),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ..._articles.map((a) => _NewsCard(article: a, onReturnFromDetail: _load)),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article, required this.onReturnFromDetail});

  final NewsModel article;
  final VoidCallback onReturnFromDetail;

  static const double _imageHeight = 180;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _articleImageUrl(article.imageUrl);
    final hasImage = imageUrl.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final url = article.url;
          if (url != null && url.isNotEmpty) {
            await context.push('/news/${article.id}', extra: url);
            if (context.mounted) onReturnFromDetail();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _imageHeight,
              width: double.infinity,
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const NewsPlaceholderImage(height: _imageHeight),
                    )
                  : const NewsPlaceholderImage(height: _imageHeight),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (article.summary != null && article.summary!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.summary!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${article.source ?? ""} · ${article.publishedAt != null ? _formatDate(article.publishedAt!) : ""}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
