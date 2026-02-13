# NeXtv PowerShell Scripts

Scripts de PowerShell para facilitar el desarrollo, testing y build de NeXtv.

## 📜 Scripts Disponibles

### 1. `build.ps1` - Build Script
Compila la aplicación para diferentes plataformas.

**Uso:**
```powershell
.\build.ps1 [platform] [mode]
```

**Ejemplos:**
```powershell
# Android Debug (default)
.\build.ps1

# Android Release
.\build.ps1 android release

# Web Release
.\build.ps1 web release

# Windows Release
.\build.ps1 windows release
```

**Plataformas:** `android`, `web`, `windows`, `ios`  
**Modos:** `debug`, `release`, `profile`

---

### 2. `test.ps1` - Test Runner
Ejecuta la aplicación en diferentes dispositivos para testing.

**Uso:**
```powershell
.\test.ps1 [device]
```

**Ejemplos:**
```powershell
# Dispositivo por defecto
.\test.ps1

# BlueStacks (Android Emulator)
.\test.ps1 bluestacks

# Web (Chrome)
.\test.ps1 web

# Windows
.\test.ps1 windows
```

**Dispositivos:** `bluestacks`, `web`, `windows`, `default`

---

### 3. `analyze.ps1` - Code Analyzer
Analiza el código en busca de errores y problemas de formato.

**Uso:**
```powershell
.\analyze.ps1
```

**Verifica:**
- Errores de análisis estático
- Formato de código
- Convenciones de Dart/Flutter

---

### 4. `quick-test.ps1` - Quick Test
Workflow rápido: analiza el código y ejecuta en BlueStacks.

**Uso:**
```powershell
.\quick-test.ps1
```

**Ejecuta:**
1. Análisis de código
2. Testing en BlueStacks

---

## ⚙️ Configuración

### Rutas de SDK

Si tus SDKs están en ubicaciones diferentes, edita las rutas en los scripts:

```powershell
# En cada script, actualiza estas variables:
$FlutterPath = "C:\src\flutter\bin\flutter.bat"
$AdbPath = "C:\platform-tools\adb.exe"
```

### BlueStacks

Para usar BlueStacks:
1. Asegúrate de que BlueStacks esté ejecutándose
2. La IP por defecto es `127.0.0.1:5555`
3. Si usas otra IP, edita `$BlueStacksIP` en `test.ps1`

---

## 🚀 Workflows Comunes

### Desarrollo Diario
```powershell
# Testing rápido
.\quick-test.ps1

# O solo ejecutar
.\test.ps1 bluestacks
```

### Antes de Commit
```powershell
# Verificar código
.\analyze.ps1

# Si hay errores de formato
flutter format lib/
```

### Crear Release
```powershell
# Android APK
.\build.ps1 android release

# Web
.\build.ps1 web release

# Windows
.\build.ps1 windows release
```

### Testing Multi-Plataforma
```powershell
# Android
.\test.ps1 bluestacks

# Web
.\test.ps1 web

# Windows
.\test.ps1 windows
```

---

## 📝 Notas

- **Permisos**: Puede que necesites ejecutar `Set-ExecutionPolicy RemoteSigned` para permitir scripts
- **Primera Ejecución**: Los scripts descargarán dependencias automáticamente
- **Errores de Build**: Revisa que Flutter SDK esté correctamente instalado
- **BlueStacks**: Debe estar ejecutándose antes de usar `.\test.ps1 bluestacks`

---

## 🔧 Troubleshooting

**"Flutter not found"**
- Verifica que Flutter esté instalado en `C:\src\flutter`
- O actualiza `$FlutterPath` en los scripts

**"ADB not found"**
- Verifica que ADB esté en `C:\platform-tools`
- O actualiza `$AdbPath` en `test.ps1`

**"Could not connect to BlueStacks"**
- Asegúrate de que BlueStacks esté ejecutándose
- Verifica que el puerto 5555 esté disponible
- Intenta `adb connect 127.0.0.1:5555` manualmente

**"Script execution is disabled"**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 📚 Más Información

- [Flutter Documentation](https://flutter.dev)
- [NeXtv Architecture](./ARCHITECTURE.md)
- [Development Workflow](./.agent/WORKFLOW.md)
