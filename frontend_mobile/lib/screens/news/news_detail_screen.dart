import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/news.dart';
import '../../services/news_service.dart';
import '../../utils/html_utils.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_utils.dart';
import '../../widgets/fantastar_background.dart';

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

  /// Formatta data da ISO o stringa raw → "16 feb 2026, 08:27".
  static String _formatArticleDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d != null) return DateFormat('d MMM yyyy, HH:mm', 'it').format(d);
    return raw;
  }

  /// Pulisce autore: rimuove "3 min" e simili attaccati al nome.
  static String _cleanAuthor(String? author) {
    if (author == null || author.isEmpty) return '';
    return author.replaceAll(RegExp(r'\d+\s*min\s*', caseSensitive: false), '').trim();
  }

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: FantastarBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textGrey),
                                ),
                              ),
                            )
                          : _buildContent(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header: indietro a sinistra, titolo "Fantastar News" centrato alla riga, logo a destra.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryDark, size: 24),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Fantastar News',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            width: 48,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article_outlined, color: AppColors.textGrey, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _imageCardHeight = 220;

  /// Contenuto: immagine in card stile spot, poi testo allineato ai margini come in home.
  Widget _buildContent(BuildContext context) {
    final a = _article!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (a.imageUrl.isNotEmpty) _buildImageCard(a.imageUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (a.title.isNotEmpty)
                  Text(
                    cleanHtml(a.title),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                if (a.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    cleanHtml(a.subtitle),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                Builder(builder: (context) {
                  final author = _cleanAuthor(a.author);
                  final dateStr = _formatArticleDate(a.date);
                  final line = [if (author.isNotEmpty) author, if (dateStr.isNotEmpty) dateStr].join(' · ');
                  if (line.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      line,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  );
                }),
                if (a.bodyHtml.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  HtmlWidget(
                    a.bodyHtml,
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                    customWidgetBuilder: (element) {
                      final name = element.localName?.toLowerCase();
                      if (name == 'img') {
                        return const SizedBox.shrink();
                      }
                      if (name == 'a') {
                        final text = element.text.trim();
                        if (text.isEmpty) return const SizedBox.shrink();
                        return Text(
                          text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card immagine come lo spot in home: margini 20, bordi arrotondati, ombra.
  Widget _buildImageCard(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: _imageCardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: _imageCardHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: _imageCardHeight,
            color: AppColors.background3,
            child: const Center(
              child: Icon(Icons.image_not_supported, color: AppColors.textGrey, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
