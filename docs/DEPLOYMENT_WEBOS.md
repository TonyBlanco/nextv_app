# Guía de Implementación - LG WebOS (Smart TV)

**App:** NeXtv - IPTV Player  
**Plataforma:** LG WebOS  
**Versión:** 2.0.0  
**Fecha:** Febrero 2026

---

## 📋 Tabla de Contenidos

1. [Introducción a WebOS](#1-introducción-a-webos)
2. [Pre-requisitos](#2-pre-requisitos)
3. [Configuración del Entorno](#3-configuración-del-entorno)
4. [Preparación de la App](#4-preparación-de-la-app)
5. [Build para WebOS](#5-build-para-webos)
6. [Empaquetado IPK](#6-empaquetado-ipk)
7. [Testing en TV Real](#7-testing-en-tv-real)
8. [LG Content Store Setup](#8-lg-content-store-setup)
9. [Submisión y Review](#9-submisión-y-review)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Introducción a WebOS

### 1.1 ¿Qué es WebOS?

**WebOS** es el sistema operativo de LG para Smart TVs basado en tecnología web (HTML5, CSS3, JavaScript).

**Características:**
- Apps son web apps estándar empaquetadas
- Usa tecnologías web: HTML5, CSS3, JavaScript
- Framework: Enyo (opcional) o frameworks modernos
- Build: Flutter Web puede ser empaquetado para WebOS

### 1.2 Versiones de WebOS

| Versión | Año | TVs | Notas |
|---------|-----|-----|-------|
| WebOS 3.x | 2016+ | 2016-2017 models | Básico |
| WebOS 4.x | 2018+ | 2018-2019 models | Mejorado |
| WebOS 5.x | 2019+ | 2019-2020 models | Magic Remote |
| WebOS 6.x | 2021+ | 2021+ models | Actual |
| WebOS 22 | 2022+ | 2022+ models | Latest |
| WebOS 23 | 2023+ | 2023+ models | Latest |

**Recomendación:** Soportar WebOS 4.5+

### 1.3 Especificaciones Técnicas

**Resoluciones soportadas:**
- Full HD: 1920x1080
- 4K UHD: 3840x2160

**Memoria:**
- Mínimo: 256MB recomendado
- Óptimo: 512MB o más

**Input:**
- Control remoto (direccional + OK/Back)
- Magic Remote (puntero + gestos)
- Teclado virtual

---

## 2. Pre-requisitos

### 2.1 Hardware Necesario

```bash
✅ LG Smart TV con WebOS 4.0+ (para testing)
✅ Computadora (Windows, macOS, o Linux)
✅ Misma red WiFi para PC y TV
✅ Cable de red (opcional pero recomendado)
```

### 2.2 Software Necesario

```bash
✅ Node.js 14+ instalado
✅ Flutter SDK 3.x
✅ WebOS SDK (CLI Tools)
✅ Git
✅ Editor de código (VS Code recomendado)
```

### 2.3 Verificar Instalaciones

```bash
# Verificar Node.js
node --version
npm --version

# Verificar Flutter
flutter doctor -v

# Verificar que Flutter web esté habilitado
flutter config --enable-web
```

---

## 3. Configuración del Entorno

### 3.1 Instalar WebOS CLI

```bash
# Instalar globalmente con npm
npm install -g @webosose/ares-cli

# Verificar instalación
ares --version
ares-setup-device --version
```

**Comandos principales de ARES:**
- `ares-package` - Empaquetar app en .ipk
- `ares-install` - Instalar app en TV
- `ares-launch` - Lanzar app en TV
- `ares-setup-device` - Configurar TV target
- `ares-inspect` - Debug remoto

### 3.2 Habilitar Modo Desarrollador en TV

**Pasos:**

1. **En tu LG TV:**
   - Presionar 3 veces el botón **"⚙️ Settings"** del control
   - Aparecerá menú oculto "Developer Mode"
   - Activar **"Dev Mode"**
   - La TV se reiniciará

2. **Configurar Developer Mode App:**
   - Abrir la app **"Developer Mode"** que aparece
   - Activar **"Dev Mode Status"**: ON
   - Activar **"Key Server"**: ON
   - Nota la IP del TV (ej: 192.168.1.100)

**⚠️ IMPORTANTE:**
- Dev Mode caduca cada 50 horas
- Debes renovarlo periódicamente durante desarrollo
- Para renovar: Abrir Developer Mode app → "Reset"

### 3.3 Configurar TV como Target

```bash
# Agregar TV como dispositivo de desarrollo
ares-setup-device

# Opciones del asistente:
# name: lgtv
# description: My LG WebOS TV
# host: 192.168.1.100  (IP de tu TV)
# port: 9922  (puerto por defecto)
# username: prisoner  (usuario por defecto)

# Listar dispositivos configurados
ares-setup-device --list

# Debería mostrar:
# name       deviceinfo               connection  profile
# ---------  -----------------------  ----------  -------
# lgtv       prisoner@192.168.1.100:9922  ssh      tv
```

### 3.4 Generar SSH Key y Configurar

```bash
# Primera conexión requiere SSH key
ares-novacom --device lgtv --getkey

# Seguir instrucciones en TV:
# - Aparecerá prompt en TV
# - Confirmar "Yes" o ingresar passphrase si se muestra
```

---

## 4. Preparación de la App

### 4.1 Estructura de Carpeta WebOS

Tu proyecto Flutter ya tiene una carpeta `webos/`:

```
webos/
├── appinfo.json       # App metadata
├── icon.png           # App icon (80x80)
├── largeIcon.png      # Large icon (130x130)
├── index.html         # Entry point
├── flutter_bootstrap.js
├── flutter.js
├── main.dart.js       # Flutter compiled JS
├── manifest.json
├── version.json
└── assets/            # Asset files
    └── ...
```

### 4.2 Configurar appinfo.json

**Archivo:** `webos/appinfo.json`

```json
{
  "id": "com.nextv.app",
  "version": "2.0.0",
  "vendor": "NeXtv",
  "type": "web",
  "main": "index.html",
  "title": "NeXtv",
  "icon": "icon.png",
  "largeIcon": "largeIcon.png",
  "splashBackground": "splash_bg.png",
  "bgImage": "bg.png",
  "bgColor": "#0A0E1A",
  "iconColor": "#6366F1",
  "uiRevision": 2,
  "requiredMemory": 256,
  "resolution": "1920x1080",
  "transparent": false,
  "visible": true,
  "disableBackHistoryAPI": true,
  "requiredPermissions": [
    "audio",
    "audio.mute",
    "tv"
  ]
}
```

**Campos importantes:**

| Campo | Descripción | Ejemplo |
|-------|-------------|---------|
| `id` | Unique app ID (reverse domain) | com.nextv.app |
| `version` | App version (semantic) | 2.0.0 |
| `vendor` | Developer/company name | NeXtv |
| `type` | App type | web |
| `main` | Entry HTML file | index.html |
| `title` | App name displayed | NeXtv |
| `requiredMemory` | Min memory (MB) | 256 |
| `resolution` | Target resolution | 1920x1080 |
| `uiRevision` | WebOS UI version | 2 |

### 4.3 Preparar Iconos

**Iconos requeridos:**

| Archivo | Tamaño | Uso |
|---------|--------|-----|
| `icon.png` | 80x80 px | App icon pequeño |
| `largeIcon.png` | 130x130 px | App icon grande (launcher) |
| `splash_bg.png` | 1920x1080 px | Splash screen (opcional) |
| `bg.png` | 1920x1080 px | Background (opcional) |

**Generar iconos:**

```bash
# Desde un icono 1024x1024
# Usar ImageMagick o herramienta online

# Instalar ImageMagick
brew install imagemagick  # macOS
sudo apt install imagemagick  # Linux

# Resize
convert icon_1024.png -resize 80x80 icon.png
convert icon_1024.png -resize 130x130 largeIcon.png
```

### 4.4 Optimizar index.html para WebOS

**Archivo:** `webos/index.html`

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>NeXtv</title>
  
  <!-- WebOS Specific -->
  <script src="webOSTVjs-1.2.4/webOSTV.js"></script>
  
  <!-- Flutter Web -->
  <link rel="manifest" href="manifest.json">
  <script src="flutter.js" defer></script>
  
  <style>
    body {
      margin: 0;
      padding: 0;
      overflow: hidden;
      background-color: #0A0E1A;
    }
    
    #loading {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      color: white;
      font-family: Arial, sans-serif;
      font-size: 24px;
    }
  </style>
</head>
<body>
  <div id="loading">Cargando NeXtv...</div>
  
  <script>
    // WebOS initialization
    if (typeof webOS !== 'undefined') {
      console.log('WebOS detected');
      
      // Handle back button
      document.addEventListener('webOSRelaunch', function() {
        console.log('App relaunched');
      });
      
      // Handle visibility
      document.addEventListener('webOSLaunch', function() {
        console.log('App launched');
      });
    }
    
    // Flutter initialization
    window.addEventListener('load', function(ev) {
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        }
      }).then(function(engineInitializer) {
        return engineInitializer.initializeEngine();
      }).then(function(appRunner) {
        document.getElementById('loading').remove();
        return appRunner.runApp();
      });
    });
  </script>
</body>
</html>
```

---

## 5. Build para WebOS

### 5.1 Build Flutter Web

```bash
# Build optimizado para producción
flutter build web --release \
  --web-renderer canvaskit \
  --base-href "/" \
  --pwa-strategy=offline-first

# Output en: build/web/
```

**Opciones importantes:**

| Flag | Descripción |
|------|-------------|
| `--web-renderer canvaskit` | Mejor performance, consistencia |
| `--web-renderer html` | Alternativa más ligera |
| `--base-href` | Base path para assets |
| `--pwa-strategy` | Offline support |

### 5.2 Copiar Build a Carpeta WebOS

```bash
# Crear script para automatizar
# Archivo: build-webos.sh

#!/bin/bash

echo "🔨 Building Flutter Web..."
flutter build web --release --web-renderer canvaskit

echo "📦 Copying to webos/ folder..."
rm -rf webos/assets webos/*.js webos/*.json webos/canvaskit
cp -r build/web/* webos/

echo "✅ WebOS build ready!"
echo "📂 Output: webos/"
```

```bash
# Dar permisos de ejecución
chmod +x build-webos.sh

# Ejecutar
./build-webos.sh
```

### 5.3 Verificar Estructura Final

```bash
webos/
├── appinfo.json          ✅ Metadata
├── icon.png              ✅ Small icon
├── largeIcon.png         ✅ Large icon
├── index.html            ✅ Entry point
├── flutter.js            ✅ Flutter loader
├── main.dart.js          ✅ Compiled Dart
├── flutter_service_worker.js
├── manifest.json
├── version.json
├── assets/               ✅ Flutter assets
│   ├── AssetManifest.json
│   ├── FontManifest.json
│   ├── fonts/
│   └── packages/
└── canvaskit/            ✅ CanvasKit WASM
    ├── canvaskit.js
    ├── canvaskit.wasm
    └── ...
```

---

## 6. Empaquetado IPK

### 6.1 Empaquetar con ARES

```bash
# Desde la raíz del proyecto
ares-package webos/ -o packages/

# Output:
# packages/com.nextv.app_2.0.0_all.ipk
```

**Opciones de ares-package:**

```bash
# Especificar output directory
ares-package webos/ -o ./output

# Verbose mode
ares-package webos/ -v

# Excluir archivos
ares-package webos/ --exclude ".git" --exclude "*.md"
```

### 6.2 Verificar IPK

```bash
# Ver contenido del IPK
tar -tzf packages/com.nextv.app_2.0.0_all.ipk

# Debería mostrar:
# appinfo.json
# icon.png
# largeIcon.png
# index.html
# ...
```

**Tamaño recomendado:**
- Ideal: < 50 MB
- Máximo: 100 MB (límite de LG Store)

**Si es muy grande:**
```bash
# Optimizar assets
- Comprimir imágenes (ImageOptim, TinyPNG)
- Minimizar JS (ya hecho por Flutter en --release)
- Eliminar assets no usados
```

---

## 7. Testing en TV Real

### 7.1 Instalar en TV

```bash
# Instalar IPK
ares-install --device lgtv packages/com.nextv.app_2.0.0_all.ipk

# Si es exitoso:
# Success instalando com.nextv.app
```

### 7.2 Lanzar App

```bash
# Lanzar app instalada
ares-launch --device lgtv com.nextv.app

# Output:
# Launched application com.nextv.app
```

### 7.3 Ver Logs en Tiempo Real

```bash
# Ver logs de la app ejecutándose
ares-launch --device lgtv com.nextv.app --inspect

# O separadamente:
ares-inspect --device lgtv --app com.nextv.app
```

### 7.4 Debugging con Chrome DevTools

1. **Lanzar con inspect:**
```bash
ares-inspect --device lgtv --app com.nextv.app --open
```

2. **Se abre Chrome DevTools automáticamente**

3. **Puedes:**
   - Ver console logs
   - Inspeccionar elementos
   - Network tab
   - Performance profiling

### 7.5 Testing Checklist en TV

```bash
✅ App se instala sin errores
✅ App lanza y muestra splash screen
✅ UI se renderiza correctamente en 1920x1080
✅ Navegación con control remoto funciona
   ✅ Flechas direccionales
   ✅ Botón OK
   ✅ Botón Back
✅ Login funciona correctamente
✅ Lista de canales carga
✅ Videos se reproducen sin problemas
✅ Audio funciona
✅ Controles de playback responden
✅ Favoritos se guardan
✅ Performance es aceptable (no lag)
✅ No hay memory leaks (dejar corriendo 30 min)
✅ App responde a sleep/wake del TV
```

### 7.6 Control Remoto Testing

**Mapeo de botones:**

| Botón TV | Evento Web | Acción |
|----------|------------|--------|
| ↑↓←→ | Arrow keys | Navegación |
| OK | Enter | Seleccionar |
| Back | Backspace | Volver |
| Home | webOSRelaunch | Minimize app |
| Números | 0-9 keys | Input directo |

**Implementar en Flutter:**

```dart
import 'package:flutter/services.dart';

// En tu widget
RawKeyboardListener(
  focusNode: FocusNode(),
  onKey: (RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Navegar arriba
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        // Seleccionar
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        // Volver
      }
    }
  },
  child: YourWidget(),
)
```

### 7.7 Desinstalar App (si es necesario)

```bash
# Desinstalar app del TV
ares-install --device lgtv --remove com.nextv.app
```

---

## 8. LG Content Store Setup

### 8.1 Crear Cuenta de Desarrollador LG

1. Ir a [LG Seller Lounge](https://seller.lgappstv.com/)
2. **Sign Up** → **Create Account**
3. Completar información:
   - Email
   - Nombre/Empresa
   - País
   - Teléfono
   - Dirección
4. Verificar email
5. Completar perfil de vendedor:
   - Tipo: Individual o Company
   - Documentos legales (si es company)
   - Información fiscal

**Tiempo de aprobación:** 3-5 días hábiles

### 8.2 Registrar App

1. **Login** a LG Seller Lounge
2. **Apps** → **Register New App**
3. **Basic Information:**
   - App Name: NeXtv
   - App ID: com.nextv.app (debe coincidir con appinfo.json)
   - Category: Video
   - Sub-category: Media Player
   - Version: 2.0.0

4. **App Description:**

```markdown
NeXtv - Reproductor IPTV Premium para LG Smart TV

Disfruta de tu contenido IPTV favorito en la pantalla grande.

🎬 CARACTERÍSTICAS:
• Soporte para protocolo Xtream Codes API
• TV en vivo con EPG (Guía electrónica de programación)
• Películas y series bajo demanda (VOD)
• Sistema de favoritos inteligente
• Catch-up TV
• Diseño optimizado para TV (10-foot UI)
• Compatible con Magic Remote
• Control parental integrado

📺 OPTIMIZADO PARA LG:
• Navegación con control remoto
• Soporte para Magic Remote
• Resolución Full HD y 4K
• Audio multicanal
• Performance optimizado

⚠️ IMPORTANTE:
NeXtv es un reproductor IPTV. NO proporcionamos contenido.
Requiere suscripción IPTV válida con proveedor autorizado.

🔒 PRIVACIDAD:
Sin recopilación de datos personales.
Credenciales almacenadas localmente de forma segura.

📧 SOPORTE:
support@nextv.app
```

5. **Screenshots:**
   - Mínimo: 5 capturas
   - Tamaño: 1280x720 o 1920x1080
   - Formato: PNG o JPG
   - Contenido: UI de la app en TV

6. **Icons:**
   - 80x80 px
   - 130x130 px
   - (Ya preparados en sección 4.3)

7. **Video (Opcional pero recomendado):**
   - Demo de la app en funcionamiento
   - Duración: 30-60 segundos
   - Formato: MP4, FLV
   - Resolución: 1280x720 o superior

### 8.3 Upload IPK

1. **App Upload** → **Select File**
2. Elegir: `com.nextv.app_2.0.0_all.ipk`
3. Upload (puede tardar varios minutos)
4. Verificación automática:
   - ✅ appinfo.json válido
   - ✅ Iconos presentes
   - ✅ Estructura correcta
   - ✅ Tamaño < 100MB

### 8.4 Configurar Países y Precio

**Available Countries:**
- Seleccionar países objetivo
- Ejemplo: España, México, Argentina, Colombia, etc.

**Pricing:**
- Gratuita (recomendado para IPTV apps)
- De pago (requiere configuración de payment provider)

### 8.5 Documentos Legales

**Privacy Policy (REQUERIDO):**
- URL pública de tu política de privacidad
- Debe estar en idioma de cada país donde distribuyes

**Terms of Service (opcional):**
- URL de términos de servicio

**Age Rating:**
- Completar cuestionario similar a otras stores
- Resultado esperado: 12+ o 17+

### 8.6 Test Devices

LG permite probar en dispositivos específicos antes de release público:

1. **Test Devices** → **Add Device**
2. Ingresar Device ID del TV
3. App estará disponible solo en ese TV para testing
4. Feedback antes de publicación global

**Obtener Device ID:**
```
TV Settings → General → About This TV → TV Information
Device ID: XXXXX-XXXXX-XXXXX
```

---

## 9. Submisión y Review

### 9.1 Pre-Submission Checklist

```bash
☐ App funciona correctamente en TV de prueba
☐ Navegación con control remoto sin problemas
☐ Videos se reproducen correctamente
☐ No crashes ni freezes
☐ Performance aceptable
☐ IPK < 100MB
☐ All strings en idioma target
☐ Screenshots de alta calidad
☐ Descripción completa y precisa
☐ Política de privacidad URL válida
☐ Iconos en todos los tamaños
☐ Documentos legales completados
☐ Pricing y países configurados
☐ Disclaimers sobre contenido IPTV incluidos
```

### 9.2 Enviar para Revisión

1. **Review Summary** → Revisar toda la información
2. **Submit for Review**
3. Cambiar estado a **"In Review"**

**Nota para Reviewer (si disponible):**
```
LG Review Team,

NeXtv is an IPTV player app requiring user credentials from 
their IPTV provider to function.

TEST CREDENTIALS:
Server URL: http://demo.iptv-provider.com:8080
Username: demo
Password: demo123

HOW TO TEST:
1. Launch app
2. Enter test credentials above
3. Click "Login"
4. Browse channels and select one to play

IMPORTANT:
- NeXtv does NOT provide IPTV content or services
- Users must have their own legal IPTV subscription
- Test server contains only legal demo content
- We have clear disclaimers about user responsibility

FEATURES TO TEST:
- Login with IPTV credentials
- Channel browsing with remote
- Video playback
- Favorites system
- EPG (program guide)
- Parental controls (PIN: 1234)

For questions, contact: review@nextv.app

Thank you!
```

### 9.3 Proceso de Revisión

**Tiempo estimado:** 7-14 días hábiles

**Fases:**
1. **Submitted:** En cola
2. **In Review:** LG está revisando
3. **Need Information:** Requieren aclaraciones
4. **Approved:** Aprobado, listo para publish
5. **Rejected:** Rechazado con razones

**Notificaciones:**
- Email cuando cambie estado
- Dashboard en Seller Lounge actualizado

### 9.4 Posibles Razones de Rechazo

| Razón | Solución |
|-------|----------|
| App no funciona | Testear exhaustivamente antes de submit |
| Crashes o freezes | Fix bugs, mejorar estabilidad |
| Performance pobre | Optimizar, reducir memoria |
| Navegación confusa | Mejorar UX para TV |
| Contenido inapropiado | Disclaimers, filtros, age rating |
| Metadatos incorrectos | Revisar appinfo.json |
| Iconos faltantes o erróneos | Agregar todos los tamaños |
| Política de privacidad ausente | Crear y subir URL |

---

## 10. Post-Release

### 10.1 Publicar App

Una vez aprobado:
1. **Apps** → **NeXtv** → **Publish**
2. Confirmar países y pricing
3. **Publish Now** o agendar fecha

**App estará disponible en LG Content Store en ~24 horas**

### 10.2 Monitorear

**Seller Lounge Dashboard:**
- 📊 Descargas
- ⭐ Ratings
- 📝 Reviews
- 🐛 Crash reports
- 📈 Analytics

### 10.3 Responder Reviews

Similar a otras stores:
- Leer reviews de usuarios
- Responder preguntas
- Agradecer feedback positivo
- Ofrecer ayuda en problemas

### 10.4 Actualizaciones

**Proceso:**

1. Incrementar version en appinfo.json:
```json
{
  "version": "2.0.1"
}
```

2. Rebuild y repackage:
```bash
./build-webos.sh
ares-package webos/ -o packages/
```

3. Upload new IPK en Seller Lounge
4. Agregar release notes:
```
v2.0.1 - Mejoras y Correcciones

• Corregido crash al cambiar canales rápidamente
• Mejorado rendimiento en TVs más antiguos
• Arreglado bug de favoritos
• Actualizado reproductor de video
• Reducido uso de memoria

Gracias por usar NeXtv!
```

5. Submit para review nuevamente

---

## 11. Troubleshooting

### 11.1 Problemas de Desarrollo

#### Error: "ares: command not found"
**Solución:**
```bash
# Verificar instalación
npm list -g @webosose/ares-cli

# Reinstalar
npm uninstall -g @webosose/ares-cli
npm install -g @webosose/ares-cli

# Actualizar PATH si es necesario
export PATH=$PATH:$(npm get prefix)/bin
```

#### Error: "Connection refused" al conectar a TV
**Soluciones:**
1. Verificar que TV esté en misma red
2. Verificar IP del TV (puede haber cambiado)
3. Re-configurar device:
```bash
ares-setup-device --modify lgtv
# Actualizar IP si cambió
```
4. Verificar que Dev Mode no haya expirado en TV
5. Reiniciar Developer Mode app en TV

#### Error: "Dev Mode has expired"
**Solución:**
```bash
# En TV:
# Abrir Developer Mode app
# Presionar "Reset" o "Extend"
# Re-configurar SSH key:
ares-novacom --device lgtv --getkey
```

#### Error: Package install failed
**Soluciones:**
1. Verificar que appinfo.json sea válido
2. Verificar que iconos existan
3. Verificar estructura de carpetas
4. Intentar desinstalar versión anterior primero:
```bash
ares-install --device lgtv --remove com.nextv.app
ares-install --device lgtv packages/com.nextv.app_2.0.0_all.ipk
```

### 11.2 Problemas de Performance

#### App es lenta en TV
**Optimizaciones:**

1. **Usar html renderer en vez de canvaskit:**
```bash
flutter build web --web-renderer html
```

2. **Reducir complejidad de UI:**
```dart
// Usar const constructors
const Text('Hello');

// Lazy load de listas largas
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ...
);
```

3. **Optimizar imágenes:**
```dart
// Usar cached images con max width/height
CachedNetworkImage(
  imageUrl: url,
  maxWidth: 300,
  maxHeight: 300,
);
```

4. **Limitar animaciones:**
```dart
// Reducir duración de animaciones
Duration(milliseconds: 200) // en vez de 500
```

#### Memory leaks
**Solución:**
```dart
// Dispose de controllers
@override
void dispose() {
  _controller.dispose();
  _scrollController.dispose();
  super.dispose();
}

// Usar autoDispose en Riverpod
final myProvider = StreamProvider.autoDispose((ref) {
  // ...
});
```

### 11.3 Problemas de Navegación

#### Control remoto no responde
**Solución:**

1. **Implementar FocusNodes correctamente:**
```dart
class ChannelList extends StatefulWidget {
  @override
  _ChannelListState createState() => _ChannelListState();
}

class _ChannelListState extends State<ChannelList> {
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: ListView(...),
    );
  }
}
```

2. **Agregar navegación manual si es necesario:**
```dart
RawKeyboardListener(
  focusNode: FocusNode(),
  autofocus: true,
  onKey: (event) {
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowDown:
          _moveDown();
          break;
        case LogicalKeyboardKey.arrowUp:
          _moveUp();
          break;
        case LogicalKeyboardKey.enter:
          _select();
          break;
      }
    }
  },
  child: ...,
)
```

---

## 12. Recursos Adicionales

### 12.1 Documentación Oficial

- [LG Developer Portal](https://webostv.developer.lge.com/)
- [WebOS TV SDK](https://webostv.developer.lge.com/sdk/installation/)
- [LG Seller Lounge](https://seller.lgappstv.com/)
- [WebOS TV API Reference](https://webostv.developer.lge.com/api/)

### 12.2 Herramientas

- **ARES CLI:** Command line tools para WebOS
- **WebOS TV Emulator:** Emulador de TV (limitado)
- **Chrome DevTools:** Remote debugging
- **ImageMagick:** Resize de iconos

### 12.3 Comunidades

- [WebOS TV Forum](https://forum.developer.lge.com/)
- [Stack Overflow - WebOS](https://stackoverflow.com/questions/tagged/webos)
- [Reddit r/webOS](https://reddit.com/r/webOS)

---

## 13. Checklist Final

```bash
DESARROLLO:
☐ Node.js y ARES CLI instalados
☐ TV en Dev Mode configurado
☐ TV configurado como target device
☐ Flutter web build funcional
☐ webos/ folder con todos los archivos necesarios
☐ appinfo.json correctamente configurado
☐ Iconos en todos los tamaños requeridos
☐ Build script automatizado creado

TESTING:
☐ IPK empaquetado sin errores
☐ Instalado y testeado en TV real
☐ Navegación con control remoto funciona
☐ Videos se reproducen correctamente
☐ Performance aceptable
☐ No memory leaks
☐ Debugging con Chrome DevTools
☐ Todos los features probados

LG SELLER LOUNGE:
☐ Cuenta de desarrollador creada y aprobada
☐ App registrada con información completa
☐ Descripción en todos los idiomas target
☐ Screenshots de alta calidad subidas
☐ Iconos subidos
☐ Video demo (opcional)
☐ Política de privacidad URL válida
☐ Pricing y países configurados
☐ Age rating completado
☐ Documentos legales OK

SUBMISSION:
☐ Pre-submission checklist completado
☐ Nota para reviewer preparada con credenciales demo
☐ IPK subido correctamente
☐ Enviado para revisión
☐ Esperando aprobación (7-14 días)

POST-RELEASE:
☐ App publicada en LG Content Store
☐ Monitoreo de downloads y reviews
☐ Plan de actualizaciones definido
☐ Soporte al usuario establecido
```

---

**¡Éxito con tu release en LG Content Store! 📺**

**Contacto:** webos-deployment@nextv.app  
**Documentación:** Febrero 2026  
**Versión:** 1.0
