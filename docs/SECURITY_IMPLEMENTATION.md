# 🛡️ Security Implementation Guide - NexTV App

**Nivel de implementación:** CRÍTICO  
**Fecha:** Febrero 2026  
**Estado:** 🔴 PENDIENTE

---

## 🎯 Security Checklist

### Pre-Release Mandatory
- [ ] Credenciales encriptadas con flutter_secure_storage
- [ ] Code obfuscation habilitado
- [ ] HTTPS enforcement implementado
- [ ] Disclaimers legales mostrados
- [ ] Política de privacidad incluida
- [ ] User-Agent propio implementado
- [ ] Logs sanitizados (sin credenciales)

### Recommended
- [  ] Certificate pinning
- [ ] Root/Jailbreak detection
- [ ] Screen capture prevention (DRM)
- [ ] Secure HTTP client configurado
- [ ] Input validation en todos los campos

---

## 🔐 1. Secure Storage Implementation

### Instalación

```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.2.2
```

### Configuración por plataforma

#### Android
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <application
    android:allowBackup="false">  <!-- Disable insecure backups -->
  </application>
</manifest>
```

#### iOS
```xml
<!-- ios/Runner/Info.plist -->
<key>NSFaceIDUsageDescription</key>
<string>Desbloquear credenciales guardadas</string>
```

### Implementación

```dart
// lib/core/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  // Credentials
  static Future<void> saveCredentials({
    required String username,
    required String password,
    required String serverUrl,
  }) async {
    await Future.wait([
      _storage.write(key: 'xtream_username', value: username),
      _storage.write(key: 'xtream_password', value: password),
      _storage.write(key: 'xtream_server_url', value: serverUrl),
    ]);
  }

  static Future<Map<String, String?>> getCredentials() async {
    final values = await Future.wait([
      _storage.read(key: 'xtream_username'),
      _storage.read(key: 'xtream_password'),
      _storage.read(key: 'xtream_server_url'),
    ]);

    return {
      'username': values[0],
      'password': values[1],
      'serverUrl': values[2],
    };
  }

  static Future<void> deleteCredentials() async {
    await Future.wait([
      _storage.delete(key: 'xtream_username'),
      _storage.delete(key: 'xtream_password'),
      _storage.delete(key: 'xtream_server_url'),
    ]);
  }

  // Generic secure storage
  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
```

### Migración de datos existentes

```dart
// lib/core/services/migration_service.dart
class MigrationService {
  static Future<void> migrateToSecureStorage(SharedPreferences prefs) async {
    // Check if migration is needed
    final migrated = prefs.getBool('migrated_to_secure_storage') ?? false;
    if (migrated) return;

    try {
      // Read old data
      final username = prefs.getString('username');
      final password = prefs.getString('password');
      final serverUrl = prefs.getString('server_url');

      // Write to secure storage
      if (username != null && password != null && serverUrl != null) {
        await SecureStorageService.saveCredentials(
          username: username,
          password: password,
          serverUrl: serverUrl,
        );

        // Delete from SharedPreferences
        await Future.wait([
          prefs.remove('username'),
          prefs.remove('password'),
          prefs.remove('server_url'),
        ]);
      }

      // Mark as migrated
      await prefs.setBool('migrated_to_secure_storage', true);
      
      print('✅ Migration to secure storage completed');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }
}

// En main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  await MigrationService.migrateToSecureStorage(prefs);
  
  runApp(MyApp());
}
```

---

## 🔒 2. Code Obfuscation

### Configuración

```bash
# Build con obfuscación
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info/
flutter build ios --release --obfuscate --split-debug-info=build/debug-info/
```

### ProGuard adicional (Android)

```proguard
# android/app/proguard-rules.pro

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep data models for JSON serialization
-keep class com.nextv.app.core.models.** { *; }

# Better Player / VLC
-keep class com.jhomlala.better_player.** { *; }
-keep class software.aws.** { *; }

# Media Kit
-keep class com.alexmercerind.media_kit.** { *; }
```

### Verificar obfuscación

```bash
# Después del build, verificar que los symbols están guardados
ls -lh build/debug-info/

# Estos archivos son necesarios para desofuscar crash reports
```

---

## 🌐 3. HTTPS Enforcement

### Network Security Config (Android)

```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Producción: Solo HTTPS -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    
    <!-- Debug: Permitir HTTP local -->
    <debug-overrides>
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </debug-overrides>
</network-security-config>
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application
    android:networkSecurityConfig="@xml/network_security_config">
</application>
```

### iOS ATS (App Transport Security)

```xml
<!-- ios/Runner/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <!-- Bloquear HTTP por defecto -->
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    
    <!-- Solo para servidores específicos que requieran HTTP -->
    <key>NSExceptionDomains</key>
    <dict>
        <!-- Ejemplo: servidor de prueba interno -->
        <key>test.internal.server</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### Validación en código

```dart
// lib/core/utils/security_utils.dart
class SecurityUtils {
  static bool isSecureUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  static Future<bool> confirmInsecureConnection(
    BuildContext context,
    String url,
  ) async {
    if (isSecureUrl(url) || kDebugMode) {
      return true;
    }

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('⚠️ Conexión Insegura'),
        content: const Text(
          'El servidor usa HTTP sin encriptación.\n\n'
          '• Tus credenciales pueden ser interceptadas\n'
          '• Tu actividad puede ser monitoreada\n'
          '• Recomendamos usar un servidor HTTPS\n\n'
          '¿Deseas continuar de todos modos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Continuar (No Seguro)'),
          ),
        ],
      ),
    ) ?? false;
  }
}
```

---

## 🕵️ 4. Input Validation & Sanitization

### URL Validation

```dart
// lib/core/utils/validators.dart
class Validators {
  static String? validateServerUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL del servidor es requerida';
    }

    // Validar formato de URL
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAbsolutePath) {
      return 'URL inválida';
    }

    // Validar esquema
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'URL debe comenzar con http:// o https://';
    }

    // Validar longitud máxima
    if (value.length > 500) {
      return 'URL demasiado larga';
    }

    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Usuario es requerido';
    }

    if (value.length > 200) {
      return 'Usuario demasiado largo';
    }

    // Permitir solo caracteres seguros
    if (!RegExp(r'^[a-zA-Z0-9_\-\.@]+$').hasMatch(value)) {
      return 'Usuario contiene caracteres inválidos';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contraseña es requerida';
    }

    if (value.length > 200) {
      return 'Contraseña demasiado larga';
    }

    return null;
  }
}
```

### HTML/XSS Prevention

```dart
// lib/core/utils/sanitization.dart
import 'package:html_unescape/html_unescape.dart';

class Sanitization {
  static final _unescape = HtmlUnescape();

  static String sanitizeText(String text) {
    // Decode HTML entities
    String sanitized = _unescape.convert(text);
    
    // Remove potential script tags
    sanitized = sanitized.replaceAll(RegExp(r'<script[^>]*>.*?</script>', 
      caseSensitive: false), '');
    
    // Remove other potentially dangerous tags
    sanitized = sanitized.replaceAll(RegExp(r'<iframe[^>]*>.*?</iframe>',
      caseSensitive: false), '');
    
    return sanitized;
  }

  static String sanitizeChannelName(String name) {
    String sanitized = sanitizeText(name);
    
    // Limitar longitud
    if (sanitized.length > 200) {
      sanitized = '${sanitized.substring(0, 197)}...';
    }
    
    return sanitized;
  }
}

// Uso en widgets
Text(Sanitization.sanitizeChannelName(channel.name))
```

---

## 🔍 5. Secrets Scanner Setup

### TruffleHog Configuration

```yaml
# .trufflehog.yaml
base: main
head: HEAD
max_depth: 100
since:
commit:
branch:
repo_path: .
allow:
  paths:
    - "**/*.dart"
    - "**/*.yaml"
    - "**/*.json"
exclude:
  paths:
    - "**/node_modules/**"
    - "**/build/**"
    - "**/.dart_tool/**"
    - "**/pubspec.lock"
detectors:
  - name: "generic"
    keywords:
      - "password"
      - "secret"
      - "api_key"
      - "apiKey"
      - "access_token"
      - "auth_token"
```

### Pre-commit hook

```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "🔍 Scanning for secrets..."

if command -v trufflehog &> /dev/null; then
  trufflehog filesystem . --no-update 2>&1 | tee trufflehog-output.txt
  
  if [ -s trufflehog-output.txt ]; then
    echo "❌ Secrets detected! Commit aborted."
    exit 1
  else
    echo "✅ No secrets found."
    rm trufflehog-output.txt
  fi
else
  echo "⚠️  TruffleHog not installed. Skipping secret scan."
  echo "   Install with: brew install trufflesecurity/trufflehog/trufflehog"
fi
```

---

## 🛡️ 6. Certificate Pinning (Advanced)

### Implementación

```dart
// lib/core/network/secure_http_client.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class SecureHttpClient {
  static Dio createSecureDio() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Certificate pinning
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      
      client.badCertificateCallback = (cert, host, port) {
        // En producción: validar contra pins conocidos
        if (kReleaseMode) {
          return _validateCertificate(cert, host);
        }
        // En debug: permitir certificados self-signed
        return true;
      };
      
      return client;
    };

    return dio;
  }

  static bool _validateCertificate(X509Certificate cert, String host) {
    // SHA-256 fingerprints de certificados confiables
    const trustedFingerprints = [
      // Agregar los hashes de los certificados de servidores confiables
      // Obtener con: openssl s_client -connect server.com:443 | openssl x509 -fingerprint -sha256
    ];

    final certHash = cert.sha256.toString();
    return trustedFingerprints.contains(certHash);
  }
}
```

---

## 🚫 7. Root/Jailbreak Detection

```yaml
# pubspec.yaml
dependencies:
  flutter_jailbreak_detection: ^1.10.0
```

```dart
// lib/core/security/device_security.dart
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class DeviceSecurity {
  static Future<bool> isDeviceSecure() async {
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      final devMode = await FlutterJailbreakDetection.developerMode;
      
      return !jailbroken && !devMode;
    } catch (e) {
      // Si falla la detección, asumimos que el dispositivo es seguro
      return true;
    }
  }

  static Future<void> checkDeviceSecurity(BuildContext context) async {
    if (kDebugMode) return; // Skip en desarrollo
    
    final isSecure = await isDeviceSecure();
    
    if (!isSecure) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Dispositivo No Seguro'),
          content: const Text(
            'Se detectó que el dispositivo tiene acceso root/jailbreak.\n\n'
            'Esto puede comprometer la seguridad de tus credenciales.\n\n'
            '¿Deseas continuar bajo tu propio riesgo?',
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Salir'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    }
  }
}
```

---

## 📱 8. Screen Capture Prevention (DRM)

```yaml
# pubspec.yaml
dependencies:
  flutter_windowmanager: ^0.2.0
```

```dart
// lib/presentation/screens/player/video_player_screen.dart
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class VideoPlayerScreen extends StatefulWidget {
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  @override
  void initState() {
    super.initState();
    _disableScreenCapture();
  }

  @override
  void dispose() {
    _enableScreenCapture();
    super.dispose();
  }

  Future<void> _disableScreenCapture() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await FlutterWindowManager.addFlags(
          FlutterWindowManager.FLAG_SECURE,
        );
      } catch (e) {
        print('Failed to disable screen capture: $e');
      }
    }
  }

  Future<void> _enableScreenCapture() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await FlutterWindowManager.clearFlags(
          FlutterWindowManager.FLAG_SECURE,
        );
      } catch (e) {
        print('Failed to enable screen capture: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VideoPlayer(),
    );
  }
}
```

---

## 📊 Security Audit Checklist

### Pre-Release Security Audit

```markdown
## 🔒 Security Checklist v1.0

### Data Protection
- [ ] Credenciales encriptadas (flutter_secure_storage)
- [ ] No hay secretos en código fuente
- [ ] No hay logs con información sensible
- [ ] SharedPreferences solo para datos no sensibles

### Network Security
- [ ] HTTPS enforcement implementado y testeado
- [ ] User-Agent propio configurado
- [ ] Timeouts configurados apropiadamente
- [ ] Certificate pinning (opcional pero recomendado)

### Code Protection
- [ ] Code obfuscation habilitado en builds de release
- [ ] ProGuard configurado (Android)
- [ ] Debug symbols guardados para crash analysis

### Input Validation
- [ ] URLs validadas
- [ ] Usernames y passwords validados
- [ ] Longitudes máximas aplicadas
- [ ] HTML/XSS sanitization implementado

### Device Security
- [ ] Root/Jailbreak detection (opcional)
- [ ] Screen capture prevention en player (DRM)

### Legal & Compliance
- [ ] Política de privacidad incluida
- [ ] Términos de servicio incluidos
- [ ] Disclaimers legales mostrados
- [ ] Consentimiento del usuario obtenido

### Permissions
- [ ] Permisos mínimos solicitados
- [ ] Descripciones claras de permisos
- [ ] No hay permisos innecesarios

### Testing
- [ ] Security tests ejecutados
- [ ] Penetration testing básico realizado
- [ ] Secrets scanner ejecutado
- [ ] Dependency audit sin vulnerabilidades críticas
```

---

## 🚀 Implementation Priority

1. **CRITICAL (Week 1):**
   - Secure Storage
   - Code Obfuscation
   - HTTPS Enforcement

2. **HIGH (Week 2):**
   - Input Validation
   - Secrets Scanner
   - Log Sanitization

3. **MEDIUM (Week 3):**
   - Certificate Pinning
   - Root Detection
   - Screen Capture Prevention

4. **LOW (Week 4):**
   - Advanced security features
   - Security monitoring
   - Incident response plan

---

**Última actualización:** Febrero 2026  
**Security Officer:** Luis Blanco  
**Next Review:** Post-implementation
