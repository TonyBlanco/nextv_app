/// Application strings and translations
class AppStrings {
  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'es': 'Español',
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'it': 'Italiano',
  };

  // Alias for languages
  static Map<String, String> get languages => supportedLanguages;

  // Translation map
  static const Map<String, Map<String, String>> _translations = {
    'settings': {'es': 'Configuración', 'en': 'Settings', 'fr': 'Paramètres'},
    'language': {'es': 'Idioma', 'en': 'Language', 'fr': 'Langue'},
    'search': {'es': 'Buscar...', 'en': 'Search...', 'fr': 'Rechercher...'},
    'player_selection': {'es': 'Reproductor', 'en': 'Player', 'fr': 'Lecteur'},
    'stream_format': {'es': 'Formato de Stream', 'en': 'Stream Format', 'fr': 'Format du flux'},
    'external_player': {'es': 'Reproductor Externo', 'en': 'External Player', 'fr': 'Lecteur externe'},
    'account': {'es': 'Cuenta', 'en': 'Account', 'fr': 'Compte'},
    'loading': {'es': 'Cargando...', 'en': 'Loading...', 'fr': 'Chargement...'},
    'error': {'es': 'Error', 'en': 'Error', 'fr': 'Erreur'},
    'retry': {'es': 'Reintentar', 'en': 'Retry', 'fr': 'Réessayer'},
    'cancel': {'es': 'Cancelar', 'en': 'Cancel', 'fr': 'Annuler'},
    'ok': {'es': 'OK', 'en': 'OK', 'fr': 'OK'},
    'save': {'es': 'Guardar', 'en': 'Save', 'fr': 'Sauvegarder'},
    'favorites': {'es': 'Favoritos', 'en': 'Favorites', 'fr': 'Favoris'},
    'recent': {'es': 'Recientes', 'en': 'Recent', 'fr': 'Récents'},
  };

  // Get translated string
  static String get(String key, [String locale = 'es']) {
    final translations = _translations[key];
    if (translations == null) return key;
    return translations[locale] ?? translations['es'] ?? key;
  }

  // General
  static const String appName = 'NeXtv';
  static const String noChannels = 'No hay canales disponibles';
  static const String noConnection = 'Sin conexión';
  static const String loadingChannels = 'Cargando canales...';
}
