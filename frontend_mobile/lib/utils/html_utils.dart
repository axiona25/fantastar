/// Pulizia testo da tag HTML e entities (titoli/summary news).
/// Usare prima di mostrare title/summary/subtitle da API.

String cleanHtml(String text) {
  if (text.isEmpty) return text;
  // Rimuovi tutti i tag HTML
  String s = text.replaceAll(RegExp(r'<[^>]*>'), '');
  // Decodifica entities comuni
  s = s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&rsquo;', "'")
      .replaceAll('&lsquo;', "'")
      .replaceAll('&rdquo;', '"')
      .replaceAll('&ldquo;', '"')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&egrave;', 'è')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&agrave;', 'à')
      .replaceAll('&ograve;', 'ò')
      .replaceAll('&ugrave;', 'ù')
      .replaceAll('&igrave;', 'ì')
      .replaceAll('&#8217;', "'")
      .replaceAll('&#8216;', "'");
  // Rimuovi spazi multipli
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}
