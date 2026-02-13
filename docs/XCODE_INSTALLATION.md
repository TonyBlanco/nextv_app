# Guía de Instalación de Xcode para NeXtv

## 🎯 Objetivo
Instalar Xcode para poder compilar la app NeXtv para iOS y macOS.

---

## 📋 Requisitos Previos
- **Espacio en disco:** ~20-25 GB libres
- **Conexión a internet:** Estable (descarga de ~15 GB)
- **Tiempo estimado:** 30-90 minutos (dependiendo de tu conexión)
- **Apple ID:** Necesario para descargar desde App Store

---

## 📱 Paso 1: Instalar Xcode

### Opción A: App Store (Recomendado)
1. Abre **App Store** en tu Mac
2. Busca "**Xcode**"
3. Haz clic en **Obtener** (o el ícono de nube si ya lo descargaste antes)
4. Ingresa tu contraseña de Apple ID si te la pide
5. **Espera** - La descarga es grande (~15 GB)
6. Una vez descargado, se instalará automáticamente

### Opción B: Descarga Directa
1. Ve a: https://developer.apple.com/xcode/
2. Haz clic en "Download"
3. Inicia sesión con tu Apple ID
4. Descarga el archivo `.xip`
5. Haz doble clic en el `.xip` para descomprimirlo
6. Mueve `Xcode.app` a `/Applications/`

---

## ⚙️ Paso 2: Configurar Xcode (Automático)

Una vez que Xcode esté instalado en `/Applications/Xcode.app`, ejecuta este comando en tu terminal:

```bash
./scripts/setup_xcode.sh
```

Este script hará automáticamente:
1. ✅ Configurar Xcode Command Line Tools
2. ✅ Aceptar la licencia de Xcode
3. ✅ Ejecutar la primera configuración
4. ✅ Instalar CocoaPods
5. ✅ Verificar que Flutter esté listo

---

## 🔍 Verificación

Después de ejecutar el script, verifica que todo esté bien:

```bash
flutter doctor -v
```

Deberías ver:
- ✅ Flutter
- ✅ Android toolchain (con advertencias, está bien)
- ✅ Xcode
- ✅ Chrome/Safari
- ✅ Connected device

---

## 🚀 Probar la App

Una vez configurado Xcode, puedes compilar para macOS:

```bash
# Ejecutar en modo desarrollo
flutter run -d macos

# Compilar para producción
flutter build macos --release
```

---

## ❓ Problemas Comunes

### "xcode-select: error: tool 'xcodebuild' requires Xcode"
**Solución:** Xcode no está completamente instalado. Verifica que esté en `/Applications/Xcode.app`

### "Active developer directory is a command line tools instance"
**Solución:** Ejecuta: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

### "CocoaPods not installed"
**Solución:** Ejecuta: `sudo gem install cocoapods`

### "Xcode license has not been accepted"
**Solución:** Ejecuta: `sudo xcodebuild -license accept`

---

## 📞 Siguiente Paso

Una vez que hayas instalado Xcode desde la App Store, vuelve aquí y ejecuta:

```bash
./scripts/setup_xcode.sh
```

¡Y estarás listo para desarrollar para iOS y macOS! 🎉
