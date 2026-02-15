import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';

import '../../models/news.dart';
import '../../services/news_service.dart';
import '../../utils/error_utils.dart';

/// Articolo news in-app: GET /news/article?url=... e mostra titolo, autore, data, body HTML.
class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.articleUrl});

  /// URL dell'articolo (passato come extra dalla lista news).
  final String articleUrl;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  ArticleDetailModel? _article;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.articleUrl.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'URL mancante';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final article = await context.read<NewsService>().getArticle(widget.articleUrl);
      if (mounted) {
        setState(() {
          _article = article;
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
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Articolo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Articolo')),
        body: Center(child: Text(_error!)),
      );
    }
    final a = _article!;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          a.title.isEmpty ? 'Articolo' : a.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (a.imageUrl.isNotEmpty)
              Image.network(
                a.imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 120),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (a.title.isNotEmpty)
                    Text(
                      a.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  if (a.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      a.subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (a.author.isNotEmpty || a.date.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      [if (a.author.isNotEmpty) a.author, if (a.date.isNotEmpty) a.date]
                          .join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                  if (a.bodyHtml.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    HtmlWidget(
                      a.bodyHtml,
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
