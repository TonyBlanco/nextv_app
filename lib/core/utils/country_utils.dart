import '../../core/models/xtream_models.dart';

/// Common IPTV category name patterns:
///   "ES | Deportes"
///   "UK: News"
///   "US- Entertainment"
///   "[ES] Deportes"
///   "ES - Deportes"
///   "ES| Deportes"
///   "SPAIN | Deportes"
///
/// We extract the prefix before the separator as the "country code".

final _separatorPattern = RegExp(r'^([A-Za-z]{2,6})\s*[\|\-:]\s*');
final _bracketPattern = RegExp(r'^\[([A-Za-z]{2,4})\]\s*');

/// Extract a country/region code from a category name, or null if none found.
String? extractCountry(String categoryName) {
  final name = categoryName.trim();

  // Try bracket pattern first: [ES] Deportes
  final bracketMatch = _bracketPattern.firstMatch(name);
  if (bracketMatch != null) {
    return _normalizeCode(bracketMatch.group(1)!);
  }

  // Try separator pattern: ES | Deportes, UK: News, US- Sports
  final sepMatch = _separatorPattern.firstMatch(name);
  if (sepMatch != null) {
    return _normalizeCode(sepMatch.group(1)!);
  }

  return null;
}

/// Normalize country-like strings to a canonical form.
/// "SPAIN" -> "ES", "spain" -> "ES", "Es" -> "ES"
String _normalizeCode(String raw) {
  final upper = raw.toUpperCase();
  // Map full country names to 2-letter codes
  return _nameToCode[upper] ?? upper;
}

/// Map of common full/alternate names to ISO codes.
const _nameToCode = <String, String>{
  'SPAIN': 'ES',
  'ESPAÑA': 'ES',
  'FRANCE': 'FR',
  'GERMANY': 'DE',
  'ALEMANIA': 'DE',
  'ITALY': 'IT',
  'ITALIA': 'IT',
  'PORTUGAL': 'PT',
  'BRAZIL': 'BR',
  'BRASIL': 'BR',
  'MEXICO': 'MX',
  'MÉXICO': 'MX',
  'ARGENTINA': 'AR',
  'COLOMBIA': 'CO',
  'CHILE': 'CL',
  'PERU': 'PE',
  'PERÚ': 'PE',
  'VENEZUELA': 'VE',
  'ECUADOR': 'EC',
  'URUGUAY': 'UY',
  'PARAGUAY': 'PY',
  'BOLIVIA': 'BO',
  'CUBA': 'CU',
  'PANAMA': 'PA',
  'PANAMÁ': 'PA',
  'CANADA': 'CA',
  'CANADÁ': 'CA',
  'UNITED': 'US',
  'USA': 'US',
  'EEUU': 'US',
  'NEDERLAND': 'NL',
  'NETHERLANDS': 'NL',
  'BELGIUM': 'BE',
  'BÉLGICA': 'BE',
  'SWITZERLAND': 'CH',
  'SUIZA': 'CH',
  'AUSTRIA': 'AT',
  'POLAND': 'PL',
  'POLONIA': 'PL',
  'ROMANIA': 'RO',
  'RUMANIA': 'RO',
  'TURKEY': 'TR',
  'TURQUÍA': 'TR',
  'TURQUIA': 'TR',
  'RUSSIA': 'RU',
  'RUSIA': 'RU',
  'JAPAN': 'JP',
  'JAPÓN': 'JP',
  'CHINA': 'CN',
  'KOREA': 'KR',
  'COREA': 'KR',
  'INDIA': 'IN',
  'ARABIC': 'AR_LANG',
  'ÁRABE': 'AR_LANG',
  'ARAB': 'AR_LANG',
  'LATINO': 'LATAM',
  'LATINOAMERICA': 'LATAM',
  'LATAM': 'LATAM',
  'AFRICA': 'AF',
  'AFRIKA': 'AF',
  'CARIBBEAN': 'CARIB',
  'CARIBE': 'CARIB',
  'INTERNATIONAL': 'INTL',
  'INTER': 'INTL',
  'WORLD': 'INTL',
  'ADULT': 'XXX',
  'ADULTOS': 'XXX',
  'SPORTS': 'SPORT',
  'DEPORTES': 'SPORT',
};

/// Convert a 2-letter ISO country code to a flag emoji.
/// Uses Unicode regional indicator symbols: A=🇦 ... Z=🇿
String getCountryFlag(String code) {
  final upper = code.toUpperCase();

  // Special non-ISO codes
  switch (upper) {
    case 'LATAM': return '🌎';
    case 'INTL': return '🌍';
    case 'AR_LANG': return '🕌';
    case 'SPORT': return '⚽';
    case 'XXX': return '🔞';
    case 'AF': return '🌍';
    case 'CARIB': return '🏝️';
    case 'EU': return '🇪🇺';
  }

  // Standard 2-letter ISO codes → flag emoji
  if (upper.length == 2) {
    final base = 0x1F1E6 - 65; // Regional Indicator Symbol Letter A
    return String.fromCharCodes([
      base + upper.codeUnitAt(0),
      base + upper.codeUnitAt(1),
    ]);
  }

  return '🏳️';
}

/// Human-readable label for common codes.
String getCountryLabel(String code) {
  return _codeToLabel[code.toUpperCase()] ?? code.toUpperCase();
}

const _codeToLabel = <String, String>{
  'ES': 'España',
  'FR': 'France',
  'DE': 'Deutschland',
  'IT': 'Italia',
  'PT': 'Portugal',
  'BR': 'Brasil',
  'MX': 'México',
  'AR': 'Argentina',
  'CO': 'Colombia',
  'CL': 'Chile',
  'PE': 'Perú',
  'VE': 'Venezuela',
  'EC': 'Ecuador',
  'UY': 'Uruguay',
  'US': 'USA',
  'CA': 'Canada',
  'UK': 'UK',
  'GB': 'UK',
  'NL': 'Nederland',
  'BE': 'Belgium',
  'CH': 'Suiza',
  'AT': 'Austria',
  'PL': 'Poland',
  'RO': 'Romania',
  'TR': 'Türkiye',
  'RU': 'Россия',
  'JP': '日本',
  'CN': '中国',
  'KR': '한국',
  'IN': 'India',
  'LATAM': 'Latino',
  'INTL': 'Intl',
  'AR_LANG': 'عربي',
  'SPORT': 'Deportes',
  'XXX': 'Adult',
  'AF': 'Africa',
  'CARIB': 'Caribe',
  'EU': 'Europa',
};

/// Extract all unique country codes from a list of categories, sorted by frequency (most first).
List<String> extractAllCountries(List<LiveCategory> categories) {
  final countMap = <String, int>{};

  for (final cat in categories) {
    final code = extractCountry(cat.categoryName);
    if (code != null) {
      countMap[code] = (countMap[code] ?? 0) + 1;
    }
  }

  // Sort by frequency descending
  final sorted = countMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.map((e) => e.key).toList();
}

/// Filter categories by country code. Returns only categories whose name starts with the given country prefix.
List<LiveCategory> filterByCountry(List<LiveCategory> categories, String? countryCode) {
  if (countryCode == null) return categories;

  return categories.where((cat) {
    final code = extractCountry(cat.categoryName);
    return code == countryCode;
  }).toList();
}
