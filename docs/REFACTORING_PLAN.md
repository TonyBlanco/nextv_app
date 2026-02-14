# 🔧 Plan de Refactoring - NexTV App

**Versión:** 1.0  
**Fecha:** Febrero 2026  
**Estado:** 🔴 PENDIENTE  
**Prioridad:** ALTA

---

## 📊 Resumen Ejecutivo

Basado en la auditoría técnica, se identificaron las siguientes áreas críticas que requieren refactoring para mejorar la mantenibilidad, escalabilidad y calidad del código.

**Tiempo estimado total:** 3-4 semanas  
**Impacto esperado:** Mejora del 30-40% en mantenibilidad y performance

---

## 🎯 Objetivos Principales

1. **Reducir complejidad** del código crítico
2. **Mejorar testabilidad** con interfaces y dependency injection
3. **Aumentar cobertura de tests** del 15% al 70%
4. **Implementar security best practices**
5. **Optimizar performance** de listas y carga de datos
6. **Eliminar código duplicado** y magic numbers

---

## 📋 Sprint 1: Seguridad Crítica (Semana 1)

### 🔴 Prioridad 1: Encriptar Credenciales

**Problema:** Credenciales almacenadas en plain text en SharedPreferences

**Solución:** Migrar a flutter_secure_storage

**Archivos afectados:**
- `lib/core/services/auth_service.dart`
- `lib/core/services/storage_service.dart` (crear)

**Pasos:**

1. Instalar dependencia
```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.2.2
```

2. Crear StorageService wrapper
```dart
// lib/core/services/storage_service.dart
class StorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  // Datos sensibles → Secure Storage
  Future<void> saveCredentials(Credentials creds) async {
    await _secureStorage.write(key: 'username', value: creds.username);
    await _secureStorage.write(key: 'password', value: creds.password);
    await _secureStorage.write(key: 'server_url', value: creds.serverUrl);
  }

  // Datos no sensibles → SharedPreferences
  Future<void> saveSetting(String key, String value) async {
    await _prefs.setString(key, value);
  }
}
```

3. Migrar datos existentes
```dart
Future<void> migrateCredentials() async {
  // Leer de SharedPreferences
  final username = _prefs.getString('username');
  final password = _prefs.getString('password');
  
  if (username != null && password != null) {
    // Guardar en SecureStorage
    await _secureStorage.write(key: 'username', value: username);
    await _secureStorage.write(key: 'password', value: password);
    
    // Limpiar de SharedPreferences
    await _prefs.remove('username');
    await _prefs.remove('password');
  }
}
```

**Testing:**
- Unit tests para StorageService
- Integration test de migración
- Verificar en iOS y Android

**Estimado:** 2 días

---

### 🔴 Prioridad 2: Implementar Code Obfuscation

**Problema:** Código fácilmente decompilable

**Solución:** Habilitar obfuscation en builds

**Pasos:**

1. Actualizar scripts de build
```bash
# build-all.ps1
flutter build apk --release --obfuscate --split-debug-info=debug-info/
flutter build ios --release --obfuscate --split-debug-info=debug-info/
```

2. Guardar symbols para crash reporting
```yaml
# .gitignore
debug-info/
```

3. Configurar ProGuard adicional (Android)
```proguard
# android/app/proguard-rules.pro
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
```

**Estimado:** 1 día

---

### 🟡 Prioridad 3: Implementar HTTPS Enforcement

**Problema:** App acepta HTTP sin advertir

**Solución:** Detectar y advertir sobre conexiones inseguras

**Archivo:** `lib/presentation/screens/login/login_screen.dart`

```dart
Future<bool> _validateServerUrl(String url) async {
  if (url.startsWith('http://') && !kDebugMode) {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Conexión Insegura'),
        content: const Text(
          'El servidor usa HTTP no encriptado.\n\n'
          'Tus credenciales pueden ser interceptadas.\n\n'
          '¿Deseas continuar de todos modos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar (No Recomendado)'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    ) ?? false;
  }
  return true;
}
```

**Estimado:** 1 día

---

## 📋 Sprint 2: Refactoring de Arquitectura (Semana 2)

### 🟡 Prioridad 4: Dividir XtreamAPIService (God Class)

**Problema:** 466 líneas, demasiadas responsabilidades

**Solución:** Dividir en servicios especializados

**Estructura propuesta:**
```
lib/core/services/xtream/
├── xtream_auth_service.dart       # Autenticación
├── xtream_live_service.dart       # Live TV
├── xtream_vod_service.dart        # Movies
├── xtream_series_service.dart     # Series
├── xtream_epg_service.dart        # EPG
└── xtream_base_service.dart       # Lógica común
```

**Implementación:**

```dart
// lib/core/services/xtream/xtream_base_service.dart
abstract class XtreamBaseService {
  final Dio dio;
  final String serverUrl;
  final String username;
  final String password;

  XtreamBaseService({
    required this.dio,
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  String buildUrl(String endpoint, [Map<String, dynamic>? params]) {
    // Lógica común de construcción de URLs
  }

  Future<T> makeRequest<T>(String endpoint, T Function(dynamic) parser) async {
    // Lógica común de requests
  }
}

// lib/core/services/xtream/xtream_live_service.dart
class XtreamLiveService extends XtreamBaseService {
  XtreamLiveService({
    required super.dio,
    required super.serverUrl,
    required super.username,
    required super.password,
  });

  Future<List<LiveStream>> fetchLiveStreams() async {
    return makeRequest(
      'get_live_streams',
      (data) => (data as List).map((e) => LiveStream.fromJson(e)).toList(),
    );
  }

  Future<List<Category>> fetchLiveCategories() async {
    // ...
  }
}
```

**Testing:**
- Unit tests para cada servicio nuevo
- Integration tests del flujo completo
- Verificar que no hay regresiones

**Estimado:** 3 días

---

### 🟡 Prioridad 5: Implementar Repository Pattern

**Problema:** Servicios mezclan lógica de negocio con acceso a datos

**Solución:** Capa de Repository + Interfaces

**Estructura:**
```
lib/core/repositories/
├── playlist_repository.dart          # Interface
├── playlist_repository_impl.dart     # Implementación
├── favorites_repository.dart
└── favorites_repository_impl.dart
```

**Ejemplo:**

```dart
// lib/core/repositories/playlist_repository.dart
abstract class PlaylistRepository {
  Future<List<Playlist>> getPlaylists();
  Future<void> savePlaylist(Playlist playlist);
  Future<void> deletePlaylist(String id);
  Future<Playlist?> getPlaylistById(String id);
}

// lib/core/repositories/playlist_repository_impl.dart
class PlaylistRepositoryImpl implements PlaylistRepository {
  final StorageService _storage;

  PlaylistRepositoryImpl(this._storage);

  @override
  Future<List<Playlist>> getPlaylists() async {
    final data = await _storage.getPlaylists();
    return data.map((e) => Playlist.fromJson(e)).toList();
  }

  // ... otras implementaciones
}

// Provider
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PlaylistRepositoryImpl(storage);
});
```

**Beneficios:**
- Fácil testing con mocks
- Fácil cambio de implementación (ej: SharedPreferences → Hive)
- Separación clara de responsabilidades

**Estimado:** 2 días

---

### 🟢 Prioridad 6: Centralizar Constantes

**Problema:** Magic numbers y strings dispersos

**Solución:** Archivos de constantes centralizados

```dart
// lib/core/config/app_constants.dart
class AppConstants {
  // Network
  static const networkTimeout = Duration(seconds: 30);
  static const maxRetries = 3;
  static const retryDelay = Duration(seconds: 2);

  // Storage Keys
  static const keyUsername = 'username';
  static const keyPassword = 'password';
  static const keyServerUrl = 'server_url';
  
  // Pagination
  static const defaultPageSize = 100;
  static const maxPageSize = 500;
  
  // Cache
  static const imageCacheMaxAge = Duration(days: 7);
  static const dataCacheMaxAge = Duration(hours: 24);
}

// lib/core/config/app_strings.dart
class AppStrings {
  static const appName = 'NeXtv';
  static const loginTitle = 'Iniciar Sesión';
  static const errorGeneric = 'Ha ocurrido un error';
  // ...
}

// lib/core/config/app_theme.dart
class AppTheme {
  static const primaryColor = Color(0xFF1E88E5);
  static const accentColor = Color(0xFFFF6F00);
  // ...
}
```

**Estimado:** 1 día

---

## 📋 Sprint 3: Testing y Calidad (Semana 3)

### 🔴 Prioridad 7: Aumentar Cobertura de Tests

**Objetivo:** Del 15% actual al 70%

**Plan:**

1. **Tests de Modelos (1 día)**
   - LiveStream
   - VODInfo
   - SeriesInfo
   - Category
   - Playlist
   - Credentials

2. **Tests de Servicios (2 días)**
   - XtreamAuthService
   - XtreamLiveService
   - FavoritesService
   - StorageService
   - EPGService

3. **Tests de Providers (1 día)**
   - authProvider
   - liveStreamsProvider
   - favoritesProvider
   - categoriesProvider

4. **Widget Tests (2 días)**
   - LoginScreen
   - ChannelCard
   - CategoryGrid
   - PlayerControls
   - SearchBar

5. **Integration Tests (1 día)**
   - Flujo de login
   - Flujo de reproducción
   - Flujo de favoritos

**Herramientas:**
```yaml
dev_dependencies:
  mockito: ^5.4.4
  mocktail: ^1.0.3
  flutter_test:
    sdk: flutter
```

**Ejemplo de Mock:**
```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([XtreamLiveService, StorageService])
void main() {
  late MockXtreamLiveService mockService;
  
  setUp(() {
    mockService = MockXtreamLiveService();
  });

  test('should return live streams', () async {
    when(mockService.fetchLiveStreams())
        .thenAnswer((_) async => [testLiveStream]);
    
    final result = await mockService.fetchLiveStreams();
    
    expect(result, hasLength(1));
    verify(mockService.fetchLiveStreams()).called(1);
  });
}
```

**Estimado:** 7 días

---

### 🟡 Prioridad 8: Implementar Error Handling Centralizado

**Problema:** Manejo inconsistente de errores

**Solución:** ErrorHandler global

```dart
// lib/core/error/error_handler.dart
class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is AuthenticationException) {
      return 'Credenciales inválidas';
    } else if (error is NetworkException) {
      return 'Error de conexión. Verifica tu internet.';
    } else {
      return 'Ha ocurrido un error inesperado';
    }
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de respuesta agotado';
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Petición cancelada';
      default:
        return 'Error de red';
    }
  }

  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Petición inválida';
      case 401:
        return 'No autorizado';
      case 403:
        return 'Acceso denegado';
      case 404:
        return 'Recurso no encontrado';
      case 500:
        return 'Error del servidor';
      case 503:
        return 'Servicio no disponible';
      default:
        return 'Error del servidor ($statusCode)';
    }
  }

  static void logError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      developer.log(
        error.toString(),
        error: error,
        stackTrace: stackTrace,
        level: Level.SEVERE.value,
      );
    }
    // En producción: enviar a crash reporting (Firebase Crashlytics)
  }
}

// Custom exceptions
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}
```

**Uso:**
```dart
try {
  await xtreamService.fetchLiveStreams();
} catch (e, stackTrace) {
  ErrorHandler.logError(e, stackTrace);
  final message = ErrorHandler.getErrorMessage(e);
  // Mostrar mensaje al usuario
}
```

**Estimado:** 1 día

---

## 📋 Sprint 4: Performance y Optimización (Semana 4)

### 🟡 Prioridad 9: Implementar Paginación

**Problema:** Carga de 30,000+ canales de una vez

**Solución:** Infinite scroll con paginación

```dart
// lib/presentation/providers/live_streams_paginated_provider.dart
@riverpod
class LiveStreamsPaginated extends _$LiveStreamsPaginated {
  static const _pageSize = 100;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  FutureOr<List<LiveStream>> build() async {
    return _fetchPage(0);
  }

  Future<List<LiveStream>> _fetchPage(int page) async {
    final service = ref.read(xtreamLiveServiceProvider);
    final streams = await service.fetchLiveStreams(
      page: page,
      pageSize: _pageSize,
    );
    
    _hasMore = streams.length == _pageSize;
    return streams;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    
    _currentPage++;
    state = await AsyncValue.guard(() async {
      final currentStreams = state.value ?? [];
      final newStreams = await _fetchPage(_currentPage);
      return [...currentStreams, ...newStreams];
    });
  }
}

// En el Widget
ListView.builder(
  controller: _scrollController,
  itemCount: streams.length + (_hasMore ? 1 : 0),
  itemBuilder: (context, index) {
    if (index == streams.length) {
      // Load more indicator
      _loadMore();
      return const CircularProgressIndicator();
    }
    return ChannelCard(stream: streams[index]);
  },
)
```

**Estimado:** 2 días

---

### 🟢 Prioridad 10: Implementar Debounce en Búsqueda

**Problema:** API calls en cada tecla presionada

**Solución:** Debounce de 500ms

```dart
// lib/presentation/widgets/search_bar.dart
class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  
  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  Timer? _debounce;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onSearchChanged,
      decoration: const InputDecoration(
        hintText: 'Buscar...',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}
```

**Estimado:** 0.5 días

---

### 🟢 Prioridad 11: Optimizar Imágenes

**Problema:** Imágenes de alta resolución sin resize

**Solución:** Resize automático con CachedNetworkImage

```dart
// lib/presentation/widgets/channel_thumbnail.dart
class ChannelThumbnail extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const ChannelThumbnail({
    required this.url,
    this.width = 120,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: (width * MediaQuery.of(context).devicePixelRatio).round(),
      memCacheHeight: (height * MediaQuery.of(context).devicePixelRatio).round(),
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.tv, color: Colors.grey),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
```

**Estimado:** 0.5 días

---

## 📋 Backlog (Futuro)

### Prioridad Baja - Implementar Según Necesidad

1. **Internacionalización (i18n)**
   - Soporte para inglés
   - Sistema flutter_intl
   - Estimado: 3 días

2. **Offline Mode Básico**
   - Cache de EPG
   - Favoritos sin conexión
   - Estimado: 5 días

3. **Certificate Pinning**
   - Validación SSL avanzada
   - Estimado: 3 días

4. **Analytics y Crash Reporting**
   - Firebase Analytics
   - Firebase Crashlytics
   - Estimado: 2 días

5. **Control Parental**
   - PIN de protección
   - Filtros de contenido
   - Estimado: 4 días

---

## 📊 Métricas de Éxito

### KPIs a medir después del refactoring:

1. **Cobertura de Tests:** 15% → 70%
2. **Complejidad Ciclomática:** 5.2 → < 4.0
3. **Tamaño Máximo de Clase:** 466 → < 300 líneas
4. **Issues de Seguridad:** 3 críticos → 0
5. **Tiempo de Startup:** 2.8s → < 2.5s (Android)
6. **Frame Jank Rate:** 3.2% → < 2%
7. **Build Time:** Establecer baseline y mejorar 10%

---

## ✅ Checklist de Implementación

### Antes de empezar:
- [ ] Crear branch `refactor/sprint-1-security`
- [ ] Backup de código actual
- [ ] Documentar estado actual con screenshots
- [ ] Crear issues en GitHub para tracking

### Durante implementación:
- [ ] Commits atómicos y descriptivos
- [ ] Tests para cada cambio
- [ ] Documentación inline actualizada
- [ ] Code reviews entre sprints

### Después de cada sprint:
- [ ] Merge a develop con PR
- [ ] Testing manual completo
- [ ] Actualizar CHANGELOG.md
- [ ] Medir métricas de mejora

---

## 🚀 Guía de Implementación

### 1. Preparación
```bash
git checkout -b refactor/sprint-1-security
git push -u origin refactor/sprint-1-security
```

### 2. Durante el sprint
```bash
# Commits frecuentes
git commit -m "refactor(security): implement secure storage service"
git commit -m "test(security): add tests for storage service"

# Push diario
git push origin refactor/sprint-1-security
```

### 3. Fin de sprint
```bash
# Create PR
gh pr create --title "Sprint 1: Security Critical Updates" \
  --body "Implements secure storage and code obfuscation"

# Después de aprobación
git checkout develop
git merge refactor/sprint-1-security
git push origin develop
```

---

## 📞 Contacto y Soporte

**Equipo de desarrollo:** dev@nextv.app  
**Revisor técnico:** Luis Blanco  
**Fecha de inicio:** TBD  
**Fecha estimada de fin:** Sprint 4 + 1 semana

---

**Última actualización:** Febrero 2026  
**Versión del documento:** 1.0
