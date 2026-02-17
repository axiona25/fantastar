import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../models/fantasy_league.dart';
import '../../models/news.dart';
import '../../models/standing_row.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/news_service.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/team_utils.dart';
import '../../utils/html_utils.dart';
import '../../widgets/league_logo.dart';
import '../../widgets/news_placeholder_image.dart';
import '../../widgets/spot_carousel.dart';

/// Home principale: header, promo carousel, leghe, news, classifica.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _newsScrollController = ScrollController();
  int _newsPage = 0;
  static const _newsCardWidth = 280.0;
  static const _newsCardGap = 12.0;
  static const _newsLimit = 15;
  Timer? _newsCarouselTimer;
  Timer? _newsRefreshTimer;
  List<NewsModel> _newsArticles = [];
  bool _newsLoading = true;
  String? _newsError;
  List<StandingRow> _standings = [];
  String? _standingsError;

  @override
  void initState() {
    super.initState();
    _newsScrollController.addListener(_onNewsScroll);
    _loadNews();
    _startNewsCarouselTimer();
    _newsRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (mounted) _loadNews();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().load();
      _loadStandings();
    });
  }

  Future<void> _loadStandings() async {
    if (mounted) setState(() => _standingsError = null);
    try {
      final list = await context.read<StatsService>().getStandings();
      if (mounted) setState(() => _standings = list);
    } catch (_) {
      if (mounted) setState(() {
        _standings = [];
        _standingsError = 'error';
      });
    }
  }

  /// Colore posizione: 1-4 blu Champions, 5-6 arancione Europa, 18-20 rosso retrocessione.
  static Color _positionColor(int position) {
    if (position >= 1 && position <= 4) return AppColors.primary;
    if (position >= 5 && position <= 6) return Colors.orange.shade700;
    if (position >= 18 && position <= 20) return Colors.red.shade700;
    return AppColors.textDark;
  }

  Future<void> _loadNews() async {
    if (mounted) setState(() { _newsLoading = true; _newsError = null; });
    try {
      debugPrint('News: fetching from API (limit: $_newsLimit)...');
      final newsService = context.read<NewsService>();
      final list = await newsService.getNews(limit: _newsLimit);
      debugPrint('News: got ${list.length} items from API');
      if (mounted) {
        setState(() {
          _newsArticles = _filterSerieANews(list);
          _newsLoading = false;
          _newsError = null;
        });
      }
    } catch (e, st) {
      debugPrint('News: error $e');
      debugPrint('News: stack $st');
      if (mounted) {
        setState(() {
          _newsArticles = [];
          _newsLoading = false;
          _newsError = 'error';
        });
      }
    }
  }

  /// Filtro client-side Serie A maschile (stesso criterio del backend).
  static List<NewsModel> _filterSerieANews(List<NewsModel> list) {
    const exclude = ['women', 'femminile', 'serie a women', 'serie b', 'serie c', 'primavera'];
    const include = [
      'serie a', 'campionato',
      'napoli', 'inter', 'milan', 'juventus', 'atalanta', 'lazio', 'roma',
      'fiorentina', 'bologna', 'torino', 'genoa', 'cagliari', 'empoli', 'como',
      'verona', 'parma', 'lecce', 'venezia', 'monza', 'udinese',
    ];
    return list.where((a) {
      final text = '${a.title} ${a.summary ?? ""}'.toLowerCase();
      if (exclude.any((ex) => text.contains(ex))) return false;
      return include.any((inc) => text.contains(inc));
    }).toList();
  }

  void _onNewsScroll() {
    if (!_newsScrollController.hasClients || _newsArticles.isEmpty) return;
    final offset = _newsScrollController.offset;
    final maxPage = (_newsArticles.length - 1).clamp(0, _newsLimit - 1);
    final page = (offset / (_newsCardWidth + _newsCardGap)).round().clamp(0, maxPage);
    if (page != _newsPage && mounted) setState(() => _newsPage = page);
  }

  void _startNewsCarouselTimer() {
    _newsCarouselTimer?.cancel();
    _newsCarouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _newsArticles.isEmpty || !_newsScrollController.hasClients) return;
      final maxPage = (_newsArticles.length - 1).clamp(0, _newsLimit - 1);
      if (maxPage <= 0) return;
      final nextPage = (_newsPage + 1) % (_newsArticles.length);
      final targetOffset = nextPage * (_newsCardWidth + _newsCardGap);
      _newsScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      if (mounted) setState(() => _newsPage = nextPage);
    });
  }

  @override
  void dispose() {
    _newsCarouselTimer?.cancel();
    _newsRefreshTimer?.cancel();
    _newsScrollController.removeListener(_onNewsScroll);
    _newsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SpotCarousel(),
          _buildMieLegheSection(),
          _buildNewsSection(),
          _buildClassificaSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ciao, ${context.watch<AuthProvider>().user?.username ?? 'Marco'}',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 64,
            width: 64,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 64,
                width: 64,
                decoration: const BoxDecoration(
                  color: AppColors.inputBorder,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, color: AppColors.textGrey, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMieLegheSection() {
    final home = context.watch<HomeProvider>();
    final leagues = home.leagues;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Le mie Leghe',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/leagues/new'),
                child: Text(
                  '+ Crea Lega',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Card contenitore — placeholder se nessuna lega, altrimenti box leghe
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: leagues.isEmpty
                ? _buildEmptyLeaguePlaceholder()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: leagues.map((league) => _buildLeagueSquareCard(league)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Placeholder quando non ci sono leghe: invita a creare la prima (tappabile → Crea Lega).
  Widget _buildEmptyLeaguePlaceholder() {
    return GestureDetector(
      onTap: () => context.push('/leagues/new'),
      child: SizedBox(
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E8F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFB0BEC5),
                  width: 1.5,
                ),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 24, color: Color(0xFF0D47A1)),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: CircleAvatar(
                      radius: 7,
                      backgroundColor: Color(0xFF0D47A1),
                      child: Icon(Icons.add, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Non hai ancora nessuna lega',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5C6B7A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tocca + Crea Lega per iniziare',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// URL stemma lega da backend (come league_detail_screen).
  String _leagueBadgeUrl(FantasyLeagueModel league) {
    final logo = league.logo;
    if (logo.startsWith('http')) return logo;
    if (logo.startsWith('/static/') || logo.contains('league_badges')) {
      return '$kBackendOrigin${logo.startsWith('/') ? logo : '/$logo'}';
    }
    if (RegExp(r'^badge_\d{2}$').hasMatch(logo)) {
      return '$kBackendOrigin/static/media/league_badges/3d/$logo.png';
    }
    return '';
  }

  /// Box quadrato singola lega: card interna grigio-blu + stemma + nome, tap → dettaglio lega.
  Widget _buildLeagueSquareCard(FantasyLeagueModel league) {
    final badgeUrl = _leagueBadgeUrl(league);
    return GestureDetector(
      onTap: () => context.push('/league/${league.id}'),
      child: Container(
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: badgeUrl.isNotEmpty
                      ? Image.network(
                          badgeUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.shield,
                            size: 30,
                            color: Color(0xFF0D47A1),
                          ),
                        )
                      : LeagueLogo(logoKey: league.logo, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              league.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _newsImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
    return '$kBackendOrigin$imageUrl';
  }

  static String _formatNewsDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('d MMM yyyy', 'it').format(d);
  }

  Widget _buildNewsSection() {
    final count = _newsArticles.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'News',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: _newsLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : (_newsError != null || count == 0)
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.newspaper_outlined, size: 40, color: AppColors.textGrey),
                              const SizedBox(height: 12),
                              Text(
                                'News non disponibili',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_newsError != null) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _loadNews,
                                  child: Text(
                                    'Riprova',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                    controller: _newsScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: count,
                    itemBuilder: (context, i) {
                      final article = _newsArticles[i];
                      final imageUrl = _newsImageUrl(article.imageUrl);
                      final hasImage = imageUrl.isNotEmpty;
                      return Padding(
                        padding: EdgeInsets.only(right: i < count - 1 ? _newsCardGap : 0),
                        child: SizedBox(
                          width: _newsCardWidth,
                          child: InkWell(
                            onTap: () {
                              final url = article.url;
                              if (url != null && url.isNotEmpty) {
                                context.push('/news/${article.id}', extra: url);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 120,
                                    width: double.infinity,
                                    child: hasImage
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const NewsPlaceholderImage(height: 120),
                                          )
                                        : const NewsPlaceholderImage(height: 120),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      cleanHtml(article.title),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                    child: Text(
                                      _formatNewsDate(article.publishedAt),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (count > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                count,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _newsPage ? AppColors.primary : AppColors.textGrey.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _standingsLogoUrl(String? crest) {
    if (crest == null || crest.isEmpty) return '';
    if (crest.startsWith('http://') || crest.startsWith('https://')) return crest;
    return '$kBackendOrigin$crest';
  }

  String _standingsBadgeUrl(StandingRow r) {
    final local = getTeamBadgeUrl(r.teamName);
    if (local.isNotEmpty) return local;
    return _standingsLogoUrl(r.crest);
  }

  Widget _buildClassificaSection() {
    final top5 = _standings.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Classifica Serie A',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push('/standings/serie-a'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    'Completa >',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _standingsError != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Classifica non disponibile',
                            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _loadStandings,
                            child: Text('Riprova', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  )
                : top5.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Nessun dato classifica',
                            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
                          ),
                        ),
                      )
                    : Column(
                    children: [
                      // Header colonne: testo grigio 10px
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(width: 28, child: Text('', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey), textAlign: TextAlign.center)),
                            const SizedBox(width: 36),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Squadra', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey))),
                            SizedBox(width: 24, child: Center(child: Text('G', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                            SizedBox(width: 24, child: Center(child: Text('V', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                            SizedBox(width: 20, child: Center(child: Text('P', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                            SizedBox(width: 20, child: Center(child: Text('S', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                            SizedBox(width: 28, child: Center(child: Text('GF', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                            SizedBox(width: 28, child: Center(child: Text('GS', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                            SizedBox(width: 32, child: Text('Pts', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey), textAlign: TextAlign.right)),
                          ],
                        ),
                      ),
                      ...List.generate(top5.length, (i) {
                        final r = top5[i];
                        final logoUrl = _standingsBadgeUrl(r);
                        final posColor = _positionColor(r.position);
                        final initial = getShortName(r.teamName).isNotEmpty ? getShortName(r.teamName).substring(0, 1).toUpperCase() : '?';
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (i > 0) Divider(height: 1, color: AppColors.inputBorder.withOpacity(0.6)),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${r.position}',
                                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: posColor),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    child: Center(
                                      child: logoUrl.isEmpty
                                          ? SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircleAvatar(
                                                backgroundColor: Colors.white,
                                                child: Text(
                                                  initial,
                                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                                                ),
                                              ),
                                            )
                                          : Image.network(
                                              logoUrl,
                                              width: 28,
                                              height: 28,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => SizedBox(
                                                width: 28,
                                                height: 28,
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.white,
                                                  child: Text(
                                                    initial,
                                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      getShortName(r.teamName),
                                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 24, child: Text('${r.played}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                                  SizedBox(width: 24, child: Text('${r.won}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                                  SizedBox(width: 20, child: Text('${r.draw}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                                  SizedBox(width: 20, child: Text('${r.lost}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                                  SizedBox(width: 28, child: Text('${r.goalsFor}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                                  SizedBox(width: 28, child: Text('${r.goalsAgainst}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${r.points}',
                                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
