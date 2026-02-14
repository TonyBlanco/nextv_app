# Guía de Implementación - iOS App Store

**App:** NeXtv - IPTV Player  
**Plataforma:** iOS / iPadOS  
**Versión:** 2.0.0  
**Fecha:** Febrero 2026

---

## 📋 Tabla de Contenidos

1. [Pre-requisitos](#1-pre-requisitos)
2. [Preparación del Entorno](#2-preparación-del-entorno)
3. [Configuración de la App en Xcode](#3-configuración-de-la-app-en-xcode)
4. [App Store Connect Setup](#4-app-store-connect-setup)
5. [Certificados y Provisioning Profiles](#5-certificados-y-provisioning-profiles)
6. [Configuración de Capabilities](#6-configuración-de-capabilities)
7. [Build de Producción](#7-build-de-producción)
8. [Preparación de Assets](#8-preparación-de-assets)
9. [App Store Review Guidelines](#9-app-store-review-guidelines)
10. [TestFlight](#10-testflight)
11. [Release de Producción](#11-release-de-producción)
12. [Post-Release](#12-post-release)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Pre-requisitos

### 1.1 Hardware y Software

```bash
✅ Mac con macOS 13.0 (Ventura) o superior
✅ Xcode 15.0+ instalado desde Mac App Store
✅ Flutter SDK 3.x configurado
✅ CocoaPods instalado
✅ Apple ID válido
✅ Membresía Apple Developer Program ($99/año)
✅ Dispositivo iOS para testing (opcional pero recomendado)
```

### 1.2 Verificar Instalaciones

```bash
# Verificar Xcode
xcode-select --version
xcode-select --install  # Si es necesario

# Verificar Flutter para iOS
flutter doctor -v

# Verificar CocoaPods
pod --version

# Instalar CocoaPods si no está
sudo gem install cocoapods
```

### 1.3 Apple Developer Program

**Registrarse:**
1. Ir a [Apple Developer](https://developer.apple.com/programs/)
2. Iniciar sesión con Apple ID
3. Inscribirse en el Developer Program
4. Pagar $99 USD (**renovación anual**)
5. Esperar aprobación (24-48 horas normalmente)

**Tipos de cuenta:**
- **Individual:** Para desarrolladores independientes
- **Organization:** Para empresas (requiere D-U-N-S Number)

---

## 2. Preparación del Entorno

### 2.1 Configurar Xcode Command Line Tools

```bash
# Establecer ruta de command line tools
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Verificar
xcode-select -p
```

### 2.2 Instalar Dependencias de iOS

```bash
cd ios
pod install
cd ..
```

### 2.3 Abrir Proyecto en Xcode

```bash
# Desde terminal
open ios/Runner.xcworkspace

# ⚠️ IMPORTANTE: Usar .xcworkspace, NO .xcodeproj cuando hay CocoaPods
```

---

## 3. Configuración de la App en Xcode

### 3.1 Bundle Identifier

1. En Xcode, seleccionar **Runner** en el navegador de proyectos
2. Seleccionar target **Runner**
3. Pestaña **General**
4. **Bundle Identifier:** `com.nextv.iptv` (único, no cambiar después de release)

**⚠️ IMPORTANTE:**
- Debe ser único en todo el App Store
- Formato: reverse domain notation
- NO puede cambiarse después del primer release

### 3.2 Display Name y Version

**General → Identity:**
- **Display Name:** NeXtv
- **Version:** 2.0.0 (semantic versioning)
- **Build:** 1 (incrementar en cada build)

**Convención de Build Number:**
```
Version 2.0.0, Build 1
Version 2.0.1, Build 2
Version 2.1.0, Build 3
```

### 3.3 Deployment Target

**General → Deployment Info:**
- **iOS Deployment Target:** 12.0 o superior
- **Supported Devices:** iPhone, iPad (Universal)
- **Orientations:** 
  - Portrait ✅
  - Landscape Left ✅
  - Landscape Right ✅
  - Upside Down ❌ (opcional)

### 3.4 Configurar Info.plist

**Archivo:** `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Información Básica -->
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    
    <key>CFBundleDisplayName</key>
    <string>NeXtv</string>
    
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    
    <key>CFBundleName</key>
    <string>NeXtv</string>
    
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    
    <!-- Permisos y Descripciones (REQUERIDO) -->
    <key>NSLocalNetworkUsageDescription</key>
    <string>NeXtv necesita acceso a la red local para transmitir contenido IPTV desde tu proveedor.</string>
    
    <key>NSCameraUsageDescription</key>
    <string>⚠️ Si no usas cámara, ELIMINAR esta entrada</string>
    
    <key>NSMicrophoneUsageDescription</key>
    <string>⚠️ Si no usas micrófono, ELIMINAR esta entrada</string>
    
    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <!-- ⚠️ Solo para desarrollo - QUITAR en producción si es posible -->
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        
        <!-- Permitir HTTP solo para servidores IPTV específicos -->
        <key>NSExceptionDomains</key>
        <dict>
            <!-- Ejemplo: permitir tu servidor IPTV si usa HTTP -->
            <!-- ⚠️ Eliminar esto si todos tus servers usan HTTPS -->
            <!--
            <key>your-iptv-server.com</key>
            <dict>
                <key>NSIncludesSubdomains</key>
                <true/>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
            -->
        </dict>
    </dict>
    
    <!-- Background Modes (si es necesario) -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>  <!-- Para continuar audio en background -->
    </array>
    
    <!-- Orientaciones Soportadas -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <!-- iPad Orientaciones -->
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <!-- Launch Screen -->
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    
    <!-- Status Bar -->
    <key>UIStatusBarHidden</key>
    <false/>
    
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
    
    <!-- Performance -->
    <key>CADisableMinimumFrameDurationOnPhone</key>
    <true/>
    
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
</dict>
</plist>
```

**⚠️ CRÍTICO:** 
- **Eliminar permisos no usados** (cámara, micrófono, ubicación, etc.)
- Apple rechaza apps que solicitan permisos innecesarios
- Cada permiso debe tener descripción clara y justificada

### 3.5 Configurar App Icons

**Manualmente:**
1. Crear iconos en todos los tamaños requeridos
2. Agregar a `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**Tamaños requeridos:**
- 20x20 @2x, @3x
- 29x29 @2x, @3x
- 40x40 @2x, @3x
- 60x60 @2x, @3x
- 76x76 @1x, @2x (iPad)
- 83.5x83.5 @2x (iPad Pro)
- 1024x1024 @1x (App Store)

**Automáticamente con flutter_launcher_icons:**

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4

flutter_launcher_icons:
  ios: true
  android: false
  image_path: "assets/images/app_icon.png"
  remove_alpha_ios: true  # iOS no permite transparencia
```

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

---

## 4. App Store Connect Setup

### 4.1 Acceder a App Store Connect

1. Ir a [App Store Connect](https://appstoreconnect.apple.com)
2. Iniciar sesión con Apple ID de desarrollador
3. Verificar que la membresía esté activa

### 4.2 Crear Nueva App

1. **Mis Apps** → **+** → **Nueva App**
2. Configurar:

**Plataformas:** iOS

**Nombre:** NeXtv  
(Debe ser único en todo el App Store, máx 30 caracteres)

**Idioma principal:** Español (España) o tu mercado principal

**Bundle ID:** com.nextv.iptv  
(Debe coincidir con Xcode)

**SKU:** com.nextv.iptv.v1  
(Identificador interno único, nunca se muestra al usuario)

**Acceso Completo:** Usuario Completo  
(Para desarrolladores individuales)

### 4.3 Configurar Información de la App

#### Información General

**Página de la App:**
- Nombre: NeXtv
- Subtítulo (30 caracteres): `Reproductor IPTV Premium`
- Categoría principal: **Entretenimiento**
- Categoría secundaria: **Foto y vídeo**

#### Clasificación por Edades

Completar cuestionario:
1. **Violencia realista:** Poco frecuente/moderado (si aplica)
2. **Contenido sexual:** Poco frecuente/moderado (si hay canales adultos)
3. **Lenguaje obsceno:** Poco frecuente/moderado (si aplica)
4. **Acceso web sin restricciones:** SÍ (streams de internet)
5. **Resultado esperado:** 12+ o 17+

**Recomendación:** 17+ si no hay control parental estricto

---

## 5. Certificados y Provisioning Profiles

### 5.1 Automatic Signing (Recomendado para principiantes)

En Xcode:
1. Seleccionar target **Runner**
2. Pestaña **Signing & Capabilities**
3. ✅ **Automatically manage signing**
4. **Team:** Seleccionar tu Team ID
5. Xcode creará certificados automáticamente

### 5.2 Manual Signing (Avanzado)

Si prefieres control manual:

#### Paso 1: Crear Certificate Signing Request (CSR)

```bash
# En Mac, abrir Keychain Access
# Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority

# Completar:
# - User Email Address: tu@email.com
# - Common Name: Tu Nombre
# - Request is: Saved to disk
# Guardar como: CertificateSigningRequest.certSigningRequest
```

#### Paso 2: Crear Certificado de Distribución

1. [Apple Developer Portal](https://developer.apple.com/account/)
2. **Certificates, Identifiers & Profiles** → **Certificates**
3. **+** → **iOS Distribution (App Store and Ad Hoc)**
4. Subir CSR creado en Paso 1
5. Descargar certificado (`.cer`)
6. Doble clic para instalar en Keychain

#### Paso 3: Crear App ID

1. **Identifiers** → **+**
2. Tipo: **App IDs**
3. **App ID Prefix:** (Tu Team ID, auto-seleccionado)
4. **Bundle ID:** Explicit - `com.nextv.iptv`
5. **Capabilities:**
   - ✅ Associated Domains (si usas Universal Links)
   - ✅ Background Modes (si usas background audio)
   - ✅ Push Notifications (si las usas)
6. Registrar

#### Paso 4: Crear Provisioning Profile

1. **Profiles** → **+**
2. **Distribution** → **App Store**
3. Seleccionar App ID creado
4. Seleccionar certificado de distribución
5. Nombre: `NeXtv App Store Profile`
6. Descargar (`.mobileprovision`)
7. Doble clic para instalar

#### Paso 5: Configurar en Xcode

```
Xcode → Runner → Signing & Capabilities
☐ Automatically manage signing  (deshabilitar)

Development:
- Provisioning Profile: Manual → [Tu Development Profile]
- Signing Certificate: iOS Developer

Release:
- Provisioning Profile: Manual → NeXtv App Store Profile
- Signing Certificate: iOS Distribution
```

---

## 6. Configuración de Capabilities

### 6.1 Capabilities Necesarias

En Xcode → **Signing & Capabilities** → **+ Capability**

#### Background Modes (Si es necesario)
- ✅ Audio, AirPlay, and Picture in Picture
  - Para continuar reproducción en background
  - Apple requiere justificación en revisión

#### Associated Domains (Opcional)
- Para Universal Links
- Formato: `applinks:nextv.app`

### 6.2 Capabilities a EVITAR si no se usan

- ❌ HealthKit
- ❌ HomeKit
- ❌ Location services (si no lo necesitas)
- ❌ Push Notifications (si no las implementaste)

**Razón:** Apple rechaza apps con capabilities no usadas

---

## 7. Build de Producción

### 7.1 Pre-build Checklist

```bash
☐ Bundle ID correcto en Xcode
☐ Display Name configurado
☐ Version y Build number correctos
☐ Deployment target establecido (iOS 12.0+)
☐ Info.plist sin permisos innecesarios
☐ App icons configurados
☐ Signing configurado correctamente
☐ Capabilities solo las necesarias
☐ Testeado en dispositivo real
```

### 7.2 Limpiar y Preparar

```bash
# Limpiar builds anteriores
flutter clean

# Actualizar pods
cd ios
pod repo update
pod install
cd ..

# Actualizar dependencias
flutter pub get
```

### 7.3 Build desde Terminal (Recomendado)

```bash
# Build con obfuscación para seguridad
flutter build ios --release \
  --obfuscate \
  --split-debug-info=build/ios-debug-info

# Esto genera Runner.app en:
# build/ios/iphoneos/Runner.app
```

### 7.4 Archive desde Xcode

1. Abrir proyecto: `open ios/Runner.xcworkspace`
2. Seleccionar esquema: **Runner**
3. Seleccionar destino: **Any iOS Device (arm64)**
4. **Product** → **Archive**
5. Esperar a que compile (puede tomar varios minutos)
6. Se abre **Organizer** automáticamente

**⚠️ Solución de errores comunes:**

```bash
# Si falla el archive:

# Error: "No such module 'Flutter'"
cd ios
pod deintegrate
pod install
cd ..

# Error de signing
# → Revisar Signing & Capabilities en Xcode
# → Asegurar que el certificado esté instalado
# → Revisar que Provisioning Profile sea válido

# Error: "Command PhaseScriptExecution failed"
# → Limpiar derived data
# Xcode → Preferences → Locations → Derived Data → Delete
```

### 7.5 Validar Archive

En **Organizer**:
1. Seleccionar el archive recién creado
2. **Distribute App** → **App Store Connect** → **Upload**
3. **Options:**
   - ✅ Strip Swift symbols
   - ✅ Upload your app's symbols to receive symbolicated reports
   - ✅ Manage Version and Build Number (automático)
4. **Advanced:**
   - ✅ Include bitcode for iOS content: NO (obsoleto desde Xcode 14)
5. **Sign and Upload**
6. Esperar confirmación (puede tomar 10-30 minutos)

---

## 8. Preparación de Assets

### 8.1 Capturas de Pantalla (REQUERIDO)

Apple requiere capturas para cada tamaño de dispositivo:

#### iPhone 6.7" (Pro Max) - REQUERIDO
- Tamaño: 1290 x 2796 píxeles
- Orientación: Portrait o Landscape
- Cantidad: 3-10 capturas
- Devices: iPhone 15 Pro Max, 14 Pro Max, 13 Pro Max, 12 Pro Max

#### iPhone 6.5" (opcional pero recomendado)
- Tamaño: 1242 x 2688 píxeles
- Devices: iPhone 11 Pro Max, XS Max

#### iPhone 5.5" (opcional)
- Tamaño: 1242 x 2208 píxeles
- Devices: iPhone 8 Plus, 7 Plus, 6s Plus

#### iPad Pro (12.9") - Si soportas iPad
- Tamaño: 2048 x 2732 píxeles (Portrait) o 2732 x 2048 (Landscape)

#### iPad Pro (11") - Si soportas iPad
- Tamaño: 1668 x 2388 píxeles

**⚠️ IMPORTANTE:**
- Todas las capturas del mismo dispositivo deben ser en la misma orientación
- No incluir bordes de dispositivo (solo contenido)
- No incluir status bar si es posible
- Máxima calidad (PNG o JPG de alta calidad)

**Crear capturas:**

```bash
# Usar simuladores específicos
flutter emulators --launch apple_ios_simulator

# En Xcode:
# Open Developer Tool → Simulator
# Seleccionar: iPhone 15 Pro Max
# Cmd+S para captura de pantalla
```

**Herramientas recomendadas:**
- [Shotbot](https://app.shotbot.io/) - Genera capturas con frames
- [AppLaunchpad](https://theapplaunchpad.com/) -Genera assets automáticamente
- Figma/Sketch - Para agregar textos y efectos

### 8.2 App Preview (Video - Opcional pero Recomendado)

- Duración: 15-30 segundos
- Resolución: Misma que capturas
- Formato: M4V, MOV, MP4
- Muestra características clave de la app
- Sin audio de copyright

**Tips:**
1. Mostrar login (rápidamente)
2. Navegar por canales
3. Reproducir video
4. Mostrar favoritos
5. Mostrar EPG
6. Resaltar diseño premium

### 8.3 Icono de la App Store (1024x1024)

- Tamaño: 1024x1024 píxeles exactos
- Formato: PNG sin transparencia
- Color space: sRGB o P3
- Sin esquinas redondeadas (Apple las agrega)
- Sin texto "Beta" o badges

**Verificar:**
```bash
# Ver información de imagen
sips -g all icon-1024.png

# Convertir a sRGB si es necesario
sips -m "/System/Library/ColorSync/Profiles/sRGB Profile.icc" icon-1024.png
```

---

## 9. App Store Review Guidelines

### 9.1 Guidelines Críticas para IPTV Apps

#### 2.3.1 - Información Precisa
- ✅ Descripción debe ser precisa
- ✅ Capturas reales de tu app
- ✅ No prometas contenido que no provees

#### 4.2.2 - Otros Proveedores de Contenido
**⚠️ CRÍTICO para apps IPTV:**

> "Apps that access third-party content must obtain express permission from the content provider to do so."

**Cómo cumplir:**
1. **Disclaimer prominente:**
```
⚠️ IMPORTANTE:
NeXtv es SOLO un reproductor IPTV.
NO proporcionamos contenido, servicios IPTV ni suscripciones.
Debes tener tu propia suscripción legal de un proveedor autorizado.
El usuario es responsable de la legalidad del contenido al que accede.
```

2. **No incluir proveedores pre-configurados**
3. **No mostrar contenido pirata en capturas de pantalla**
4. **Implementar sistema de reporte de contenido ilegal**
5. **Tener una respuesta preparada para el reviewer de Apple**

#### 5.1.1 - Privacidad
- ✅ Política de privacidad clara y accesible
- ✅ Declarar qué datos recopilas
- ✅ Explicar cómo usas los datos
- ✅ Opción de eliminar cuenta/datos

#### 5.1.2 - Consentimiento de Datos
- ✅ Pedir permiso antes de recopilar datos
- ✅ Explicar por qué necesitas cada permiso

### 9.2 Preparar Nota para Reviewer

En App Store Connect, apartado **App Review Information**:

```
INSTRUCCIONES PARA REVIEWER:

NeXtv es un reproductor IPTV profesional que requiere credenciales 
de un proveedor IPTV para funcionar.

CREDENCIALES DE PRUEBA:
Server URL: http://demo.iptv-provider.com:8080
Username: demo
Password: demo123

CÓMO PROBAR LA APP:
1. Abrir app y tocar "Iniciar Sesión"
2. Ingresar las credenciales de prueba proporcionadas arriba
3. Presionar "Conectar"
4. La app cargará canales de prueba
5. Seleccionar cualquier canal para reproducir

IMPORTANTE SOBRE EL CONTENIDO:
- NeXtv NO proporciona contenido ni servicios IPTV
- El demo server proporcionado contiene solo contenido de prueba legal
- En uso real, los usuarios deben proveer sus propias credenciales IPTV legales
- Tenemos disclaimers prominentes sobre responsabilidad del usuario

CARACTERÍSTICAS A REVISAR:
- Login con credenciales IPTV
- Navegación de canales
- Reproducción de video
- Sistema de favoritos
- EPG (guía de programación)
- Control parental (PIN: 1234)

CONTACTO:
Si tienen preguntas, por favor contactar:
Email: review@nextv.app
Teléfono: +1 (XXX) XXX-XXXX

Gracias por su revisión.
```

### 9.3 Preparar Demo Server

**⚠️ MUY IMPORTANTE:**
- Apple NECESITA poder probar tu app
- Debes proveer credenciales de test funcionales
- El servidor debe estar disponible 24/7 durante revisión
- Contenido debe ser 100% legal y apropiado

**Opciones:**
1. Contactar a un proveedor IPTV para cuenta de prueba
2. Crear tu propio servidor de prueba con contenido libre
3. Usar Xtream Codes demo (si disponible)

---

## 10. TestFlight

### 10.1 Configurar TestFlight

Después de subir el build a App Store Connect:

1. **Mi Apps** → **NeXtv** → **TestFlight**
2. Esperar procesamiento (10-60 minutos)
3. Aparecerá en **iOS Builds**
4. Completar información de prueba:
   - ¿Qué probar?
   - Cuenta de demo (igual que reviewer notes)
   - Información de contacto

### 10.2 Testing Interno

**Agregar testers internos:**
1. **TestFlight** → **Internal Testing**
2. **+** → Agregar por email
3. Límite: 100 testers internos
4. No requiere revisión de Apple
5. Builds disponibles inmediatamente

**Distribución:**
- Enviar link de TestFlight
- Testers descargan **TestFlight app**
- Instalan build de prueba
- Proporcionan feedback

### 10.3 Testing Externo (Beta Pública)

1. **TestFlight** → **External Testing**
2. Crear nuevo grupo: "Beta Testers"
3. Agregar build
4. Completar información para revisión de Apple
5. **Enviar para revisión**
6. Esperar aprobación (24-48 horas)
7. Una vez aprobado, invitar testers

**Límite:** 10,000 testers externos

**Ventajas:**
- Feedback de usuarios reales
- Detectar bugs antes de release
- Probar en dispositivos variados
- No afecta rating del App Store

### 10.4 Gestionar Feedback

```bash
TestFlight recopila automáticamente:
- ✅ Crashes
- ✅ Screenshots de testers
- ✅ Comentarios
- ✅ Device info
- ✅ iOS version

Revisar en:
App Store Connect → TestFlight → Feedback
```

---

## 11. Release de Producción

### 11.1 Pre-Release Checklist

```bash
☐ Build subido y procesado en App Store Connect
☐ Testeado exhaustivamente via TestFlight
☐ Feedback de testers incorporado
☐ Bugs críticos resueltos
☐ Todas las capturas subidas
☐ Icono 1024x1024 subido
☐ Descripción completa y sin errores
☐ Política de privacidad URL válida
☐ Clasificación por edad completada
☐ Nota para reviewer preparada
☐ Credenciales de demo funcionales
☐ Información de contacto correcta
☐ Localización completa (si multi-idioma)
☐ Pricing & Availability configurado
```

### 11.2 Completar Información de Release

#### En App Store Connect → NeXtv → Versión (2.0.0):

**¿Qué hay de nuevo en esta versión?**
```markdown
🎉 NeXtv 2.0.0 - Release Inicial

Bienvenido a NeXtv, tu reproductor IPTV premium.

✨ NOVEDADES:
• Soporte completo para Xtream Codes API
• Reproducción de TV en vivo con EPG integrado
• Biblioteca de películas y series (VOD)
• Sistema inteligente de favoritos
• Catch-up TV para ver programas pasados
• Diseño premium con efectos glassmorphism
• Control parental con PIN
• Soporte para múltiples proveedores IPTV

📱 OPTIMIZACIONES:
• Rendimiento mejorado en dispositivos antiguos
• Menor consumo de batería
• Carga rápida de canales
• Interfaz intuitiva y moderna

🔒 SEGURIDAD:
• Credenciales encriptadas con Keychain
• Conexiones seguras (HTTPS)
• Sin recopilación de datos personales

¿Problemas o sugerencias?
Contáctanos: support@nextv.app

Disfruta de NeXtv! 📺✨
```

**Descripción Promocional (170 caracteres):**
```
Reproductor IPTV premium con diseño moderno. TV en vivo, películas, 
series y catch-up TV. Control parental integrado. 📺
```

### 11.3 Pricing & Availability

1. **Precio:** Gratis (recomendado para apps IPTV)
2. **Availability:**
   - Países: Seleccionar (ej: España, Latinoamérica, EE.UU.)
   - Pre-order: NO (para primera versión)
3. **App Distribution Methods:**
   - ✅ App Store
   - ✅ Volume Purchase (para empresas)

### 11.4 Enviar para Revisión

1. Revisar toda la información
2. Seleccionar build final
3. **Lanzamiento automático después de aprobación**
   - ✅ Liberar automáticamente (recomendado)
   - ❌ Liberar manualmente (puedes elegir fecha)
4. **Revisar y Enviar**
5. Cambiar estado a **"Esperando revisión"**

### 11.5 Tiempo de Revisión

**Estimado:** 24-48 horas (puede ser más)

**Notificaciones:**
- Email cuando la app esté **"En revisión"**
- Email cuando esté **"Aprobada"** o **"Rechazada"**

**Seguimiento:**
App Store Connect → NeXtv → Ver estado actual

---

## 12. Post-Release

### 12.1 Monitoreo Inicial

**Primeras 24-48 horas:**

```bash
Revisar en App Store Connect → Analytics:
- 📊 Impresiones
- 📥 Descargas
- ⭐ Ratings
- 📝 Reviews
- 💥 Crashes (App Analytics)
```

### 12.2 Configurar Crash Reporting

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
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  runApp(MyApp());
}
```

### 12.3 Responder a Reviews

**Apple permite responder a reviews:**

1. App Store Connect → NeXtv → Ratings and Reviews
2. Ver reviews recientes
3. Tocar review → **Respond**
4. Escribir respuesta (máximo 1 por review)

**Buenas prácticas:**
```
Review negativo ejemplo:
"No funciona con mi servidor IPTV"

Respuesta sugerida:
"Hola [Usuario], lamentamos los inconvenientes. Por favor 
verifica que estés usando el protocolo Xtream Codes y que tus 
credenciales sean correctas. Si continúas con problemas, 
contáctanos en support@nextv.app y te ayudaremos 
personalmente. ¡Gracias!"
```

### 12.4 Promocionar la App

- 🐦 Anunciar en redes sociales
- 📧 Email a lista de usuarios beta
- 🌐 Update de sitio web
- 📰 Comunicado de prensa
- 🎥 Video demo en YouTube
- 💬 Comunidad: Reddit, Discord, Telegram

---

## 13. Actualizaciones

### 13.1 Proceso de Actualización

**Preparar nueva versión:**

1. **Incrementar version y build:**
```yaml
# pubspec.yaml
version: 2.0.1+2  # version+build
```

2. **Build y Archive:**
```bash
flutter clean
flutter pub get
flutter build ios --release --obfuscate --split-debug-info=build/ios-debug-info
# Seguir pasos de Archive desde Xcode (sección 7.4)
```

3. **Subir a App Store Connect:**
   - Organizer → Distribute App → Upload

4. **Configurar nuevo release:**
   - App Store Connect → NeXtv → + Versión → 2.0.1
   - Agregar "¿Qué hay de nuevo?"
   - Seleccionar nuevo build
   - Enviar para revisión

**Release Notes Ejemplo:**
```markdown
🔧 NeXtv 2.0.1

CORRECCIONES:
• Solucionado crash al reproducir ciertos formatos de video
• Mejorado rendimiento en iPhone antiguos (6s, 7, 8)
• Corregido problema de sincronización de favoritos
• Arreglado bug de EPG que mostraba horario incorrecto

MEJORAS:
• Carga 30% más rápida de listas de canales
• Reducido consumo de batería en un 20%
• Interfaz más responsive en iPad
• Actualizado reproductor de video a última versión

GRACIAS:
A todos los usuarios que reportaron bugs. 
¡Seguimos mejorando!

¿Disfrutando NeXtv? Déjanos un review ⭐
```

### 13.2 Phased Release

**Recomendado para actualizaciones mayores:**

1. App Store Connect → NeXtv → Versión → Phased Release
2. Activar **"Release this version over a 7-day period"**
3. Apple distribuye gradualmente:
   - Día 1: 1% de usuarios  
   - Día 2: 2%
   - Día 3: 5%
   - Día 4: 10%
   - Día 5: 20%
   - Día 6: 50%
   - Día 7: 100%

**Ventajas:**
- Limita impacto de bugs críticos
- Permite pausar/detener rollout si hay problemas
- Tiempo para fix emergency bugs

### 13.3 Expedited Review (Urgente)

Si tienes un bug crítico:

1. Crear actualización de emergencia
2. Enviar para revisión
3. Seleccionar **"Request Expedited Review"**
4. Justificar:
   ```
   Critical bug causing app crashes for 80% of users.
   This fix resolves the issue immediately.
   ```
5. Apple revisará en 24 horas (normalmente)

**⚠️ Usar solo para emergencias reales**

---

## 14. Troubleshooting

### 14.1 Errores Comunes de Build

#### Error: "No signing certificate found"
**Solución:**
```bash
1. Verificar en Keychain que el certificado esté instalado
2. Xcode → Preferences → Accounts → Download Manual Profiles
3. Intentar Automatic Signing primero
```

#### Error: "Bundle ID does not match"
**Solución:**
```bash
Verificar que en Xcode y App Store Connect el Bundle ID sea exactamente igual:
- Xcode: Runner → General → Bundle Identifier
- App Store Connect: App Information → Bundle ID
```

#### Error: "Pods not found"
**Solución:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

#### Error: "Undefined symbol: OBJC_CLASS$_FLTFirebaseMessagingPlugin"
**Solución:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### 14.2 Rechazos Comunes de App Review

#### Rechazo: "Guideline 2.1 - Performance - App Completeness"
**Razón:** App crashed o no funcionó para el reviewer

**Solución:**
1. Testear exhaustivamente en multiple dispositivos
2. Verificar que credenciales de demo funcionen
3. Proporcionar instrucciones claras
4. Video demo de la app funcionando

#### Rechazo: "Guideline 4.2.2 - Design - Minimum Functionality"
**Razón:** App no tiene suficiente funcionalidad o es solo un reproductor web

**Solución:**
1. Demostrar funcionalidad nativa (favoritos, EPG, etc.)
2. No es solo un wrapper de sitio web
3. Tener features únicas y valor agregado

#### Rechazo: "Guideline 4.3 - Design - Spam"
**Razón:** App muy similar a otras en la tienda

**Solución:**
1. Enfatizar características únicas
2. Diseño distintivo
3. Funcionalidad diferenciada

#### Rechazo: "Guideline 5.1.1 - Legal - Privacy"
**Razón:** Política de privacidad ausente o inadecuada

**Solución:**
1. URL de política debe funcionar
2. Debe ser específica para tu app
3. En el idioma de la app
4. Accesible sin login

#### Rechazo: Contenido inapropiado
**Razón:** Access a contenido con copyright sin autorización

**Solución:**
1. Añadir disclaimers prominentes
2. Sistema de reporte de contenido
3. Filtros de contenido por defecto
4. Explicar que NO proporcionas contenido
5. Apelar con documentación legal

### 14.3 Problemas Post-Release

#### Alto crash rate
**Soluciones:**
1. App Store Connect → Analytics → Crashes
2. Identificar dispositivos/versiones afectados
3. Firebase Crashlytics para stack traces
4. Fix y release actualización urgente
5. Solicitar Expedited Review si es crítico

#### Desinstalaciones altas
**Causas posibles:**
- App crashes frecuentes
- Funcionalidad confusa
- No cumple expectativas

**Soluciones:**
1. Mejorar onboarding
2. Tutorial inicial
3. Fix bugs críticos
4. Solicitar feedback in-app

---

## 15. Recursos y Contacto

### 15.1 Documentación Oficial

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

### 15.2 Soporte de Apple

- App Store Connect → Ayuda → Contactar Soporte
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [Technical Support Incidents](https://developer.apple.com/support/technical/) (2 gratis/año)

### 15.3 Comunidades

- [r/iOSProgramming](https://reddit.com/r/iOSProgramming)
- [Stack Overflow - iOS](https://stackoverflow.com/questions/tagged/ios)
- [Flutter Discord](https://discord.gg/flutter)

---

## 16. Checklist Final

```bash
PRE-BUILD:
☐ Bundle ID configurado correctamente
☐ Version y Build number actualizados
☐ Info.plist sin permisos innecesarios
☐ App icons en todos los tamaños
☐ Display name correcto
☐ Deployment target establecido
☐ Signing configurado (automático o manual)
☐ Capabilities solo las necesarias

APP STORE CONNECT:
☐ App creada con datos correctos
☐ Bundle ID coincide con Xcode
☐ Descripción completa y precisa
☐ Capturas para iPhone 6.7" (mínimo)
☐ Capturas para iPad (si soportas)
☐ Icono 1024x1024 subido
☐ App Preview video (opcional)
☐ Clasificación de edad completada
☐ Política de privacidad URL válida
☐ Pricing & Availability configurado
☐ Nota para reviewer con credenciales demo

BUILD & UPLOAD:
☐ Build compilado sin errores
☐ Archive creado en Xcode
☐ Validación exitosa
☐ Upload a App Store Connect
☐ Build procesado (esperar 10-60 min)
☐ Build seleccionado en versión

TESTFLIGHT (Recomendado):
☐ Testing interno completado
☐ Beta testers externos (opcional)
☐ Feedback incorporado
☐ Bugs críticos resueltos

RELEASE:
☐ Toda la información revisada
☐ Server de demo funcionando 24/7
☐ Enviado para revisión
☐ Esperando aprobación (24-72h)

POST-RELEASE:
☐ Monitoreo de crashes configurado
☐ Analytics revisado
☐ Reviews respondidas
☐ Promoción iniciada
☐ Plan de actualizaciones establecido
```

---

**¡Éxito con tu release en el App Store! 🚀**

**Contacto:** ios-deployment@nextv.app  
**Documentación:** Febrero 2026  
**Versión:** 1.0
