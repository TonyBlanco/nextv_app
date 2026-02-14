# Guía de Implementación - Google Play Store

**App:** NeXtv - IPTV Player  
**Plataforma:** Android  
**Versión:** 2.0.0  
**Fecha:** Febrero 2026

---

## 📋 Tabla de Contenidos

1. [Pre-requisitos](#1-pre-requisitos)
2. [Preparación de la App](#2-preparación-de-la-app)
3. [Configuración de Firma (Signing)](#3-configuración-de-firma-signing)
4. [Build de Producción](#4-build-de-producción)
5. [Creación de Cuenta de Desarrollador](#5-creación-de-cuenta-de-desarrollador)
6. [Configuración en Play Console](#6-configuración-en-play-console)
7. [Preparación de Assets de la Store](#7-preparación-de-assets-de-la-store)
8. [Políticas de Google Play](#8-políticas-de-google-play)
9. [Testing Interno/​Cerrado/​Abierto](#9-testing-internoacerradoabierto)
10. [Release de Producción](#10-release-de-producción)
11. [Post-Release](#11-post-release)
12. [Actualizaciones](#12-actualizaciones)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Pre-requisitos

### 1.1 Herramientas Necesarias

```bash
✅ Flutter SDK 3.x instalado
✅ Android Studio o Android SDK CLI tools
✅ Java JDK 17+
✅ Git
✅ Cuenta de Google (para Play Console)
✅ $25 USD (pago único de registro de desarrollador)
```

### 1.2 Verificar Instalación

```bash
# Verificar Flutter
flutter doctor -v

# Verificar que puedas compilar para Android
flutter doctor --android-licenses

# Verificar Java
java -version
```

### 1.3 Documentos Necesarios

- ✅ ID válido (para verificación de cuenta)
- ✅ Dirección física válida
- ✅ Método de pago (tarjeta de crédito/débito)
- ✅ Política de privacidad (URL pública requerida)
- ✅ Assets gráficos (iconos, capturas, etc.)

---

## 2. Preparación de la App

### 2.1 Actualizar Application ID

**Archivo:** `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.nextv.iptv"  // Tu ID único
    
    defaultConfig {
        applicationId = "com.nextv.iptv"  // ⚠️ NO cambiar después del primer release
        minSdk = 21  // Android 5.0+
        targetSdk = 34  // Android 14 (actualizar según Google requirements)
        versionCode = 1  // Incrementar en cada release
        versionName = "2.0.0"  // Versión visible para usuarios
    }
}
```

### 2.2 Configurar AndroidManifest.xml

**Archivo:** `android/app/src/main/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.nextv.iptv">

    <!-- Permisos -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    
    <!-- ⚠️ Evitar permisos innecesarios que Google rechaza -->

    <application
        android:label="NeXtv"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"  <!-- ⚠️ Seguridad: deshabilitar backup -->
        android:usesCleartextTraffic="false">  <!-- ⚠️ Solo HTTPS en producción -->

        <!-- Actividad principal -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 2.3 Configurar Icono de la App

**Opción A: Manually**
- Colocar iconos en:
  - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

**Opción B: Con flutter_launcher_icons**

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#0A0E1A"
  adaptive_icon_foreground: "assets/images/app_icon_foreground.png"
```

```bash
# Generar iconos
flutter pub get
flutter pub run flutter_launcher_icons
```

### 2.4 Configurar Nombre de la App

**Archivo:** `android/app/src/main/res/values/strings.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">NeXtv</string>
</resources>
```

---

## 3. Configuración de Firma (Signing)

### 3.1 Generar Keystore

```bash
# Navegar a carpeta android
cd android

# Generar keystore (guarda la contraseña de forma segura!)
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storetype JKS

# Seguir los prompts:
# - Enter keystore password: [TU_PASSWORD_SEGURO]
# - Re-enter password: [MISMO_PASSWORD]
# - What is your first and last name?: [Tu Nombre/Empresa]
# - What is your name of your organizational unit?: [Tu Departamento]
# - What is the name of your organization?: [Tu Empresa]
# - What is the name of your City or Locality?: [Tu Ciudad]
# - What is the name of your State or Province?: [Tu Estado]
# - What is the two-letter country code?: [ES/US/etc]
# - Is CN=..., OU=..., correct? yes
```

**⚠️ IMPORTANTE:** 
- **Guarda `upload-keystore.jks` en lugar seguro**
- **NO lo subas a Git** (añadir a `.gitignore`)
- **Guarda las contraseñas de forma segura** (password manager)
- **Si lo pierdes, NO podrás actualizar tu app en Play Store**

### 3.2 Crear key.properties

**Archivo:** `android/key.properties`

```properties
storePassword=TU_STORE_PASSWORD
keyPassword=TU_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

**⚠️ Agregar a .gitignore:**

```bash
# En android/.gitignore
key.properties
*.jks
*.keystore
```

### 3.3 Configurar Signing en build.gradle

**Archivo:** `android/app/build.gradle.kts`

```kotlin
// Después de 'plugins' y antes de 'android'
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... configuración existente ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            
            // Optimizaciones recomendadas
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 3.4 Configurar ProGuard (Opcional pero Recomendado)

**Archivo:** `android/app/proguard-rules.pro`

```proguard
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Better Player
-keep class com.jhomlala.** { *; }
-keepclassmembers class com.jhomlala.** { *; }

# VLC Player
-keep class org.videolan.** { *; }

# Gson (si se usa)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# Modelos de datos
-keep class com.nextv.iptv.models.** { *; }
```

---

## 4. Build de Producción

### 4.1 Build AAB (Android App Bundle) - RECOMENDADO

```bash
# Limpiar builds anteriores
flutter clean

# Obtener dependencias
flutter pub get

# Build con obfuscación (recomendado para seguridad)
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info

# El archivo estará en:
# build/app/outputs/bundle/release/app-release.aab
```

**Ventajas del AAB:**
- ✅ Tamaño de descarga menor para usuarios
- ✅ Google Play genera APKs optimizados por dispositivo
- ✅ Soporte automático para múltiples idiomas/densidades
- ✅ **REQUERIDO por Google Play desde agosto 2021**

### 4.2 Build APK (Alternativo, para testing)

```bash
# APK universal (más grande)
flutter build apk --release

# APKs separados por arquitectura (recomendado)
flutter build apk --release --split-per-abi

# Esto genera:
# - app-armeabi-v7a-release.apk (32-bit ARM)
# - app-arm64-v8a-release.apk (64-bit ARM)
# - app-x86_64-release.apk (64-bit x86)
```

### 4.3 Verificar el Build

```bash
# Ver información del APK/AAB
cd build/app/outputs/bundle/release
bundletool build-apks --bundle=app-release.aab \
  --output=app-release.apks \
  --mode=universal

# Instalar en dispositivo conectado
bundletool install-apks --apks=app-release.apks
```

### 4.4 Testear el Build de Release

**⚠️ IMPORTANTE:** Siempre testear el build de release antes de subir

```bash
# Instalar en dispositivo
flutter install --release

# Verificar:
# - ✅ Credenciales se guardan correctamente
# - ✅ Videos se reproducen sin problemas
# - ✅ No hay crashes
# - ✅ Permisos funcionan correctamente
# - ✅ Performance es aceptable
```

---

## 5. Creación de Cuenta de Desarrollador

### 5.1 Registro

1. Ir a [Google Play Console](https://play.google.com/console)
2. Iniciar sesión con cuenta de Google
3. Aceptar términos y condiciones
4. Pagar $25 USD (pago único de por vida)
5. Completar información de cuenta:
   - Nombre de desarrollador
   - Email de contacto
   - Dirección física
   - Teléfono

### 5.2 Verificación de Identidad

Google puede requerir:
- ✅ ID oficial con foto
- ✅ Verificación de dirección
- ✅ Verificación de número de teléfono

**Tiempo de verificación:** 24-48 horas normalmente

### 5.3 Configuración de Cuenta de Pagos

Si la app será paga o tendrá compras in-app:
1. Configurar Merchant Account
2. Proporcionar información fiscal
3. Configurar método de pago para recibir ingresos

---

## 6. Configuración en Play Console

### 6.1 Crear Nueva App

1. En Play Console, clic en "Crear app"
2. Completar información:
   - **Nombre de la app:** NeXtv
   - **Idioma predeterminado:** Español (España) o según tu mercado
   - **Tipo de app:** App
   - **Gratuita o de pago:** Gratuita (recomendado para IPTV)
3. Declaraciones:
   - ✅ La app cumple con políticas de Google Play
   - ✅ La app cumple con leyes de exportación de EE.UU.

### 6.2 Configurar Ficha de la Store

#### Información Principal

**Nombre de la app:** NeXtv  
**Descripción breve (80 caracteres):**
```
Reproductor IPTV premium para TV en vivo, películas y series
```

**Descripción completa (hasta 4000 caracteres):**
```
NeXtv - Tu Experiencia IPTV Premium

Disfruta de tu contenido IPTV favorito con la mejor experiencia de usuario.

🎬 CARACTERÍSTICAS PRINCIPALES:
• Soporte para protocolo Xtream Codes API
• Reproducción de TV en vivo con EPG (Guía de programación)
• Películas y series bajo demanda (VOD)
• Sistema inteligente de favoritos
• Catch-up TV - revive tus programas
• Interfaz moderna con diseño premium
• Soporte para múltiples proveedores IPTV
• Control parental integrado

📺 TV EN VIVO:
Accede a miles de canales en vivo de todo el mundo. EPG integrado para ver qué se está transmitiendo ahora y qué viene después.

🎥 PELÍCULAS Y SERIES:
Biblioteca completa de contenido VOD. Busca por género, año, calificación y más.

⭐ FAVORITOS:
Guarda tus canales y contenido favorito para acceso rápido.

⏪ CATCH-UP TV:
No te pierdas tus programas. Reproduce contenido de hasta 7 días atrás.

🎨 DISEÑO PREMIUM:
Interfaz moderna con efectos glassmorphism y animaciones fluidas. Optimizado para tablets y teléfonos.

🔒 CONTROL PARENTAL:
Protege a tu familia con filtros de contenido y bloqueo por PIN.

⚠️ IMPORTANTE:
NeXtv es un reproductor IPTV. No proporcionamos contenido ni servicios IPTV. 
Debes tener tu propia suscripción IPTV con un proveedor autorizado.
El usuario es responsable de verificar la legalidad del contenido al que accede.

🌐 MULTIPLATAFORMA:
Disponible para Android, iOS, Web y Smart TVs.

📧 SOPORTE:
support@nextv.app

🔐 PRIVACIDAD:
Tus credenciales se almacenan de forma segura en tu dispositivo. No recopilamos ni compartimos tu información personal.

Descarga NeXtv hoy y eleva tu experiencia IPTV al siguiente nivel.
```

### 6.3 Assets Gráficos

#### Icono de la App (512x512 px, PNG de 32 bits)
- Icono de alta resolución para la store
- Tamaño: 512x512 píxeles exactos
- Formato: PNG con canal alfa
- **Sin esquinas redondeadas** (Google las agrega automáticamente)

#### Imagen de Encabezado (1024x500 px)
- Banner promocional (opcional pero recomendado)
- Tamaño: 1024x500 píxeles
- Formato: PNG o JPG

#### Capturas de Pantalla (REQUERIDO)

**Teléfonos (mínimo 2, máximo 8):**
- Tamaño mínimo: 320px
- Tamaño máximo: 3840px  
- Aspecto: 16:9 o 9:16
- Formato: PNG o JPG (24-bit)

**Ejemplo de capturas recomendadas:**
1. Pantalla principal con lista de canales
2. Reproductor en acción mostrando video
3. Sistema de favoritos
4. EPG / guía de programación
5. Pantalla de login/configuración
6. Biblioteca de películas/series
7. Búsqueda de contenido
8. Diseño premium / UI highlights

**Tablets de 7" (opcional pero recomendado):**
- Same requirements as phones
- Mínimo 1 captura
- Aspect ratio optimizado para tablet

**Tablets de 10" (opcional):**
- Similar a tablets 7"

### 6.4 Video Promocional (Opcional)

- URL de YouTube
- Muestra características de la app
- Duración recomendada: 30-60 segundos

### 6.5 Categorización

**Categoría:** Reproducción de video  
**Etiquetas (hasta 5):**
- IPTV
- Streaming
- TV en vivo
- VOD
- Media player

### 6.6 Información de Contacto

**Correo electrónico:** support@nextv.app  
**Sitio web:** https://nextv.app  
**Teléfono:** [Opcional]

**Política de privacidad (⚠️ REQUERIDO):**
- Debe ser una URL pública y accesible
- Debe explicar qué datos recopila la app
- Debe estar en el idioma de la app

**Ejemplo de lo que debe incluir:**
```markdown
# Política de Privacidad - NeXtv

## Datos que Recopilamos
- Credenciales IPTV (almacenadas localmente, encriptadas)
- Preferencias de usuario (favoritos, configuración)
- Datos de uso anónimos (opcional, con consentimiento)

## Cómo Usamos los Datos
Los datos se almacenan exclusivamente en tu dispositivo y se usan 
para proporcionar funcionalidad de la app.

## Compartición de Datos
No compartimos tu información personal con terceros.
Las credenciales IPTV se envían únicamente a tu proveedor IPTV 
elegido para autenticación.

## Tus Derechos
Puedes eliminar todos tus datos desinstalando la app o usando 
la función de "Borrar datos" en configuración.

Contacto: privacy@nextv.app
Última actualización: Febrero 2026
```

---

## 7. Preparación de Assets de la Store

### 7.1 Crear Capturas de Pantalla

**Herramientas:**
- Android Emulator con diferentes tamaños
- Dispositivos físicos
- Screenshots dentro de la app

**Tips para mejores capturas:**
```bash
# Usar emuladores específicos
flutter emulators --launch Pixel_6_API_34

# Tomar screenshot desde Flutter DevTools
# o usar adb:
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
```

**Edición recomendada:**
- Agregar marcos de dispositivo para profesionalidad
- Agregar textos descriptivos (optional)
- Resaltar características clave
- Usar herramientas: Figma, Sketch, Photoshop

### 7.2 Herramienta para Assets: Fastlane Supply

```bash
# Instalar fastlane
gem install fastlane

# Configurar
cd android
fastlane supply init

# Estructura de carpetas:
# android/fastlane/metadata/android/
# ├── es-ES/
# │   ├── full_description.txt
# │   ├── short_description.txt
# │   ├── title.txt
# │   └── images/
# │       ├── icon.png
# │       ├── featureGraphic.png
# │       └── phoneScreenshots/
# └── en-US/
#     └── ...
```

---

## 8. Políticas de Google Play

### 8.1 Políticas Relevantes para Apps IPTV

#### ⚠️ Contenido Restringido

**Política de Google:**
> Apps que faciliten el acceso a contenido con derechos de autor sin 
> autorización pueden ser rechazadas o eliminadas.

**Cómo cumplir:**
1. **Disclaimer claro:**
   ```dart
   "NeXtv NO proporciona contenido. El usuario es responsable 
    de tener una suscripción legal de IPTV."
   ```

2. **No incluir proveedores pre-configurados**
3. **No incluir enlaces a contenido pirata**
4. **Implementar sistema de reportes de contenido ilegal**

#### 🔞 Contenido para Adultos

Si la app puede acceder a contenido adulto:
- ✅ Marcar rating como "Adultos" (18+)
- ✅ Implementar control parental obligatorio
- ✅ Filtrar contenido adulto por defecto
- ✅ Requerir confirmación de edad

#### 🎬 Sistema de Calificación de Contenido

Completar el cuestionario de rating en Play Console:
1. Apps y juegos → Calificacion de contenido
2. Completar cuestionario IARC:
   - Violencia
   - Contenido sexual
   - Lenguaje fuerte
   - Drogas/alcohol
   - etc.

**Para NeXtv sugiero:**
- Violence: Puede contener
- Sexuality: Puede contener (si no hay adult filtering)
- Language: Puede contener
- Rating esperado: Teen (12+) o Mature (17+)

### 8.2 Requisitos de Privacidad

#### Sección de Seguridad de Datos (REQUERIDO)

Declarar en Play Console:
1. **¿Recopila o comparte datos de usuario?**
   - NO (si solo almacenas localmente)
   - SÍ (si envías analytics)

2. **Qué datos:**
   - Credenciales IPTV: Almacenadas localmente, no compartidas
   - Preferencias: Almacenadas localmente
   - Historial: Almacenado localmente

3. **Propósito:**
   - Funcionalidad de la app
   - Personalización

4. **Datos encriptados:**
   - ✅ Los datos se encriptan en tránsito (HTTPS)
   - ✅ Los datos se encriptan en reposo (FlutterSecureStorage)

5. **Usuario puede solicitar eliminación:**
   - ✅ Sí (mediante desinstalación o función de borrar datos)

### 8.3 Requisitos Familiares

Si quieres que la app sea apta para familias:
- ❌ **NO recomendado para apps IPTV** (contenido variable)
- Requiere cumplir con COPPA (niños < 13 años)
- Requiere certificación adicional

**Recomendación:** No marcar como "Diseñado para familias"

---

## 9. Testing Interno/​Cerrado/​Abierto

### 9.1 Testing Interno (Recomendado primero)

**Propósito:** Testing rápido con equipo interno

**Pasos:**
1. Play Console → Testing → Testing interno
2. Crear lista de testers (hasta 100)
3. Subir AAB
4. Enviar link de opt-in a testers
5. Feedback rápido antes de release público

**Aprobación:** Instantánea

### 9.2 Testing Cerrado (Alpha)

**Propósito:** Testing con usuarios específicos (early adopters)

**Pasos:**
1. Play Console → Testing → Testing cerrado
2. Crear track (ej: "Alpha")
3. Agregar lista de testers (emails, grupos de Google)
4. Subir AAB
5. Testers reciben invitación

**Ventajas:**
- Feedback de usuarios reales
- Detectar bugs antes de release público
- Probar en amplia variedad de dispositivos

**Duración recomendada:** 1-2 semanas

### 9.3 Testing Abierto (Beta)

**Propósito:** Testing público antes de release final

**Pasos:**
1. Play Console → Testing → Testing abierto
2. Configurar disponibilidad:
   - Todos los países o países específicos
   - Límite de usuarios (opcional)
3. Subir AAB
4. Publicar

**Ventajas:**
- Cualquiera puede unirse
- Aparece en Play Store como "Beta"
- Feedback masivo
- Críticas no afectan rating de producción

**Duración recomendada:** 2-4 semanas

### 9.4 Gestión de Feedback

**Crear canal de feedback:**
- Google Groups
- Discord/Telegram
- Email: beta@nextv.app
- In-app feedback form

**Priorizar:**
- 🔴 Crashes críticos
- 🟡 Bugs que afectan funcionalidad principal
- 🟢 Mejoras de UX
- 🔵 Feature requests

---

## 10. Release de Producción

### 10.1 Revisión Pre-Release Checklist

```bash
✅ AAB compilado y firmado correctamente
✅ Testeado en modo release en múltiples dispositivos
✅ Todos los strings sensibles ofuscados
✅ Credenciales encriptadas con FlutterSecureStorage
✅ Política de privacidad publicada y accesible
✅ Disclaimer legal incluido en app
✅ Capturas de pantalla actualizadas y profesionales
✅ Descripción de la store completa y sin errores
✅ Icono de alta resolución subido
✅ Rating de contenido completado
✅ Sección de seguridad de datos completada
✅ Testing (al menos cerrado) completado
✅ Feedback de testers incorporado
✅ Version code incrementado
✅ Release notes preparados
```

### 10.2 Subir a Producción

**Pasos:**
1. Play Console → Producción
2. Crear nuevo release
3. Subir AAB:
   ```bash
   # Ubicación del archivo
   build/app/outputs/bundle/release/app-release.aab
   ```
4. Nombre del release: `2.0.0`
5. Notas de la versión (Release notes):

```markdown
🎉 NeXtv 2.0.0 - Release Inicial

✨ Características:
• Soporte completo para Xtream Codes API
• Reproducción de TV en vivo con EPG
• Biblioteca de películas y series (VOD)
• Sistema de favoritos inteligente
• Catch-up TV para revivir programas
• Diseño premium con interfaz moderna
• Control parental integrado
• Soporte para múltiples proveedores

🔒 Seguridad:
• Credenciales encriptadas
• Conexiones seguras (HTTPS)
• Sin recopilación de datos personales

📱 Compatibilidad:
• Android 5.0 (Lollipop) y superior
• Optimizado para smartphones y tablets

¿Problemas? Contáctanos: support@nextv.app
```

6. **Distribución:**
   - Países: Seleccionar (ej: España, América Latina, EE.UU.)
   - Disponibilidad: 100% de usuarios (o phased rollout)

7. **Revisión y envío:**
   - Revisar todo
   - "Enviar para revisión"

### 10.3 Proceso de Revisión de Google

**Tiempo estimado:** 24-72 horas (puede ser más)

**Fases:**
1. En revisión
2. Procesamiento de versión
3. Publicado

**Notificaciones:**
- ✅ Email cuando esté publicado
- ❌ Email si es rechazado (con razones)

### 10.4 Posibles Razones de Rechazo

| Razón | Solución |
|-------|----------|
| Política de privacidad inaccesible | Verificar URL, asegurar HTTPS |
| Sección de seguridad de datos incompleta | Completar todas las preguntas |
| Contenido restringido | Agregar disclaimers, control parental |
| App crashes | Testear exhaustivamente, fix bugs |
| Permisos no justificados | Explicar en manifest o remover |
| Metadata engañoso | Asegurar que descripciones sean precisas |

---

## 11. Post-Release

### 11.1 Monitoreo Inicial

**Primeras 24 horas:**
- 📊 Revisar estadísticas en Play Console
- 🔥 Monitorear crashes en Play Console → Calidad → Android vitals
- ⭐ Leer reviews y responder preguntas
- 📧 Monitorear emails de soporte

**Métricas clave:**
- Instalaciones
- Desinstalaciones
- Crash rate (objetivo: < 1%)
- ANR rate (objetivo: < 0.5%)
- Rating (objetivo: > 4.0)

### 11.2 Configurar Recopilación de Crashes

**Firebase Crashlytics (Recomendado):**

```yaml
# pubspec.yaml
dependencies:
  firebase_core: latest
  firebase_crashlytics: latest
```

```dart
// main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Capturar errores de Flutter
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(MyApp());
}
```

### 11.3 Responder a Reviews

**Buenas prácticas:**
- ✅ Responder en < 24 horas
- ✅ Agradecer feedback positivo
- ✅ Ofrecer ayuda en reviews negativos
- ✅ Proveer email de soporte
- ✅mantener tono profesional y amable

**Ejemplo de respuesta:**
```
⭐⭐: "No puedo conectar a mi servidor"

Respuesta:
"Hola [Usuario], lamentamos los problemas. Por favor verifica que:
1. La URL del servidor es correcta (debe incluir http:// o https://)
2. Tu usuario y contraseña son correctos
3. Tu conexión a Internet está activa

Si continúas con problemas, contáctanos en support@nextv.app 
y te ayudaremos personalmente. ¡Gracias!"
```

### 11.4 Marketing Post-Launch

- Share in social media
- Comunicado de prensa
- Contactar blogs de tecnología
- Community en Discord/Telegram/Reddit
- Ads de Google Play (opcional, de pago)

---

## 12. Actualizaciones

### 12.1 Proceso de Actualización

**Preparar nueva versión:**

1. **Incrementar version code y name:**
```kotlin
// android/app/build.gradle.kts
defaultConfig {
    versionCode = 2  // Incrementar SIEMPRE
    versionName = "2.0.1"  // Versión semántica
}
```

2. **Compilar nuevo AAB:**
```bash
flutter clean
flutter pub get
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

3. **Subir a Play Console:**
   - Producción → Crear nuevo release → Subir AAB
   - Agregar release notes detallados

**Release Notes Ejemplo:**
```markdown
🔧 NeXtv 2.0.1 - Bug Fixes y Mejoras

Correcciones:
• Corregido crash al cambiar de canal rápidamente
• Mejorada estabilidad de conexión con servidores lentos
• Arreglado problema de favoritos que no se guardaban

Mejoras:
• Performance mejorado en listas largas de canales
• Reducido uso de memoria en un 15%
• Actualizados reproductores de video a última versión

Gracias por sus reportes. ¡Seguimos mejorando!
```

### 12.2 Rollout Gradual (Phased Rollout)

**Recomendado para actualizaciones mayores:**

1. Configurar porcentaje inicial (ej: 10%)
2. Monitorear crashes y ratings durante 24h
3. Si todo va bien, incrementar a 50%
4. Monitorear otras 24h
5. Completar 100%

**Ventajas:**
- Limita impacto de bugs críticos
- Permite rollback si hay problemas serios
- Da tiempo para fix emergency bugs

### 12.3 Frecuencia de Actualizaciones

**Recomendado:**
- 🔴 Critical bugs: Inmediato
- 🟡 Major features: Cada 4-6 semanas
- 🟢 Minor improvements: Cada 2-3 semanas
- 🔵 Maintenance: Mensual

**Avoid:**
- ❌ Actualizaciones diarias (molesta a usuarios)
- ❌ Meses sin actualizaciones (parece abandonado)

---

## 13. Troubleshooting

### 13.1 Errores Comunes de Build

#### Error: "You uploaded an APK that is signed..."
**Causa:** Keystore diferente al original

**Solución:** Usar el mismo keystore SIEMPRE. Si lo perdiste, contacta a Google Play Support.

#### Error: "Version code X has already been used"
**Causa:** Version code no incrementado

**Solución:**
```kotlin
versionCode = X + 1  // Incrementar
```

#### Error: "INSTALL_FAILED_UPDATE_INCOMPATIBLE"
**Causa:** Firma diferente entre versiones

**Solución:**
```bash
# Desinstalar app anterior
adb uninstall com.nextv.iptv

# Reinstalar
flutter install --release
```

### 13.2 Problemas de Revisión

#### Rechazado: "Funcionalidad limitada"
**Causa:** App no funciona sin credenciales externas

**Solución:** 
- Proporcionar credenciales de prueba en "Notas para reviewers"
- Incluir video demo
- Documentación clara de cómo usar la app

#### Rechazado: "Violación de política de contenido"
**Causa:** Contenido restringido accesible

**Solución:**
- Agregar disclaimers prominentes
- Implementar control parental estricto
- Filtrar contenido adulto por defecto
- Apelar con explicación detallada

#### Rechazado: "Política de privacidad inválida"
**Causa:** URL inaccesible o política genérica

**Solución:**
- Asegurar URL pública y permanente
- Política específica para tu app
- HTTPS obligatorio
- En idioma de la app

### 13.3 Problemas Post-Release

#### Alto crash rate
**Causa:** Bug no detectado en testing

**Solución:**
1. Revisar crashes en Play Console → Android vitals
2. Identificar dispositivos/versiones afectados
3. Reproducir bug en emulador
4. Fix y release emergency update
5. Considerar rollback si es crítico

#### Malas reviews
**Causa:** Bug, expectativas no cumplidas, UX confusa

**Solución:**
1. Leer reviews cuidadosamente
2. Identificar patrones comunes
3. Responder a reviews
4. Priorizar fixes en próxima actualización
5. Comunicar que estás trabajando en ello

#### Baja retención de usuarios
**Causa:** Onboarding confuso, crashes, features faltantes

**Solución:**
1. Analizar funnel de usuarios en Play Console
2. Mejorar onboarding/tutorial
3. Fix bugs críticos
4. Agregar features más demandadas

---

## 14. Recursos Adicionales

### 14.1 Documentación Oficial

- [Google Play Console](https://play.google.com/console)
- [Políticas de Google Play](https://play.google.com/about/developer-content-policy/)
- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Android App Bundles](https://developer.android.com/guide/app-bundle)

### 14.2 Herramientas Útiles

- **bundletool:** Testing de AABs
- **Fastlane:** Automatización de deploys
- **Firebase:** Analytics y Crashlytics
- **AppFollow:** Monitoreo de reviews

### 14.3 Contacto y Soporte

**Google Play Support:**
- Play Console → Ayuda → Contactar soporte

**Comunidad:**
- [r/androiddev](https://reddit.com/r/androiddev)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/google-play)
- [Flutter Discord](https://discord.gg/flutter)

---

## 15. Checklist Final

```bash
PRE-RELEASE:
☐ Application ID configurado y único
☐ Keystore generado y guardado de forma segura
☐ key.properties configurado (no en Git)
☐ Signing configurado en build.gradle
☐ Version code y version name correctos
☐ Icono de app configurado
☐ Nombre de app correcto en todos los idiomas
☐ AndroidManifest con permisos mínimos
☐ Build de release testeado exhaustivamente
☐ Obfuscación habilitada
☐ Credenciales encriptadas implementado

PLAY CONSOLE:
☐ Cuenta de desarrollador creada y verificada ($25 pagado)
☐ App creada en consola
☐ Descripción completa y profesional
☐ Capturas de pantalla (mínimo 2, recomendado 8)
☐ Icono de alta resolución (512x512)
☐ Política de privacidad URL válida y pública
☐ Sección de seguridad de datos completa
☐ Rating de contenido completado (IARC)
☐ Categoría y etiquetas configuradas
☐ Información de contacto completa
☐ Disclaimer legal en descripción

TESTING:
☐ Testing interno completado
☐ Testing cerrado (alpha) opcional pero recomendado
☐ Testing abierto (beta) opcional pero recomendado
☐ Feedback de testers incorporado
☐ Bugs críticos resueltos

RELEASE:
☐ AAB final compilado con obfuscación
☐ Release notes preparados
☐ Países de distribución seleccionados
☐ Estrategia de rollout definida
☐ Enviado para revisión

POST-RELEASE:
☐ Monitoreo de crashes configurado (Firebase)
☐ Alertas de reviews configuradas
☐ Canal de soporte establecido
☐ Plan de actualizaciones definido
☐ Marketing y promoción iniciados
```

---

**¡Éxito con tu release en Google Play! 🚀**

**Contacto para dudas:** deployment@nextv.app  
**Documentación actualizada:** Febrero 2026  
**Versión de la guía:** 1.0
