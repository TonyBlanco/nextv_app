# 💎 Best Practices & Development Guidelines - NexTV App

**Versión:** 1.0  
**Fecha:** Febrero 2026  
**Tipo:** Guía de desarrollo

---

## 📚 Tabla de Contenidos

1. [Código Limpio](#código-limpio)
2. [Arquitectura](#arquitectura)
3. [Testing](#testing)
4. [Git y Commits](#git-y-commits)
5. [Performance](#performance)
6. [Seguridad](#seguridad)
7. [UI/UX](#uiux)
8. [Documentación](#documentación)

---

## 🧹 Código Limpio

### Nomenclatura

```dart
// ✅ CORRECTO

// Clases: PascalCase
class LiveStreamProvider extends StateNotifier<AsyncValue<List<LiveStream>>> {}
class XtreamAPIService {}

// Variables y funciones: camelCase
final liveStreams = <LiveStream>[];
Future<void> fetchLiveStreams() async {}

// Constantes: camelCase (no SCREAMING_SNAKE_CASE en Dart)
const maxRetries = 3;
const defaultTimeout = Duration(seconds: 30);

// Archivos: snake_case
// live_stream_provider.dart
// xtream_api_service.dart

// ❌ INCORRECTO
class live_stream_provider {}  // No snake_case en clases
final LiveStreams = [];         // No PascalCase en variables
const MAX_RETRIES = 3;          // No SCREAMING_SNAKE_CASE
```

### Formato de Código

```dart
// ✅ CORRECTO: Formato consistente
class LiveStreamCard extends StatelessWidget {
  final LiveStream stream;
  final VoidCallback? onTap;

  const LiveStreamCard({
    super.key,
    required this.stream,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          children: [
            ChannelThumbnail(url: stream.icon),
            Text(stream.name),
          ],
        ),
      ),
    );
  }
}

// ❌ INCORRECTO: Formato inconsistente
class LiveStreamCard extends StatelessWidget{
  final LiveStream stream;final VoidCallback? onTap;
  const LiveStreamCard({super.key,required this.stream,this.onTap,});
  @override Widget build(BuildContext context){return GestureDetector(onTap:onTap,child:Card(child:Column(children:[ChannelThumbnail(url:stream.icon),Text(stream.name),],),),);}
}
```

### Comentarios

```dart
// ✅ CORRECTO: Comentarios útiles y concisos

/// Fetches live streams from Xtream API with optional filters.
///
/// Returns a [Future] that completes with a list of [LiveStream]s.
/// Throws [NetworkException] if network request fails.
/// Throws [AuthenticationException] if credentials are invalid.
Future<List<LiveStream>> fetchLiveStreams({
  String? categoryId,
  int page = 0,
  int pageSize = 100,
}) async {
  // Build URL with pagination parameters
  final url = _buildUrl('get_live_streams', {
    'category_id': categoryId,
    'page': page,
    'size': pageSize,
  });

  // Make API request with timeout
  final response = await _dio.get(url).timeout(
    AppConstants.networkTimeout,
  );

  return _parseStreams(response.data);
}

// ❌ INCORRECTO: Comentarios obvios o desactualizados

// This function gets streams  ← Obvio por el nombre
Future<List<LiveStream>> fetchLiveStreams() async {
  final url = _buildUrl('get_live_streams');
  // TODO: Fix this later  ← No específico
  final response = await _dio.get(url);
  // Returns movies  ← Incorrecto, returna streams no movies
  return _parseStreams(response.data);
}
```

### Funciones Pequeñas

```dart
// ✅ CORRECTO: Funciones enfocadas y pequeñas

Future<void> loginUser() async {
  final credentials = await _getCredentials();
  _validateCredentials(credentials);
  final authData = await _authenticate(credentials);
  await _saveSession(authData);
  _navigateToHome();
}

Future<Credentials> _getCredentials() async {
  return Credentials(
    username: _usernameController.text,
    password: _passwordController.text,
    serverUrl: _serverController.text,
  );
}

void _validateCredentials(Credentials creds) {
  if (creds.username.isEmpty) throw ValidationException('Username required');
  if (creds.password.isEmpty) throw ValidationException('Password required');
  if (creds.serverUrl.isEmpty) throw ValidationException('Server required');
}

// ❌ INCORRECTO: Función gigante que hace muchas cosas

Future<void> loginUser() async {
  // 200 líneas de código mezclando:
  // - Validación
  // - Network calls
  // - State management
  // - Navigation
  // - Error handling
  // ...
}
```

---

## 🏗️ Arquitectura

### Clean Architecture

```
lib/
├── core/                      # Capa de negocio
│   ├── models/               # Modelos de datos
│   ├── repositories/         # Interfaces de repositories
│   ├── services/             # Servicios (implementan repositorios)
│   ├── providers/            # Riverpod providers
│   ├── config/               # Configuración global
│   └── utils/                # Utilidades
│
├── presentation/              # Capa de presentación
│   ├── screens/              # Pantallas completas
│   ├── widgets/              # Widgets reutilizables
│   ├── providers/            # UI state providers
│   └── theme/                # Theming
│
└── features/                  # Features modulares
    ├── auth/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── live_tv/
    ├── vod/
    └── series/
```

### Riverpod Best Practices

```dart
// ✅ CORRECTO: Provider con autoDispose

@riverpod
Future<List<LiveStream>> liveStreams(LiveStreamsRef ref) async {
  // Se dispose automáticamente cuando no hay listeners
  final service = ref.watch(xtreamLiveServiceProvider);
  return service.fetchLiveStreams();
}

// Uso en widgets
final streamsAsync = ref.watch(liveStreamsProvider);
streamsAsync.when(
  data: (streams) => ListView(children: ...),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error),
);

// ❌ INCORRECTO: Provider sin autoDispose que causa memory leaks

final liveStreamsProvider = FutureProvider<List<LiveStream>>((ref) async {
  // No hay .autoDispose, permanece en memoria
  final service = ref.read(xtreamLiveServiceProvider);
  return service.fetchLiveStreams();
});
```

### Separation of Concerns

```dart
// ✅ CORRECTO: Widget solo UI, Provider maneja lógica

@riverpod
class LiveStreamsList extends _$LiveStreamsList {
  @override
  Future<List<LiveStream>> build() async {
    final service = ref.watch(xtreamLiveServiceProvider);
    return service.fetchLiveStreams();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  void filter(String query) {
    // Lógica de filtrado
  }
}

class LiveStreamsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsync = ref.watch(liveStreamsListProvider);
    
    return Scaffold(
      body: streamsAsync.when(
        data: (streams) => _buildList(streams),
        loading: () => _buildLoading(),
        error: (error, _) => _buildError(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(liveStreamsListProvider.notifier).refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// ❌ INCORRECTO: Widget con lógica de negocio

class LiveStreamsScreen extends StatefulWidget {
  @override
  _LiveStreamsScreenState createState() => _LiveStreamsScreenState();
}

class _LiveStreamsScreenState extends State<LiveStreamsScreen> {
  List<LiveStream> _streams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStreams();  // ❌ Lógica en widget
  }

  Future<void> _fetchStreams() async {
    // ❌ Network calls en widget
    final service = XtreamAPIService();
    final streams = await service.fetchLiveStreams();
    setState(() {
      _streams = streams;
      _loading = false;
    });
  }
}
```

---

## 🧪 Testing

### Test Coverage Target: 70%+

```dart
// ✅ CORRECTO: Test completo con setup, act, assert

void main() {
  group('LiveStream Model', () {
    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'stream_id': 12345,
        'name': 'Test Channel',
        'stream_icon': 'http://test.com/icon.png',
      };

      // Act
      final stream = LiveStream.fromJson(json);

      // Assert
      expect(stream.streamId, 12345);
      expect(stream.name, 'Test Channel');
      expect(stream.streamIcon, 'http://test.com/icon.png');
    });

    test('should generate correct stream URL', () {
      // Arrange
      final stream = LiveStream(
        streamId: 123,
        name: 'Test',
        // ... otros campos
      );

      // Act
      final url = stream.getStreamUrl('http://server.com', 'user', 'pass');

      // Assert
      expect(url, contains('http://server.com'));
      expect(url, contains('/user/pass/'));
      expect(url, contains('123.'));
    });

    test('should handle null values gracefully', () {
      final json = {'stream_id': 123, 'name': 'Test'};
      
      expect(() => LiveStream.fromJson(json), returnsNormally);
    });
  });
}

// ❌ INCORRECTO: Test sin estructura ni contexto

void main() {
  test('test', () {
    final s = LiveStream.fromJson({'stream_id': 1});
    expect(s.streamId, 1);
  });
}
```

### Mock Dependencies

```dart
// ✅ CORRECTO: Usar mocks para isolar tests

@GenerateMocks([XtreamAPIService, StorageService])
void main() {
  late MockXtreamAPIService mockService;
  late MockStorageService mockStorage;
  late FavoritesProvider provider;

  setUp(() {
    mockService = MockXtreamAPIService();
    mockStorage = MockStorageService();
    provider = FavoritesProvider(mockService, mockStorage);
  });

  test('should add favorite successfully', () async {
    // Arrange
    when(mockStorage.saveFavorite(any))
        .thenAnswer((_) async => true);

    // Act
    await provider.toggleFavorite(123);

    // Assert
    expect(provider.isFavorite(123), isTrue);
    verify(mockStorage.saveFavorite(123)).called(1);
  });
}
```

### Widget Testing

```dart
testWidgets('ChannelCard displays channel name', (tester) async {
  // Arrange
  final channel = LiveStream(streamId: 1, name: 'Test Channel');

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: ChannelCard(channel: channel),
    ),
  );

  // Assert
  expect(find.text('Test Channel'), findsOneWidget);
  expect(find.byType(CachedNetworkImage), findsOneWidget);
});
```

---

## 🔄 Git y Commits

### Commit Message Format

```bash
# ✅ CORRECTO: Conventional Commits

feat(player): add live TV indicator badge
fix(auth): resolve login timeout issue
docs(readme): update installation instructions
style(ui): improve spacing in channel grid
refactor(api): split XtreamAPIService into specialized services
perf(list): implement lazy loading for large lists
test(models): add unit tests for LiveStream model
chore(deps): update flutter_riverpod to 2.6.1

# Commit con body
feat(security): implement secure storage for credentials

Replace SharedPreferences with flutter_secure_storage to encrypt
sensitive user credentials. Includes migration logic for existing users.

Fixes #123
Closes #456

# ❌ INCORRECTO: Mensajes vagos

update stuff
fix bug
changes
wip
asdf
```

### Branch Strategy

```bash
# Branches principales
main          # Producción
develop       # Desarrollo

# Feature branches
feature/live-tv-grid
feature/catch-up-tv
fix/player-controls-bug
refactor/api-services
chore/update-dependencies

# Workflow
git checkout develop
git checkout -b feature/player-controls
# ... hacer cambios y commits
git push origin feature/player-controls
# Crear PR a develop
# Después de aprobación y merge
git checkout develop
git pull origin develop
```

### Pull Request Template

```markdown
## 📝 Description
Brief description of changes

## 🎯 Type of Change
- [ ] 🐛 Bug fix
- [ ] ✨ New feature
- [ ] 💥 Breaking change
- [ ] 📝 Documentation update
- [ ] ♻️ Refactoring

## 🧪 Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

## 📸 Screenshots (if applicable)
Before | After

## ✅ Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests pass locally
```

---

## ⚡ Performance

### ListView Optimization

```dart
// ✅ CORRECTO: ListView optimizado

ListView.builder(
  itemCount: channels.length,
  itemExtent: 120.0,  // ← Ayuda a Flutter a optimizar
  cacheExtent: 600.0, // ← Precache de items
  itemBuilder: (context, index) {
    return ChannelCard(
      key: ValueKey(channels[index].streamId),  // ← Key para reusabilidad
      channel: channels[index],
    );
  },
)

// ❌ INCORRECTO: ListView no optimizado

ListView(
  children: channels.map((channel) => ChannelCard(channel: channel)).toList(),
  // ❌ Crea todos los widgets de una vez
)
```

### Image Optimization

```dart
// ✅ CORRECTO: Imágenes optimizadas

CachedNetworkImage(
  imageUrl: channel.icon,
  width: 100,
  height: 100,
  memCacheWidth: 200,  // ← Limita tamaño en memoria
  memCacheHeight: 200,
  fit: BoxFit.cover,
  placeholder: (context, url) => const Shimmer(),
  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
)

// ❌ INCORRECTO: Imágenes sin optimizar

Image.network(
  channel.icon,
  // No hay cache
  // No hay resize
  // No hay error handling
)
```

### Async Operations

```dart
// ✅ CORRECTO: Operaciones paralelas con Future.wait

Future<void> loadData() async {
  final results = await Future.wait([
    fetchLiveStreams(),
    fetchVOD(),
    fetchSeries(),
  ]);
  
  _liveStreams = results[0];
  _vod = results[1];
  _series = results[2];
}

// ❌ INCORRECTO: Operaciones secuenciales

Future<void> loadData() async {
  _liveStreams = await fetchLiveStreams();  // Espera
  _vod = await fetchVOD();                   // Espera
  _series = await fetchSeries();             // Espera
  // ↑ 3x más lento
}
```

---

## 🔐 Seguridad

### Never Hardcode Secrets

```dart
// ✅ CORRECTO: Configuración externa

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiKey => dotenv('API_KEY')!;
  static String get baseUrl => dotenv('BASE_URL')!;
}

// .env (no commiteado)
API_KEY=abc123xyz
BASE_URL=https://api.example.com

// ❌ INCORRECTO: Secretos en código

const apiKey = 'abc123xyz';  // ❌ Visible en GitHub
const password = 'mypassword123';  // ❌ Comprometido
```

### Sanitize User Input

```dart
// ✅ CORRECTO: Validar y sanitizar

Future<void> login(String url) async {
  // Validar formato
  if (!Validators.isValidUrl(url)) {
    throw ValidationException('Invalid URL');
  }
  
  // Limitar longitud
  if (url.length > 500) {
    throw ValidationException('URL too long');
  }
  
  // Sanitizar caracteres especiales
  final sanitized = url.trim();
  
  await _authenticate(sanitized);
}

// ❌ INCORRECTO: Usar input directamente

Future<void> login(String url) async {
  await _authenticate(url);  // ❌ Sin validación
}
```

---

## 🎨 UI/UX

### Responsive Design

```dart
// ✅ CORRECTO: Responsive con MediaQuery y LayoutBuilder

class ChannelGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 6
            : constraints.maxWidth > 800
                ? 4
                : constraints.maxWidth > 600
                    ? 3
                    : 2;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 16 / 9,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) => ChannelCard(...),
        );
      },
    );
  }
}
```

### Accessibility

```dart
// ✅ CORRECTO: Con accesibilidad

Semantics(
  label: 'Play ${channel.name}',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.play_arrow),
    onPressed: () => _play(channel),
    tooltip: 'Reproducir',
  ),
)

// ❌ INCORRECTO: Sin accesibilidad

IconButton(
  icon: Icon(Icons.play_arrow),
  onPressed: () => _play(channel),
)
```

---

## 📖 Documentación

### Code Documentation

```dart
/// Service for interacting with Xtream Codes API.
///
/// This service handles all communication with Xtream Codes servers,
/// including authentication, fetching live streams, VOD, and series.
///
/// Example usage:
/// ```dart
/// final service = XtreamLiveService(
///   dio: dio,
///   serverUrl: 'http://server.com',
///   username: 'user',
///   password: 'pass',
/// );
/// final streams = await service.fetchLiveStreams();
/// ```
///
/// See also:
/// - [XtreamAuthService] for authentication
/// - [XtreamVODService] for video on demand
class XtreamLiveService {
  // ...
}
```

### README Updates

Mantener README.md actualizado con:
- Cómo instalar
- Cómo configurar
- Cómo ejecutar tests
- Cómo hacer build
- Arquitectura del proyecto
- Contribuir

---

## 🎯 Code Review Checklist

```markdown
### Antes de crear PR:
- [ ] Código formateado (`dart format .`)
- [ ] Sin warnings (`flutter analyze`)
- [ ] Tests agregados/actualizados
- [ ] Tests pasando (`flutter test`)
- [ ] Documentación actualizada
- [ ] Commit messages siguiendo convención
- [ ] Branch actualizado con develop

### Durante code review:
- [ ] Código es legible y mantenible
- [ ] No hay código duplicado
- [ ] Funciones son pequeñas y enfocadas
- [ ] Variables tienen nombres descriptivos
- [ ] No hay magic numbers
- [ ] Error handling es apropiado
- [ ] Performance es aceptable
- [ ] Seguridad no comprometida
- [ ] UI/UX es consistente
- [ ] Accesibilidad considerada
```

---

## 🚀 Quick Reference

```bash
# Formato
dart format .

# Análisis
flutter analyze --fatal-infos

# Tests
flutter test --coverage

# Build
flutter build apk --release --obfuscate --split-debug-info=debug-info/

# Dependencies
flutter pub get
flutter pub upgrade
flutter pub outdated

# Clean
flutter clean
flutter pub get
```

---

**Última actualización:** Febrero 2026  
**Mantenedor:** Luis Blanco  
**Contribuidores:** Equipo NexTV
