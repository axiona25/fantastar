/// Parsing sicuro da JSON: l'API può inviare numeri come String.
double? toDoubleSafe(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

double toDoubleSafeOrDefault(dynamic v, double def) => toDoubleSafe(v) ?? def;

int? toIntSafe(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

int toIntSafeOrDefault(dynamic v, int def) => toIntSafe(v) ?? def;
