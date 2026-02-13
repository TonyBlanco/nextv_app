# Solución al Problema de CocoaPods

## 🐛 Problema Original

```
Error: CocoaPods not installed or not in valid state.
```

### Causa Raíz
- macOS viene con **Ruby 2.6.10** (versión del sistema)
- CocoaPods moderno requiere **Ruby 3.0+**
- Incompatibilidad de versiones → CocoaPods no se puede instalar

## ✅ Solución Implementada

### Paso 1: Instalar Homebrew
Homebrew es el gestor de paquetes estándar para macOS.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Paso 2: Instalar Ruby Moderno
```bash
brew install ruby
```

Esto instala Ruby 3.3+ en:
- **Apple Silicon (M1/M2):** `/opt/homebrew/opt/ruby/`
- **Intel:** `/usr/local/opt/ruby/`

### Paso 3: Instalar CocoaPods
```bash
gem install cocoapods
pod setup
```

## 🚀 Script Automático

Ejecuta:
```bash
./scripts/install_cocoapods.sh
```

Este script hace todo automáticamente:
1. ✅ Detecta si Homebrew está instalado
2. ✅ Instala Homebrew si es necesario
3. ✅ Instala Ruby moderno
4. ✅ Instala CocoaPods
5. ✅ Configura CocoaPods
6. ✅ Verifica Flutter

## 📝 Configuración Permanente

Después de ejecutar el script, agrega estas líneas a `~/.zshrc`:

### Para Apple Silicon (M1/M2/M3):
```bash
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin:$PATH"
```

### Para Intel:
```bash
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="/usr/local/lib/ruby/gems/3.3.0/bin:$PATH"
```

## 🔍 Verificación

Después de la instalación:

```bash
# Verificar Ruby
ruby -v
# Debería mostrar: ruby 3.3.x

# Verificar CocoaPods
pod --version
# Debería mostrar: 1.16.x

# Verificar Flutter
flutter doctor
# Debería mostrar ✓ en Xcode
```

## 🎯 Resultado Final

Una vez completado, podrás:
- ✅ Compilar para macOS: `flutter run -d macos`
- ✅ Compilar para iOS: `flutter run -d ios`
- ✅ Usar plugins nativos que requieren CocoaPods

## ⏱️ Tiempo de Instalación

- Homebrew: 5-10 minutos
- Ruby: 2-3 minutos
- CocoaPods: 1-2 minutos
- **Total: ~10-15 minutos**

## ❓ Problemas Comunes

### "command not found: brew"
**Solución:** Reinicia la terminal o ejecuta:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"     # Intel
```

### "pod: command not found"
**Solución:** Asegúrate de que el PATH de Ruby esté configurado (ver arriba)

### "Permission denied"
**Solución:** El script necesita `sudo` para instalar Homebrew. Ingresa tu contraseña cuando te la pida.
