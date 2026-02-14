# Manual de Documentación Técnica - NeXtv App

**Versión:** 2.0.0  
**Fecha:** Febrero 2026  
**Autor:** Equipo de Desarrollo NeXtv

---

## 📋 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura de la Aplicación](#arquitectura-de-la-aplicación)
3. [Stack Tecnológico](#stack-tecnológico)
4. [Estructura del Proyecto](#estructura-del-proyecto)
5. [Componentes Principales](#componentes-principales)
6. [Flujos de Datos](#flujos-de-datos)
7. [Gestión de Estado](#gestión-de-estado)
8. [Servicios Core](#servicios-core)
9. [Modelos de Datos](#modelos-de-datos)
10. [Interfaz de Usuario](#interfaz-de-usuario)
11. [Plataformas Soportadas](#plataformas-soportadas)
12. [Configuración y Despliegue](#configuración-y-despliegue)
13. [Testing y Calidad](#testing-y-calidad)
14. [Mantenimiento](#mantenimiento)
15. [Glosario](#glosario)

---

## 1. Resumen Ejecutivo

### 1.1 Descripción
NeXtv es una aplicación IPTV multiplataforma de nivel premium desarrollada en Flutter. Proporciona acceso a contenido de televisión en vivo, películas, series y catch-up TV mediante el protocolo Xtream Codes API.

### 1.2 Características Principales
- 📺 **Live TV**: Soporte para 30,000+ canales en vivo
- 🎬 **VOD**: Películas y series bajo demanda
- ⏪ **Catch-up TV**: Reproducción de programas pasados
- ⭐ **Sistema de Favoritos**: Gestión persistente de canales favoritos
- 📡 **EPG**: Guía electrónica de programación
- 🎨 **UI Premium**: Diseño moderno con glassmorphism y animaciones fluidas
- 🔒 **Control Parental**: Filtrado de contenido por categorías
- 🌐 **Multiplataforma**: Android, iOS, Web, WebOS, macOS, Windows, Linux

### 1.3 Usuarios Objetivo
- Consumidores finales que buscan una experiencia IPTV de alta calidad
- Proveedores de servicios IPTV que requieren una solución white-label
- Operadores de televisión digital

---

## 2. Arquitectura de la Aplicación

### 2.1 Patrón Arquitectónico
La aplicación sigue el patrón **Clean Architecture** con separación clara de responsabilidades:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, UI Components)      │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│           Business Layer                │
│  (Providers, Services, Use Cases)       │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│            Data Layer                   │
│  (Models, Repositories, API Clients)    │
└─────────────────────────────────────────┘
```

### 2.2 Principios de Diseño
- **Separation of Concerns**: Cada capa tiene responsabilidades específicas
- **Dependency Injection**: Usando Riverpod para gestión de dependencias
- **Single Responsibility**: Cada clase/servicio tiene un propósito único
- **DRY (Don't Repeat Yourself)**: Política de cero duplicación de código
- **Inmutabilidad**: Modelos de datos inmutables donde sea posible

### 2.3 Flujo de Datos
```
User Input → Screen → Provider → Service → API/Storage → Model → Provider → Screen → UI Update
```

---

## 3. Stack Tecnológico

### 3.1 Framework Principal
- **Flutter**: 3.x (SDK >= 2.18.0 < 4.0.0)
- **Dart**: Lenguaje de programación principal

### 3.2 Gestión de Estado
- **flutter_riverpod**: ^2.6.1 - State management reactivo

### 3.3 Networking
- **dio**: ^5.1.2 - Cliente HTTP para API calls
- **xml**: ^6.6.1 - Parsing de EPG XML

### 3.4 Almacenamiento
- **shared_preferences**: ^2.5.4 - Persistencia de configuración y favoritos
- **hive**: ^2.2.3 - Base de datos local NoSQL
- **hive_flutter**: ^1.1.0 - Integración de Hive con Flutter
- **flutter_secure_storage**: ^10.0.0 - Almacenamiento seguro de credenciales

### 3.5 Reproductores de Video
- **better_player_plus**: ^1.1.5 - Player principal para Android/iOS
- **flutter_vlc_player**: ^7.4.4 - Player alternativo con soporte VLC
- **media_kit**: ^1.1.10 - Player para Desktop (Windows/Linux/macOS)
- **media_kit_video**: ^2.0.1 - Componente de video para media_kit
- **media_kit_libs_windows_video**: ^1.0.9 - Librerías nativas Windows
- **media_kit_libs_macos_video**: latest - Librerías nativas macOS
- **media_kit_libs_ios_video**: ^1.1.4 - Librerías nativas iOS

### 3.6 UI/UX
- **google_fonts**: ^8.0.1 - Tipografías personalizadas
- **cached_network_image**: ^3.3.0 - Caché de imágenes
- **flutter_svg**: ^2.0.10 - Soporte para vectores SVG
- **scrollable_positioned_list**: ^0.3.8 - Listas con scroll posicionable

### 3.7 Utilidades
- **url_launcher**: ^6.3.2 - Apertura de URLs externas
- **path_provider**: ^2.1.3 - Acceso al sistema de archivos
- **permission_handler**: ^12.0.1 - Gestión de permisos
- **intl**: latest - Internacionalización
- **equatable**: ^2.0.5 - Comparación de objetos
- **flutter_dotenv**: ^6.0.0 - Variables de entorno

### 3.8 Características Avanzadas
- **google_generative_ai**: latest - Integración con Gemini AI
- **webview_flutter**: ^4.13.1 - WebViews embebidas
- **universal_html**: ^2.3.0 - HTML universal para multiplataforma

---

## 4. Estructura del Proyecto

### 4.1 Estructura de Directorios
```
nextv_app/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── core/                     # Lógica de negocio
│   │   ├── constants/            # Constantes y configuración
│   │   │   ├── nextv_colors.dart
│   │   │   └── ...
│   │   ├── models/               # Modelos de datos
│   │   │   ├── xtream_models.dart
│   │   │   ├── playlist_model.dart
│   │   │   └── ...
│   │   ├── services/             # Servicios de negocio
│   │   │   ├── xtream_api_service.dart
│   │   │   ├── playlist_manager.dart
│   │   │   ├── epg_service.dart
│   │   │   ├── favorites_service.dart
│   │   │   └── ...
│   │   ├── providers/            # Riverpod providers
│   │   │   ├── active_playlist_provider.dart
│   │   │   ├── favorites_provider.dart
│   │   │   └── ...
│   │   ├── adapters/             # Adaptadores de plataforma
│   │   └── utils/                # Utilidades
│   ├── presentation/             # Capa de UI
│   │   ├── screens/              # Pantallas completas
│   │   │   ├── landing_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── nova_main_screen.dart
│   │   │   ├── provider_manager_screen.dart
│   │   │   └── ...
│   │   ├── widgets/              # Componentes reutilizables
│   │   │   ├── nextv_logo.dart
│   │   │   ├── premium_top_bar.dart
│   │   │   └── ...
│   │   └── platform_router.dart  # Enrutamiento específico
│   └── features/                 # Módulos de características
│       └── player/               # Feature de reproducción
├── android/                      # Configuración Android
├── ios/                          # Configuración iOS
├── macos/                        # Configuración macOS
├── windows/                      # Configuración Windows
├── linux/                        # Configuración Linux
├── web/                          # Configuración Web
├── webos/                        # Build para WebOS
├── assets/                       # Recursos estáticos
│   └── images/
├── docs/                         # Documentación
├── scripts/                      # Scripts de deployment
└── test/                         # Tests unitarios
```

### 4.2 Convenciones de Nomenclatura

#### Archivos
- **Snake case**: `feature_name_screen.dart`
- **Sufijos**:
  - `_screen.dart` - Pantallas completas
  - `_widget.dart` - Widgets reutilizables
  - `_service.dart` - Servicios de negocio
  - `_provider.dart` - Riverpod providers
  - `_model.dart` - Modelos de datos

#### Clases
- **PascalCase**: `PremiumTopBar`, `XtreamAPIService`

#### Variables y Métodos
- **camelCase**: `activePlaylist`, `fetchLiveStreams()`

---

## 5. Componentes Principales

### 5.1 Entry Point (main.dart)

**Responsabilidades:**
- Inicialización de la aplicación
- Configuración de MediaKit para desktop e iOS
- Configuración de player por defecto (BetterPlayer)
- Setup de SharedPreferences
- Definición de rutas principales

**Rutas disponibles:**
```dart
routes: {
  '/landing': (context) => const LandingScreen(),
  '/dashboard': (context) => const LandingScreen(),
  '/login': (context) => const LoginScreen(),
  '/player': (context) => const NovaMainScreen(),
  '/providers': (context) => const ProviderManagerScreen(),
  '/playlist-selector': (context) => const PlaylistSelectorScreen(),
}
```

### 5.2 Startup Screen

**Funcionalidad:**
- Carga automática de configuración
- Fallback chain de navegación:
  1. Si hay playlist activa → `/player` (NovaMainScreen)
  2. Si hay playlists guardadas → `/playlist-selector`
  3. Si hay proveedores → `/providers`
  4. Por defecto → `/landing`

### 5.3 Pantallas Principales

#### Landing Screen
- Primera pantalla de bienvenida
- Branding y presentación
- Navegación a login o configuración

#### Login Screen
- Ingreso de credenciales Xtream Codes
- Campos: Server URL, Username, Password
- Validación y autenticación
- Guardado de proveedores

#### Nova Main Screen
- Pantalla principal de la aplicación
- Navegación entre Live TV, VOD y Series
- Barra superior premium con logo NeXtv
- Sistema de favoritos integrado

#### Provider Manager Screen
- Gestión de múltiples proveedores IPTV
- CRUD de credenciales
- Selección de proveedor activo

#### Playlist Selector Screen
- Selección entre múltiples playlists guardadas
- Visualización de información del proveedor

---

## 6. Flujos de Datos

### 6.1 Flujo de Autenticación
```
1. Usuario ingresa credenciales en LoginScreen
2. LoginScreen llama a XtreamAPIService.authenticate()
3. XtreamAPIService realiza petición HTTP al servidor
4. Servidor responde con datos de usuario y permisos
5. Credenciales se guardan en ProviderManager
6. Usuario es redirigido a NovaMainScreen
```

### 6.2 Flujo de Carga de Canales
```
1. NovaMainScreen se monta
2. Provider fetchea datos de activePlaylistProvider
3. activePlaylistProvider carga credenciales de SharedPreferences
4. XtreamAPIService.fetchLiveStreams() obtiene lista de canales
5. Datos parseados a List<LiveStream>
6. Provider notifica a la UI
7. UI renderiza lista de canales
```

### 6.3 Flujo de Favoritos
```
1. Usuario presiona icono de favorito en un canal
2. Widget llama a FavoritesService.toggleFavorite()
3. FavoritesService actualiza SharedPreferences
4. favoritesProvider emite nuevo estado
5. UI se actualiza reactivamente mostrando cambio visual
```

### 6.4 Flujo de Reproducción
```
1. Usuario selecciona un canal/video
2. Screen construye URL de stream usando credenciales
3. Navega a PlayerScreen con stream URL
4. PlayerScreen inicializa reproductor apropiado:
   - BetterPlayer para Android/iOS
   - MediaKit para Desktop/iOS (MKV)
   - VLC como fallback
5. Reproductor carga y comienza playback
6. EPG se carga en paralelo si está disponible
```

---

## 7. Gestión de Estado

### 7.1 Riverpod Providers

#### sharedPreferencesProvider
```dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});
```
- Proveedor de SharedPreferences
- Overridden en main.dart con instancia real

#### activePlaylistProvider
```dart
final activePlaylistProvider = StreamProvider<PlaylistModel?>((ref) {
  final manager = ref.watch(playlistManagerProvider);
  return manager.watchActivePlaylist();
});
```
- Stream del playlist activo
- Se actualiza automáticamente cuando cambia

#### favoritesProvider
```dart
final favoritesProvider = StreamProvider<List<FavoriteChannel>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  return service.watchFavorites();
});
```
- Stream de canales favoritos
- Reactivo a cambios en almacenamiento

#### xtreamAPIProvider
```dart
final xtreamAPIProvider = Provider((ref) => XtreamAPIService());
```
- Instancia singleton de XtreamAPIService

### 7.2 Patrones de Estado

#### Provider Pattern
Para datos inmutables o servicios:
```dart
final myServiceProvider = Provider((ref) => MyService());
```

#### StreamProvider Pattern
Para datos que cambian con el tiempo:
```dart
final myDataProvider = StreamProvider<MyData>((ref) {
  return myService.watchData();
});
```

#### StateNotifierProvider Pattern
Para estado mutable complejo:
```dart
final myStateProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});
```

---

## 8. Servicios Core

### 8.1 XtreamAPIService

**Ubicación:** `lib/core/services/xtream_api_service.dart`

**Responsabilidad:** Comunicación con Xtream Codes API

**Métodos principales:**
```dart
class XtreamAPIService {
  // Autenticación
  Future<Map<String, dynamic>> authenticate();
  
  // Obtener canales en vivo
  Future<List<LiveStream>> fetchLiveStreams();
  
  // Obtener categorías de TV
  Future<List<StreamCategory>> fetchLiveCategories();
  
  // Obtener películas
  Future<List<VodStream>> fetchVodStreams();
  
  // Obtener series
  Future<List<SeriesInfo>> fetchSeries();
  
  // Obtener información de serie específica
  Future<SeriesDetails> getSeriesInfo(int seriesId);
}
```

**Características:**
- Manejo de múltiples User-Agents
- Retry automático con diferentes User-Agents
- Timeouts configurables (30 segundos)
- Manejo de códigos de estado no estándares
- Headers personalizados para compatibilidad con servidores IPTV

### 8.2 PlaylistManager

**Ubicación:** `lib/core/services/playlist_manager.dart`

**Responsabilidad:** Gestión de playlists guardadas

**Métodos principales:**
```dart
class PlaylistManager {
  // Guardar playlist
  Future<void> savePlaylist(PlaylistModel playlist);
  
  // Obtener todas las playlists
  Future<List<PlaylistModel>> getAllPlaylists();
  
  // Establecer playlist activa
  Future<void> setActivePlaylist(String id);
  
  // Obtener playlist activa
  Stream<PlaylistModel?> watchActivePlaylist();
  
  // Eliminar playlist
  Future<void> deletePlaylist(String id);
}
```

### 8.3 FavoritesService

**Ubicación:** `lib/core/services/favorites_service.dart`

**Responsabilidad:** Gestión de canales favoritos

**Métodos principales:**
```dart
class FavoritesService {
  // Agregar/eliminar favorito
  Future<void> toggleFavorite(LiveStream stream);
  
  // Verificar si es favorito
  bool isFavorite(int streamId);
  
  // Obtener todos los favoritos
  Stream<List<FavoriteChannel>> watchFavorites();
  
  // Limpiar favoritos
  Future<void> clearFavorites();
}
```

**Persistencia:**
- Almacenamiento en SharedPreferences
- Serialización JSON
- Keys: `favorites_v2`

### 8.4 EPGService

**Ubicación:** `lib/core/services/epg_service.dart`

**Responsabilidad:** Gestión de guía electrónica de programas

**Métodos principales:**
```dart
class EPGService {
  // Obtener EPG de un canal
  Future<void> fetchXtreamEPG(
    String serverUrl, 
    String username, 
    String password, 
    int streamId
  );
  
  // Obtener programa actual
  EPGProgram? getCurrentProgram(int streamId);
  
  // Obtener URL de catch-up
  String getCatchupUrl(
    String serverUrl,
    String username,
    String password,
    int streamId,
    DateTime startTime,
    int durationHours
  );
}
```

### 8.5 ChannelStatusService

**Ubicación:** `lib/core/services/channel_status_service.dart`

**Responsabilidad:** Verificación de disponibilidad de canales

**Métodos principales:**
```dart
class ChannelStatusService {
  // Verificar si un canal está disponible
  Future<bool> checkChannelAvailability(
    LiveStream channel,
    String serverUrl,
    String username,
    String password
  );
  
  // Verificación en batch
  Future<void> batchCheckChannels(
    List<LiveStream> channels,
    String serverUrl,
    String username,
    String password
  );
}
```

### 8.6 PlaylistGenerator

**Ubicación:** `lib/core/services/playlist_generator.dart`

**Responsabilidad:** Generación de playlists M3U

**Métodos principales:**
```dart
class PlaylistGenerator {
  // Generar M3U desde lista de streams
  String generateM3U(
    List<LiveStream> streams,
    {String serverUrl, String username, String password}
  );
  
  // Generar M3U de favoritos
  String generateFavoritesM3U(...);
  
  // Generar M3U por categoría
  String generateCategoryM3U(...);
}
```

---

## 9. Modelos de Datos

### 9.1 XtreamCredentials
```dart
class XtreamCredentials {
  final String serverUrl;
  final String username;
  final String password;
  
  // Constructor, fromJson, toJson
}
```

### 9.2 LiveStream
```dart
class LiveStream {
  final int streamId;
  final String name;
  final String? streamIcon;
  final int categoryId;
  final String? epgChannelId;
  final bool? added;
  
  // Métodos de utilidad
  String getStreamUrl(String serverUrl, String username, String password);
}
```

### 9.3 VodStream
```dart
class VodStream {
  final int streamId;
  final String name;
  final String? streamIcon;
  final int categoryId;
  final String? containerExtension;
  final StreamInfo? info;
  
  // Método para obtener URL de stream
}
```

### 9.4 SeriesInfo
```dart
class SeriesInfo {
  final int seriesId;
  final String name;
  final String? cover;
  final int categoryId;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? releaseDate;
  final double? rating;
}
```

### 9.5 PlaylistModel
```dart
class PlaylistModel {
  final String id;
  final String name;
  final XtreamCredentials credentials;
  final DateTime createdAt;
  final DateTime lastUsed;
  
  // Serialización
}
```

### 9.6 FavoriteChannel
```dart
class FavoriteChannel {
  final int streamId;
  final String name;
  final String? icon;
  final DateTime addedAt;
  
  // Serialización
}
```

### 9.7 EPGProgram
```dart
class EPGProgram {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;
  final int channelId;
}
```

---

## 10. Interfaz de Usuario

### 10.1 Tema y Estilos

#### NextvColors
```dart
class NextvColors {
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF1A1F2E);
  static const Color accent = Color(0xFF6366F1);
  static const Color accentBright = Color(0xFF818CF8);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB4B8C5);
}
```

#### Tipografía
- **Font Family:** Google Fonts - Inter
- **Tamaños:**
  - Título: 24px, bold
  - Subtítulo: 18px, semibold
  - Body: 14px, regular
  - Caption: 12px, regular

### 10.2 Widgets Reutilizables

#### NextvLogo
```dart
class NextvLogo extends StatelessWidget {
  final double size;
  final bool animate;
  
  // Renderiza logo con animación opcional
}
```

#### PremiumTopBar
```dart
class PremiumTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  
  // Barra superior con branding NeXtv
}
```

#### ChannelCard
```dart
class ChannelCard extends StatelessWidget {
  final LiveStream channel;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  
  // Tarjeta de canal con imagen, nombre, favorito
}
```

### 10.3 Navegación

**Tipo:** Navigator 1.0 con rutas nombradas

**Rutas disponibles:**
- `/` - StartupScreen (automático)
- `/landing` - LandingScreen
- `/login` - LoginScreen
- `/player` - NovaMainScreen
- `/providers` - ProviderManagerScreen
- `/playlist-selector` - PlaylistSelectorScreen

**Navegación programática:**
```dart
// Navegar a nueva ruta
Navigator.pushNamed(context, '/player');

// Reemplazar ruta actual
Navigator.pushReplacementNamed(context, '/landing');

// Navegar con datos
Navigator.pushNamed(
  context, 
  '/player',
  arguments: {'streamId': 123}
);
```

---

## 11. Plataformas Soportadas

### 11.1 Android
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** 34 (Android 14)
- **Application ID:** com.nextv.iptv
- **Permisos requeridos:**
  - INTERNET
  - ACCESS_NETWORK_STATE
  - WAKE_LOCK

### 11.2 iOS
- **Min Version:** iOS 12.0
- **Bundle ID:** com.nextv.iptv (o personalizado)
- **Capacidades:**
  - Background Audio
  - Network Access
- **Permisos:**
  - NSLocalNetworkUsageDescription
  - NSAppTransportSecurity

### 11.3 Web
- **Compatibilidad:** Chrome, Firefox, Safari, Edge
- **Limitaciones:**
  - No soporta VLC player
  - Limitaciones de CORS en algunos servidores
  - Requiere HTTPS para ciertas características

### 11.4 WebOS (LG TV)
- **Build:** Paquete IPK
- **App ID:** com.nextv.app
- **Formato:** Web app empaquetada
- **Resolución:** 1920x1080
- **Memoria requerida:** 256MB

### 11.5 Desktop

#### Windows
- **Min Version:** Windows 10
- **Arquitecturas:** x64, ARM64

#### macOS
- **Min Version:** macOS 10.14
- **Arquitecturas:** x86_64, ARM64 (Apple Silicon)

#### Linux
- **Distribuciones:** Ubuntu 18.04+, Fedora, Debian
- **Arquitecturas:** x64, ARM64

---

## 12. Configuración y Despliegue

### 12.1 Requisitos de Desarrollo

**Software requerido:**
- Flutter SDK 3.x
- Dart SDK (incluido con Flutter)
- Android Studio / Xcode (para desarrollo móvil)
- Visual Studio Code o IntelliJ IDEA

**Dependencias del sistema:**
- Git
- CocoaPods (para iOS/macOS)
- Android SDK Build Tools
- Xcode Command Line Tools (macOS)

### 12.2 Setup Inicial

```bash
# Clonar repositorio
git clone <repo-url>
cd nextv_app

# Instalar dependencias
flutter pub get

# Verificar configuración
flutter doctor

# Generar código (si aplica)
flutter pub run build_runner build
```

### 12.3 Ejecución en Desarrollo

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Desktop (Linux ejemplo)
flutter run -d linux
```

### 12.4 Build de Producción

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### 12.5 Configuración de Signing

#### Android
Editar `android/app/build.gradle.kts`:
```kotlin
signingConfigs {
    release {
        storeFile = file("path/to/keystore.jks")
        storePassword = "password"
        keyAlias = "alias"
        keyPassword = "password"
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

#### iOS
Configurar en Xcode:
- Team ID
- Provisioning Profile
- Code Signing Identity

---

## 13. Testing y Calidad

### 13.1 Test Unitarios

**Ubicación:** `test/`

**Ejecutar tests:**
```bash
flutter test
```

**Cobertura:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 13.2 Widget Tests

```dart
testWidgets('Test de un widget', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());
  expect(find.text('Hello'), findsOneWidget);
});
```

### 13.3 Tests de Integración

```bash
flutter drive --target=test_driver/app.dart
```

### 13.4 Análisis Estático

```bash
# Análisis de código
flutter analyze

# Formateo
flutter format lib/ test/

# Lints configurados
# Ver: analysis_options.yaml
```

---

## 14. Mantenimiento

### 14.1 Actualización de Dependencias

```bash
# Ver dependencias desactualizadas
flutter pub outdated

# Actualizar
flutter pub upgrade

# Actualizar major versions (con precaución)
flutter pub upgrade --major-versions
```

### 14.2 Logs y Debugging

**Modo debug:**
```dart
debugPrint('Mensaje de debug');
```

**Logs estructurados:**
```dart
import 'dart:developer' as developer;
developer.log('Message', name: 'nextv.service.api');
```

**Debug remoto:**
- Android: `adb logcat`
- iOS: Console.app o Xcode
- Chrome DevTools: `flutter run -d chrome --web-renderer html`

### 14.3 Monitoreo de Performance

**Flutter DevTools:**
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

**Métricas clave:**
- Frame rendering time (< 16ms)
- Memory usage
- Network requests latency
- App startup time

### 14.4 Gestión de Versiones

**Formato:** semantic versioning (MAJOR.MINOR.PATCH)

**Actualizar versión:**
- Editar `pubspec.yaml`: `version: 2.0.1`
- Commit: `git commit -m "chore: bump version to 2.0.1"`
- Tag: `git tag v2.0.1`

---

## 15. Glosario

- **IPTV**: Internet Protocol Television
- **Xtream Codes**: Protocolo/API estándar para servicios IPTV
- **VOD**: Video On Demand (películas y series)
- **EPG**: Electronic Program Guide (guía de programación)
- **Catch-up TV**: Televisión diferida, reproducción de programas pasados
- **M3U**: Formato de archivo de playlist multimedia
- **Provider**: Proveedor de servicio IPTV
- **Stream**: Flujo de video/audio en tiempo real
- **Riverpod**: Librería de gestión de estado para Flutter
- **Clean Architecture**: Patrón arquitectónico con separación de capas
- **User-Agent**: Identificador de cliente HTTP
- **BetterPlayer**: Librería de reproducción de video para Flutter
- **MediaKit**: Framework multimedia multiplataforma

---

## Contacto y Soporte

**Equipo de Desarrollo:** NeXtv Team  
**Email:** support@nextv.app  
**Documentación Online:** https://docs.nextv.app  
**Repository:** [GitHub Link]

---

**Última actualización:** Febrero 2026  
**Versión del documento:** 1.0
