import 'xtream_models.dart';

class Playlist {
  final String id;
  final String name;
  final String type; // 'xtream' or 'm3u'
  final String? serverUrl;
  final String? username;
  final String? password;
  final String? m3uUrl;
  final String? epgUrl;
  final String? fallbackUrl; // NUEVO: URL de respaldo para resiliencia
  final DateTime? lastUpdated; // NUEVO: Fecha de última actualización
  final List<String>? selectedTypes; // e.g. ['live','movies','series']
  final bool isActive; // NUEVO: Indica si es la playlist activa

  Playlist({
    required this.id,
    required this.name,
    required this.type,
    this.serverUrl,
    this.username,
    this.password,
    this.m3uUrl,
    this.epgUrl,
    this.fallbackUrl,
    this.lastUpdated,
    this.selectedTypes,
    this.isActive = false,
  });

  XtreamCredentials? get toXtreamCredentials {
    if (type == 'xtream' && serverUrl != null && username != null && password != null) {
      return XtreamCredentials(
        serverUrl: serverUrl!,
        username: username!,
        password: password!,
      );
    }
    return null;
  }

  // Helper para obtener la URL efectiva (primaria o fallback)
  String? get effectiveServerUrl => serverUrl ?? fallbackUrl;

  // Crear copia con campos actualizados
  Playlist copyWith({
    String? id,
    String? name,
    String? type,
    String? serverUrl,
    String? username,
    String? password,
    String? m3uUrl,
    String? epgUrl,
    String? fallbackUrl,
    DateTime? lastUpdated,
    List<String>? selectedTypes,
    bool? isActive,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      m3uUrl: m3uUrl ?? this.m3uUrl,
      epgUrl: epgUrl ?? this.epgUrl,
      fallbackUrl: fallbackUrl ?? this.fallbackUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'serverUrl': serverUrl,
    'username': username,
    'password': password,
    'm3uUrl': m3uUrl,
    'epgUrl': epgUrl,
    'fallbackUrl': fallbackUrl,
    'lastUpdated': lastUpdated?.toIso8601String(),
    'selectedTypes': selectedTypes,
    'isActive': isActive,
  };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      serverUrl: json['serverUrl'],
      username: json['username'],
      password: json['password'],
      m3uUrl: json['m3uUrl'],
      epgUrl: json['epgUrl'],
      fallbackUrl: json['fallbackUrl'],
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
      selectedTypes: json['selectedTypes'] != null ? List<String>.from(json['selectedTypes']) : null,
      isActive: json['isActive'] ?? false,
    );
  }
}
