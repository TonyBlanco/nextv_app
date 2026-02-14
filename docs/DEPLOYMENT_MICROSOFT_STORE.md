# Guía de Implementación - Microsoft Store (Windows)

**App:** NeXtv - IPTV Player  
**Plataforma:** Windows 10/11  
**Versión:** 2.0.0  
**Fecha:** Febrero 2026

---

## 📋 Tabla de Contenidos

1. [Introducción](#1-introducción)
2. [Pre-requisitos](#2-pre-requisitos)
3. [Configuración del Entorno](#3-configuración-del-entorno)
4. [Preparación de la App](#4-preparación-de-la-app)
5. [Build para Windows](#5-build-para-windows)
6. [Empaquetado MSIX](#6-empaquetado-msix)
7. [Testing Local](#7-testing-local)
8. [Partner Center Setup](#8-partner-center-setup)
9. [Submisión y Revisión](#9-submisión-y-revisión)
10. [Post-Release](#10-post-release)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Introducción

### 1.1 Microsoft Store para Windows

**Microsoft Store** es la tienda oficial de apps para Windows 10 y Windows 11.

**Características:**
- Apps nativas de Windows
- Distribución global
- Updates automáticos
- Sandbox de seguridad
- Compras in-app integradas

### 1.2 Tipos de Apps

| Tipo | Descripción | Para NeXtv |
|------|-------------|------------|
| UWP | Universal Windows Platform | ❌ No (requiere reescritura) |
| WinUI 3 | Modern Windows apps | ❌ No (requiere C#/C++) |
| Win32 | Traditional desktop apps | ✅ Sí (empaquetado en MSIX) |
| Flutter | Nativo de Flutter | ✅ Sí (compilado a Win32) |

**NeXtv usa Flutter → Compila a Win32 → Empaqueta en MSIX → Microsoft Store**

### 1.3 Requisitos de Microsoft Store

- ✅ Windows 10 versión 1809 o superior
- ✅ Arquitecturas: x64, ARM64
- ✅ Package formato: MSIX
- ✅ Signing con certificado válido
- ✅ Pasar certificación de Microsoft

---

## 2. Pre-requisitos

### 2.1 Hardware y Software

```bash
✅ Windows 10 (build 1809+) o Windows 11
✅ Visual Studio 2022 Community o superior
✅ Windows 10 SDK (10.0.17763.0 o superior)
✅ Flutter SDK 3.x configurado para Windows
✅ Git
✅ Cuenta de Microsoft (para Partner Center)
✅ $19 USD (registro individual) o $99 USD (empresa)
```

### 2.2 Verificar Instalaciones

```powershell
# Verificar Flutter para Windows
flutter doctor -v

# Verificar que Windows esté habilitado
flutter config --enable-windows-desktop

# Verificar Visual Studio
# Debe tener instalado:
# - Desktop development with C++
# - Universal Windows Platform development (opcional)
```

### 2.3 Instalar Windows App SDK

```powershell
# Instalar con winget
winget install Microsoft.WindowsAppSDK

# O desde Visual Studio Installer:
# Individual components → Windows 11 SDK
```

---

## 3. Configuración del Entorno

### 3.1 Configurar Visual Studio

**Componentes necesarios:**

1. Abrir **Visual Studio Installer**
2. Modificar instalación
3. Asegurar que estén instalados:
   - ✅ Desktop development with C++
   - ✅ C++ CMake tools for Windows
   - ✅ Windows 10/11 SDK (última versión)
   - ✅ MSBuild
   - ✅ .NET desktop development (opcional)

### 3.2 Habilitar Desarrollo de Apps

```powershell
# Habilitar Developer Mode en Windows
# Settings → Update & Security → For developers → Developer mode
```

### 3.3 Instalar Certificado de Desarrollo

Para testing local, necesitas un certificado:

```powershell
# Generar certificado auto-firmado (solo para desarrollo)
New-SelfSignedCertificate `
  -Type Custom `
  -Subject "CN=NeXtv Development, O=NeXtv, C=ES" `
  -KeyUsage DigitalSignature `
  -FriendlyName "NeXtv Dev Certificate" `
  -CertStoreLocation "Cert:\CurrentUser\My" `
  -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

# Exportar certificado
# Certificado estará en: Cert:\CurrentUser\My
# Exportar como .pfx desde certmgr.msc
```

**⚠️ IMPORTANTE:** Para Microsoft Store, usarás certificado de Microsoft (automático)

---

## 4. Preparación de la App

### 4.1 Estructura de Windows en Flutter

```
windows/
├── CMakeLists.txt              # Build configuration
├── runner/
│   ├── main.cpp                # Entry point
│   ├── Runner.rc               # Resources
│   ├── runner.exe.manifest     # App manifest
│   └── resources/
│       └── app_icon.ico        # App icon
└── flutter/
    └── CMakeLists.txt
```

### 4.2 Configurar App Identity

**Archivo:** `windows/runner/Runner.rc`

```cpp
// Configurar versión
#define VERSION_AS_NUMBER 2,0,0,0
#define VERSION_AS_STRING "2.0.0.0"

// Metadata
VS_VERSION_INFO VERSIONINFO
 FILEVERSION VERSION_AS_NUMBER
 PRODUCTVERSION VERSION_AS_NUMBER
 FILEFLAGSMASK VS_FFI_FILEFLAGSMASK
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "040904e4"
        BEGIN
            VALUE "CompanyName", "NeXtv" "\0"
            VALUE "FileDescription", "NeXtv - IPTV Player" "\0"
            VALUE "FileVersion", VERSION_AS_STRING "\0"
            VALUE "InternalName", "nextv" "\0"
            VALUE "LegalCopyright", "Copyright (C) 2026 NeXtv. All rights reserved." "\0"
            VALUE "OriginalFilename", "nextv.exe" "\0"
            VALUE "ProductName", "NeXtv" "\0"
            VALUE "ProductVersion", VERSION_AS_STRING "\0"
        END
    END
END
```

### 4.3 Configurar Icono de la App

**Crear icono .ico con múltiples resoluciones:**

**Tamaños necesarios:**
- 16x16
- 32x32
- 48x48
- 64x64
- 128x128
- 256x256

**Herramientas:**
- [IconsFlow](https://iconsflow.com/)
- [IcoFX](https://icofx.ro/)
- [Online ICO Converter](https://www.icoconverter.com/)

**Ubicación:**
```
windows/runner/resources/app_icon.ico
```

### 4.4 Configurar Manifest

**Archivo:** `windows/runner/runner.exe.manifest`

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity
    version="2.0.0.0"
    processorArchitecture="*"
    name="com.nextv.iptv"
    type="win32"/>
  
  <description>NeXtv - Premium IPTV Player</description>
  
  <!-- Windows 10/11 compatibility -->
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <!-- Windows 10 -->
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>  
      <!-- Windows 11 -->
      <supportedOS Id="{35138b9a-5d96-4fbd-8e2d-a2440225f93a}"/>
    </application>
  </compatibility>
  
  <!-- DPI Awareness -->
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true</dpiAware>
      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
    </windowsSettings>
  </application>
  
  <!-- Trust Info (para UAC) -->
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level="asInvoker" uiAccess="false"/>
      </requestedPrivileges>
    </security>
  </trustInfo>
</assembly>
```

---

## 5. Build para Windows

### 5.1 Build Básico

```powershell
# Limpiar builds anteriores
flutter clean

# Instalar dependencias
flutter pub get

# Build release
flutter build windows --release

# Output en:
# build\windows\x64\runner\Release\
```

### 5.2 Verificar Estructura del Build

```
build\windows\x64\runner\Release\
├── nextv.exe               # Ejecutable principal
├── flutter_windows.dll     # Flutter engine
├── data\
│   ├── icudtl.dat         # Datos de internacionalización
│   ├── flutter_assets\    # Assets de la app
│   └── ...
└── plugins\               # Plugins nativos
    └── ...
```

### 5.3 Testing Manual

```powershell
# Ejecutar directamente
cd build\windows\x64\runner\Release
.\nextv.exe

# Verificar:
# ✅ App lanza sin errores
# ✅ UI se renderiza correctamente
# ✅ Funcionalidad completa trabaja
# ✅ Videos se reproducen
# ✅ No hay crashes
```

---

## 6. Empaquetado MSIX

### 6.1 Instalar MSIX Packaging Tool

**Opción A: Desde Microsoft Store**
1. Abrir Microsoft Store
2. Buscar "MSIX Packaging Tool"
3. Instalar (gratis)

**Opción B: Desde línea de comandos**
```powershell
winget install Microsoft.MSIXPackagingTool
```

### 6.2 Crear Configuración MSIX

**Crear archivo:** `msix_config.xml` en la raíz del proyecto

```xml
<?xml version="1.0" encoding="utf-8"?>
<MsixManifest xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
              xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
              xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
              IgnorableNamespaces="uap rescap">
  
  <!-- Package Identity -->
  <Identity Name="NeXtv.IPTVPlayer"
            Publisher="CN=Your Publisher Name"
            Version="2.0.0.0"
            ProcessorArchitecture="x64" />
  
  <!-- Properties -->
  <Properties>
    <DisplayName>NeXtv</DisplayName>
    <PublisherDisplayName>NeXtv</PublisherDisplayName>
    <Logo>Assets\StoreLogo.png</Logo>
    <Description>Premium IPTV Player for Windows</Description>
  </Properties>
  
  <!-- Dependencies -->
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0" MaxVersionTested="10.0.22621.0" />
  </Dependencies>
  
  <!-- Resources -->
  <Resources>
    <Resource Language="es-ES"/>
    <Resource Language="en-US"/>
  </Resources>
  
  <!-- Applications -->
  <Applications>
    <Application Id="NeXtv" Executable="nextv.exe" EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements
        DisplayName="NeXtv"
        Description="Premium IPTV Player"
        BackgroundColor="transparent"
        Square150x150Logo="Assets\Square150x150Logo.png"
        Square44x44Logo="Assets\Square44x44Logo.png">
        <uap:DefaultTile Wide310x150Logo="Assets\Wide310x150Logo.png" />
        <uap:SplashScreen Image="Assets\SplashScreen.png" />
      </uap:VisualElements>
      
      <!-- File associations (opcional) -->
      <Extensions>
        <uap:Extension Category="windows.fileTypeAssociation">
          <uap:FileTypeAssociation Name="m3u">
            <uap:SupportedFileTypes>
              <uap:FileType>.m3u</uap:FileType>
              <uap:FileType>.m3u8</uap:FileType>
            </uap:SupportedFileTypes>
          </uap:FileTypeAssociation>
        </uap:Extension>
      </Extensions>
    </Application>
  </Applications>
  
  <!-- Capabilities -->
  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
    <Capability Name="internetClient" />
    <Capability Name="internetClientServer" />
    <Capability Name="privateNetworkClientServer" />
  </Capabilities>
  
</MsixManifest>
```

### 6.3 Preparar Assets para MSIX

**Assets requeridos:**

Crear carpeta `windows/assets/` con las siguientes imágenes:

| Archivo | Tamaño | Uso |
|---------|--------|-----|
| StoreLogo.png | 50x50 | Logo de la tienda |
| Square44x44Logo.png | 44x44 | Icono pequeño |
| Square150x150Logo.png | 150x150 | Tile mediano |
| Wide310x150Logo.png | 310x150 | Tile ancho |
| SplashScreen.png | 620x300 | Splash screen |
| LargeTile.png | 310x310 | Tile grande (opcional) |

**Generar assets automáticamente:**

Usar herramienta online o script:

```powershell
# Usando ImageMagick
magick convert icon_1024.png -resize 50x50 StoreLogo.png
magick convert icon_1024.png -resize 44x44 Square44x44Logo.png
magick convert icon_1024.png -resize 150x150 Square150x150Logo.png
# ... etc
```

### 6.4 Empaquetar con flutter_distributor (Recomendado)

**Instalar:**
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_distributor: ^0.5.0
```

```bash
flutter pub get
flutter pub global activate flutter_distributor
```

**Crear configuración:**  
**Archivo:** `distribute_options.yaml`

```yaml
output: dist/
releases:
  - name: windows
    jobs:
      - name: msix
        package:
          platform: windows
          target: msix
          build_args:
            target-platform: windows-x64
        msix_config:
          display_name: NeXtv
          publisher_display_name: NeXtv
          identity_name: NeXtv.IPTVPlayer
          publisher: CN=YourPublisher
          version: 2.0.0.0
          logo_path: windows/assets/StoreLogo.png
          capabilities: internetClient,internetClientServer,privateNetworkClientServer
          store: true
```

**Empaquetar:**
```bash
flutter_distributor package --platform windows --targets msix
```

### 6.5 Empaquetar Manualmente con MSBuild

**Alternativa si flutter_distributor falla:**

1. **Abrir Visual Studio 2022**
2. **Create new project** → **Blank App (Package)** → **Windows Application Packaging Project**
3. **Add existing project** → Apuntar a build de Flutter
4. **Project** → **Properties**:
   - Package name: com.nextv.iptv
   - Display name: NeXtv
   - Publisher: CN=YourName
   - Version: 2.0.0.0
5. **Build** → **Create App Packages**
6. Seguir wizard

### 6.6 Signing del MSIX

**Para Microsoft Store:**
- Microsoft firma automáticamente tu package
- No necesitas certificado propio

**Para sideloading (fuera de Store):**
```powershell
# Firmar con certificado
SignTool sign /fd SHA256 /a /f MyCertificate.pfx /p <password> nextv.msix

# Instalar certificado en trusted root (necesario para install)
Import-Certificate -FilePath MyCertificate.cer -CertStoreLocation Cert:\LocalMachine\Root
```

---

## 7. Testing Local

### 7.1 Instalar MSIX Localmente

```powershell
# Método 1: PowerShell
Add-AppxPackage -Path "C:\path\to\nextv.msix"

# Método 2: Doble clic en el archivo .msix
# Windows preguntará si quieres instalar
```

### 7.2 Testing Checklist

```bash
✅ App se instala sin errores
✅ Aparece en Start Menu con icono correcto
✅ App lanza desde Start Menu
✅ Ventana se renderiza correctamente
✅ Todas las funciones trabajan:
   ✅ Login con credenciales
   ✅ Lista de canales
   ✅ Reproducción de video
   ✅ Favoritos
   ✅ EPG
   ✅ Búsqueda
✅ No hay crashes
✅ Performance aceptable
✅ Video playback fluido
✅ Audio sincronizado
✅ Recursos del sistema aceptables:
   ✅ CPU < 30% en idle
   ✅ Memoria < 500MB
   ✅ No memory leaks
✅ Minimize/maximize funciona
✅ Close funciona correctamente
✅ Reinstalación funciona
✅ Desinstalación limpia
```

### 7.3 Desinstalar

```powershell
# Ver apps instaladas
Get-AppxPackage -Name "*nextv*"

# Desinstalar
Remove-AppxPackage -Package [FullPackageName]

# O desde Settings → Apps → Installed apps → NeXtv → Uninstall
```

---

## 8. Partner Center Setup

### 8.1 Crear Cuenta de Desarrollador

1. Ir a [Microsoft Partner Center](https://partner.microsoft.com/dashboard)
2. **Sign in** con cuenta de Microsoft
3. **Settings** → **Developer settings** → **Account settings**
4. **Enroll** en Developer Program:
   - **Individual:** $19 USD (solo tú)
   - **Company:** $99 USD (requiere company verification)
5. Completar información:
   - Nombre/Empresa
   - País
   - Email de contacto
   - Información fiscal (para pagos)
6. Pagar fee de registro
7. Esperar aprobación (24-48 horas para individual, 1-2 semanas para company)

### 8.2 Crear Nueva App

1. **Apps and games** → **+ New product** → **Microsoft Store app**
2. **Name:** NeXtv (verificar disponibilidad)
   - ⚠️ Nombre debe ser único en toda la tienda
   - Se reserva por 3 meses
3. Confirmar
4. Se crea la app con provisionary Identity

### 8.3 Configurar Identity

**Importante para MSIX:**

1. **App overview** → **Product identity**
2. Anotar:
   - **Package ID:** NeXtv.IPTVPlayer  
   - **Publisher:** CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   - **Publisher display name:** Tu nombre

3. **Actualizar estos valores en msix_config.xml:**
```xml
<Identity Name="NeXtv.IPTVPlayer"
          Publisher="CN=[Copiar de Partner Center]"
          Version="2.0.0.0" />
```

### 8.4 Pricing and Availability

1. **Pricing and availability**
2. **Markets:** Seleccionar países (ej: España, USA, LatAm)
3. **Pricing:**
   - **Free** (recomendado para IPTV)
   - Pricing model: Free
4. **Free trial:** No
5. **Sale pricing:** No aplicable si es gratis
6. **Organizational licensing:** Allow (opcional)
7. **Microsoft Store for Business:** Allow (opcional)

### 8.5 Properties

**App properties:**

**Category:** Entertainment  
**Subcategory:** Video players

**Privacy policy URL:** https://nextv.app/privacy (REQUERIDO)

**Website:** https://nextv.app

**Support contact info:** support@nextv.app

**Age ratings:**
- IARC questionnaire:
  - Violence: None/Mild
  - Sexual content: None/Mild
  - Language: None/Mild
  - Controlled substances: None
  - Online interactions: Yes (streaming)
  - User-generated content: No
  - Location sharing: No
  - Purchases: No

**Resultado esperado:** PEGI 12 o ESRB Teen

### 8.6 Store Listings

**Description:**

```markdown
# NeXtv - Reproductor IPTV Premium para Windows

Disfruta de tu contenido IPTV favorito en tu PC con NeXtv.

## 🎬 CARACTERÍSTICAS PRINCIPALES:
• Soporte completo para Xtream Codes API
• TV en vivo con EPG (Guía electrónica de programación)
• Películas y series bajo demanda (VOD)
• Catch-up TV para ver programas pasados
• Sistema inteligente de favoritos
• Diseño moderno optimizado para Windows 10/11
• Control parental integrado
• Soporte para múltiples proveedores IPTV

## 📺 TV EN VIVO:
Miles de canales de todo el mundo. EPG integrado para ver qué se transmite ahora y próximamente.

## 🎥 PELÍCULAS Y SERIES:
Biblioteca completa de contenido VOD. Busca por género, año, calificación y más.

## ⭐ FAVORITOS:
Guarda tus canales y contenido favorito para acceso rápido.

## ⏪ CATCH-UP TV:
No te pierdas tus programas. Reproduce contenido de hasta 7 días atrás.

## 🖥️ OPTIMIZADO PARA WINDOWS:
• Soporte para múltiples monitores
• Modo ventana y pantalla completa
• Atajos de teclado
• Touch screen support (tablets)
• Notificaciones de Windows

## ⚠️ IMPORTANTE:
NeXtv es SOLO un reproductor IPTV.
NO proporcionamos contenido, servicios IPTV ni suscripciones.
Debes tener tu propia suscripción legal de un proveedor autorizado.
El usuario es responsable de verificar la legalidad del contenido al que accede.

## 🔒 SEGURIDAD Y PRIVACIDAD:
• Credenciales encriptadas localmente
• Sin recopilación de datos personales
• Sin anuncios ni tracking
• Open source (próximamente)

## 📧 SOPORTE:
¿Preguntas o problemas? Contáctanos en support@nextv.app

## 💻 REQUISITOS DEL SISTEMA:
• Windows 10 versión 1809 o superior, o Windows 11
• 4 GB RAM mínimo (8 GB recomendado)
• 200 MB de espacio en disco
• Conexión a Internet

Descarga NeXtv hoy y eleva tu experiencia IPTV al siguiente nivel.
```

**Keywords (max 7):**
- IPTV
- Media Player
- Streaming
- Live TV
- VOD
- TV Player
- Video Player

**Screenshots (mínimo 1, máximo 10):**
- Tamaño: 1366x768, 1920x1080, 2560x1440, o 3840x2160
- Formato: PNG o JPG
- Sin bordes de ventana (solo contenido)

**Tipos de screenshots recomendados:**
1. Pantalla principal con lista de canales
2. Video reproduciéndose en pantalla completa
3. Sistema de favoritos
4. EPG / guía de programación
5. Biblioteca de películas/series
6. Búsqueda de contenido
7. Configuración
8. Multi-window support (si aplica)

**Store logos:**
- 1:1 (300x300): Logo cuadrado
- 2:3 (200x300): Logo vertical (opcional)
- 16:9 (1920x1080): Banner horizontal
- 9:16 (1080x1920): Banner vertical (opcional)

**Promotional images (optional pero recomendado):**
- Feature image: 1920x1080
- Super hero art: 1920x720
- Box art: 1:1 ratio

### 8.7 System Requirements

**Minimum:**
- OS: Windows 10 versión 1809 o superior
- Architecture: x64, ARM64
- Memory: 4 GB
- Video card: DirectX 11 compatible
- Processor: 1.5 GHz dual-core
- Storage: 200 MB

**Recommended:**
- OS: Windows 11 latest
- Architecture: x64
- Memory: 8 GB
- Video card: Dedicated GPU
- Processor: 2.5 GHz quad-core
- Storage: 500 MB

---

## 9. Submisión y Revisión

### 9.1 Upload Package

1. **Packages** → **+ New package**
2. **Upload MSIX file:**
   - Drag & drop o browse para `nextv.msix`
   - Partner Center valida automáticamente:
     - ✅ Package identity matches
     - ✅ Publisher matches
     - ✅ Version is valid
     - ✅ Dependencies satisfied
3. Esperar upload (puede tardar varios minutos para packages grandes)

### 9.2 Package Validation

Microsoft verifica automáticamente:
- ✅ Package format correcto
- ✅ Identity válida
- ✅ Publisher autorizado
- ✅ No malware detectado
- ✅ APIs permitidas
- ✅ Capabilities justificadas

**Si falla, revisar:**
- Identity name y publisher coinciden con Partner Center
- Version format es X.Y.Z.W
- MSIX está firmado correctamente (si es sideloading)

### 9.3 Notes for Certification

**⚠️ MUY IMPORTANTE - Proporcionar credenciales de prueba:**

```
MICROSOFT CERTIFICATION TEAM:

NeXtv is an IPTV player app that requires credentials from the user's IPTV provider.

TEST CREDENTIALS:
Server URL: http://demo.iptv-provider.com:8080
Username: demo
Password: demo123

HOW TO TEST THE APP:
1. Launch NeXtv from Start Menu
2. On login screen, enter the test credentials above
3. Click "Login" or press Enter
4. App will load demo channels (may take 10-20 seconds)
5. Select any channel from the list to play
6. Video should start playing automatically

IMPORTANT NOTES:
- NeXtv does NOT provide IPTV content or services
- Users must have their own legal IPTV subscription
- Test server contains only legal demo content for review purposes
- We have prominent disclaimers about user responsibility

FEATURES TO TEST:
- Login with IPTV credentials
- Channel browsing and selection
- Videoplayback (should be smooth)
- Favorites system (star icon on channels)
- EPG / program guide (if available for test channels)
- Search functionality
- Parental controls (PIN: 1234 if prompted)
- Window resize and maximize
- Multiple monitor support

KNOWN LIMITATIONS:
- Video quality depends on test server bandwidth
- Some channels may be offline (outside our control)
- EPG data may be limited for demo channels

TROUBLESHOOTING:
- If login fails, please verify test credentials were entered correctly
- If video doesn't play, try a different channel
- For questions, contact: certification@nextv.app

Thank you for reviewing NeXtv!
```

### 9.4 Submit for Review

1. Revisar toda la información:
   - ✅ Package uploaded
   - ✅ Pricing set
   - ✅ Markets selected
   - ✅ Store listings complete
   - ✅ Age rating completed
   - ✅ Privacy policy URL valid
   - ✅ Notes for certification provided

2. **Save draft** (recomendado primero)

3. **Submit to the Store**

4. Estado cambia a **"In certification"**

### 9.5 Certification Process

**Tiempo estimado:** 24-72 horas (puede ser más)

**Fases:**
1. **Pre-processing:** Validación automática del package
2. **Security tests:** Escaneo de malware y vulnerabilidades
3. **Technical compliance:** APIs, capabilities, performance
4. **Content compliance:** Verificar políticas de contenido
5. **Manual testing:** Tester humano prueba la app
6. **Final review:** Aprobación o rechazo

**Notificaciones:**
- Email en cada cambio de estado
- Dashboard en Partner Center actualizado

### 9.6 Posibles Razones de Rechazo

| Razón | Solución |
|-------|----------|
| App crashes on launch | Fix bugs, testear exhaustivamente |
| Login no funciona | Verificar credenciales de test, clarificar instrucciones |
| Performance pobre | Optimizar, reducir uso de recursos |
| Contenido inapropiado | Disclaimers, filtros, age rating |
| Privacy policy inválida | Asegurar URL accesible y específica |
| Package identity mismatch | Verificar que coincida con Partner Center |
| Missing capabilities declaration | Declarar todas las capabilities usadas |
| APIs no permitidas | Usar solo Windows APIs públicas |

---

## 10. Post-Release

### 10.1 Publicar App

Una vez certificado:
- Estado cambia a **"Publishing"**
- App estará disponible en Microsoft Store en ~24 horas
- Usuarios pueden buscar e instalar

**Verificar:**
```
Microsoft Store app → Buscar "NeXtv" → Debe aparecer
```

### 10.2 Monitorear

**Partner Center → Analytics:**

- 📊 **Acquisitions:** Installs, país, canal
- 👥 **Usage:** Active users, sesiones, engagement
- 💥 **Health:** Crashes, hangs, error rates
- ⭐ **Ratings & Reviews:** Feedback de usuarios
- 📈 **Channels:** Descargas por fuente (busca, referral, etc.)

### 10.3 Configurar Crash Reporting Detallado

**Integrar Windows App SDK telemetry:**

```dart
// Opcional: Usar Firebase Crashlytics o Sentry para más detalles
dependencies:
  firebase_core: latest
  firebase_crashlytics: latest
```

### 10.4 Responder a Reviews

**Partner Center → Ratings and reviews:**

1. Ver reviews de usuarios
2. **Respond** a reviews (máximo 1 respuesta por review)
3. Agradecer feedback positivo
4. Ofrecer ayuda en reviews negativos

**Ejemplo:**
```
Review: "No funciona con mi servidor"

Respuesta:
"Hola, lamentamos los inconvenientes. Por favor verifica que:
1. Tu servidor usa protocolo Xtream Codes
2. Las credenciales son correctas
3. La URL incluye http:// o https://

Si continúas con problemas, contáctanos en support@nextv.app 
con detalles de tu proveedor y te ayudaremos.

Gracias por usar NeXtv."
```

### 10.5 Actualizaciones

**Proceso:**

1. Incrementar versión:
```xml
<!-- msix_config.xml -->
<Identity Version="2.0.1.0" />
```

2. Rebuild:
```bash
flutter clean
flutter build windows --release
# Empaquetar nuevo MSIX
```

3. Partner Center → **NeXtv** → **Packages** → **+ New package**

4. Upload nuevo MSIX (2.0.1.0)

5. **Release notes:**
```markdown
What's new in 2.0.1:

FIXES:
• Fixed crash when switching channels rapidly
• Improved connection stability with slow servers
• Fixed favorites not saving issue
• Corrected EPG timezone issues

IMPROVEMENTS:
• 25% faster channel loading
• Reduced memory usage by 15%
• Better video player performance
• Updated UI for Windows 11 design guidelines

Thanks to all users who reported issues!

Having issues? Contact us: support@nextv.app
```

6. **Submit for certification** (again)

**⚠️ Microsoft permite deployment gradual:**
- Percentage rollout: 10% → 50% → 100%
- Pause rollout si hay problemas

---

## 11. Troubleshooting

### 11.1 Problemas de Build

#### Error: "Windows toolchain  not installed"
**Solución:**
```bash
flutter doctor -v
# Seguir instrucciones para instalar Visual Studio con C++ tools
```

#### Error: CMake not found
**Solución:**
```bash
# Instalar desde Visual Studio Installer:
# Individual components → C++ CMake tools for Windows
```

#### Error: "Unable to find suitable version of Windows SDK"
**Solución:**
```bash
# Instalar Windows 10 SDK desde Visual Studio Installer
# O descargar standalone: https://developer.microsoft.com/windows/downloads/windows-sdk/
```

### 11.2 Problemas de Empaquetado

#### Error: "Invalid package identity"
**Solución:**
```xml
<!-- Verificar que en msix_config.xml coincida con Partner Center -->
<Identity Name="[Exactamente como en Partner Center]"
          Publisher="[CN exacto de Partner Center]" />
```

#### Error: App won't install (0x80073CF9)
**Solución:**
```powershell
# Desinstalar versión anterior primero
Get-AppxPackage -Name "*nextv*" | Remove-AppxPackage

# Limpiar cache
wsreset.exe

# Reinstalar
Add-AppxPackage nextv.msix
```

#### Error: Certificate not trusted
**Solución para sideloading:**
```powershell
# Instalar certificado en Trusted Root
# Abrir certmgr.msc
# Trusted Root Certification Authorities → Certificates
# Importar .cer file
```

### 11.3 Problemas de Certificación

#### Rechazado: "App crashes during review"
**Soluciones:**
1. Testear exhaustivamente en Windows 10 Y 11
2. Testear en máquina virtual limpia
3. Verificar dependencias (todas .dll incluidas)
4. Agregar exception handling robusto
5. Proporcionar logs de debugging en notes

#### Rechazado: "Cannot test - login failed"
**Soluciones:**
1. Verificar credenciales de test funcionan
2. Clarificar instrucciones paso a paso
3. Proveer video demo de cómo usar la app
4. Ofrecer VPN access si el servidor tiene geo-restricción
5. Responder rápidamente a feedback del certificator

#### Rechazado: "Content policy violation"
**Soluciones:**
1. Agregar disclaimers prominentes en primera pantalla
2. Implementar control parental estricto
3. Filtrar contenido adulto por defecto
4. Sistema de reporte de contenido ilegal
5. Apelar con documentación legal si es necesario

### 11.4 Problemas de Performance

#### Alto uso de CPU
**Optimizaciones:**
```dart
// Limitar frame rate si no es necesario 60fps
import 'dart:ui' as ui;
ui.window.scheduleFrame();

// Usar const constructors
const Text('Hello');

// Dispose correctamente
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

#### Alto uso de memoria
**Soluciones:**
```dart
// Lazy load de imágenes
CachedNetworkImage(
  imageUrl: url,
  maxWidth: 300,
  maxHeight: 300,
);

// Limitar tamaño de cache
CachedNetworkImageProvider(
  url,
  maxWidth: 300,
  maxHeight: 300,
);
```

---

## 12. Recursos Adicionales

### 12.1 Documentación Oficial

- [Microsoft Partner Center](https://partner.microsoft.com/dashboard)
- [Windows App Certification Kit](https://docs.microsoft.com/windows/uwp/debug-test-perf/windows-app-certification-kit)
- [MSIX Packaging](https://docs.microsoft.com/windows/msix/)
- [Microsoft Store Policies](https://docs.microsoft.com/windows/uwp/publish/store-policies)
- [Flutter Windows Development](https://docs.flutter.dev/platform-integration/windows/)

### 12.2 Herramientas

- **MSIX Packaging Tool:** Crear y editar MSIX
- **Windows App Certification Kit:** Pre-validar apps
- **Visual Studio:** IDE completo
- **flutter_distributor:** Automatizar empaquetado

### 12.3 Comunidades

- [Microsoft Q&A](https://docs.microsoft.com/answers/topics/windows-store.html)
- [Flutter Discord](https://discord.gg/flutter) - #desktop canal
- [Stack Overflow - MSIX](https://stackoverflow.com/questions/tagged/msix)
- [r/FlutterDev](https://reddit.com/r/FlutterDev)

---

## 13. Checklist Final

```bash
DESARROLLO:
☐ Visual Studio 2022 con C++ tools instalado
☐ Windows 10 SDK instalado
☐ Flutter Windows desktop habilitado
☐ Build de release exitoso
☐ Testeado en Windows 10 y 11
☐ Iconos configurados
☐ Manifest configurado correctamente
☐ Version numbers actualizados

EMPAQUETADO:
☐ Assets para MSIX preparados
☐ msix_config.xml creado y configurado
☐ MSIX empaquetado sin errores
☐ MSIX firmado (si sideloading)
☐ Instalado y testeado localmente
☐ Tamaño de package < 200MB idealmente

PARTNER CENTER:
☐ Cuenta de desarrollador creada y aprobada
☐ App registrada con nombre único
☐ Product identity obtenida
☐ Identity actualizada en msix_config.xml
☐ Pricing y markets configurados
☐ Properties completadas (category, age rating
☐ Store listings en todos idiomas
☐ Screenshots de alta calidad subidas
☐ Store logos subidos
☐ Privacy policy URL válida
☐ System requirements especificados

SUBMISSION:
☐ MSIX package uploaded correctamente
☐ Package validation exitosa
☐ Notes for certification con credenciales demo
☐ Toda la información revisada
☐ Enviado para certificación
☐ Esperando aprobación (24-72h)

POST-RELEASE:
☐ App publicada en Microsoft Store
☐ Verificado que aparece en búsquedas
☐ Crash reporting configurado
☐ Analytics monitoreado
☐ Reviews respondidas
☐ Plan de actualizaciones establecido
```

---

**¡Éxito con tu release en Microsoft Store! 🚀**

**Contacto:** windows-deployment@nextv.app  
**Documentación:** Febrero 2026  
**Versión:** 1.0
