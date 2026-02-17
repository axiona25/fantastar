import '../app/constants.dart';

/// Nomi brevi per visualizzazione classifica (evitare troncamento "FC Internazionale Milano").
const Map<String, String> teamShortNames = {
  'FC Internazionale Milano': 'Inter',
  'Internazionale': 'Inter',
  'AC Milan': 'Milan',
  'SSC Napoli': 'Napoli',
  'Juventus FC': 'Juventus',
  'AS Roma': 'Roma',
  'SS Lazio': 'Lazio',
  'Atalanta BC': 'Atalanta',
  'ACF Fiorentina': 'Fiorentina',
  'Bologna FC 1909': 'Bologna',
  'Torino FC': 'Torino',
  'Genoa CFC': 'Genoa',
  'Cagliari Calcio': 'Cagliari',
  'Empoli FC': 'Empoli',
  'Como 1907': 'Como',
  'Hellas Verona FC': 'Verona',
  'Hellas Verona': 'Verona',
  'Parma Calcio 1913': 'Parma',
  'US Lecce': 'Lecce',
  'Venezia FC': 'Venezia',
  'AC Monza': 'Monza',
  'Udinese Calcio': 'Udinese',
  // Nomi seed DB (short)
  'Inter': 'Inter',
  'Milan': 'Milan',
  'Napoli': 'Napoli',
  'Juventus': 'Juventus',
  'Roma': 'Roma',
  'Lazio': 'Lazio',
  'Atalanta': 'Atalanta',
  'Fiorentina': 'Fiorentina',
  'Bologna': 'Bologna',
  'Torino': 'Torino',
  'Genoa': 'Genoa',
  'Cagliari': 'Cagliari',
  'Empoli': 'Empoli',
  'Como': 'Como',
  'Verona': 'Verona',
  'Parma': 'Parma',
  'Lecce': 'Lecce',
  'Venezia': 'Venezia',
  'Monza': 'Monza',
  'Udinese': 'Udinese',
  'Frosinone': 'Frosinone',
  'Salernitana': 'Salernitana',
};

/// Stemmi in backend/static/media/team_badges_serie_A/ sono 21.png ... 40.png.
/// Mappa: nome esatto squadra (DB/API) -> id file. Verificata con real_teams.id 21-40:
/// 21=AC Milan, 22=ACF Fiorentina, 23=AS Roma, 24=Atalanta BC, 25=Bologna FC 1909,
/// 26=Cagliari Calcio, 27=Genoa CFC, 28=FC Internazionale Milano, 29=Juventus FC,
/// 30=SS Lazio, 31=Parma, 32=SSC Napoli, 33=Udinese, 34=Hellas Verona, 35=US Cremonese,
/// 36=US Sassuolo Calcio, 37=AC Pisa 1909, 38=Torino FC, 39=US Lecce, 40=Como 1907.
const Map<String, String> teamBadgeIds = {
  'AC Milan': '21',
  'Milan': '21',
  'ACF Fiorentina': '22',
  'Fiorentina': '22',
  'AS Roma': '23',
  'Roma': '23',
  'Atalanta BC': '24',
  'Atalanta': '24',
  'Bologna FC 1909': '25',
  'Bologna': '25',
  'Cagliari Calcio': '26',
  'Cagliari': '26',
  'Genoa CFC': '27',
  'Genoa': '27',
  'FC Internazionale Milano': '28',
  'Internazionale': '28',
  'Inter': '28',
  'Juventus FC': '29',
  'Juventus': '29',
  'SS Lazio': '30',
  'Lazio': '30',
  'Parma Calcio 1913': '31',
  'Parma': '31',
  'SSC Napoli': '32',
  'Napoli': '32',
  'Udinese Calcio': '33',
  'Udinese': '33',
  'Hellas Verona FC': '34',
  'Hellas Verona': '34',
  'Verona': '34',
  'US Cremonese': '35',
  'Cremonese': '35',
  'US Sassuolo Calcio': '36',
  'Sassuolo': '36',
  'AC Pisa 1909': '37',
  'Pisa': '37',
  'Torino FC': '38',
  'Torino': '38',
  'US Lecce': '39',
  'Lecce': '39',
  'Como 1907': '40',
  'Como': '40',
  'Empoli FC': '21',
  'Empoli': '21',
  'Frosinone': '21',
  'Salernitana': '21',
  'Venezia FC': '21',
  'Venezia': '21',
  'AC Monza': '21',
  'Monza': '21',
};

String getShortName(String fullName) {
  if (fullName.isEmpty) return fullName;
  return teamShortNames[fullName] ?? fullName;
}

/// URL stemma Serie A (static/media/team_badges_serie_A/{id}.png).
/// Ritorna '' se squadra non in mappa (UI mostrerà iniziale).
String getTeamBadgeUrl(String fullName) {
  final id = teamBadgeIds[fullName];
  if (id == null || id.isEmpty) return '';
  final base = Uri.parse(kApiBaseUrl).origin;
  return '$base/static/media/team_badges_serie_A/$id.png';
}
