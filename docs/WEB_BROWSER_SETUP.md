# NeXtv - Configuración Web con Safari

## Problema Resuelto ✅

Flutter buscaba Chrome pero no está instalado en tu Mac. He configurado Safari como navegador para desarrollo web.

## Opciones Disponibles

### 1️⃣ Usar Safari (Configurado)
Ya está listo. Safari funciona perfectamente con Flutter web.

```bash
# Ya configurado en scripts/setup_mac.sh
export CHROME_EXECUTABLE="/Applications/Safari.app/Contents/MacOS/Safari"
```

### 2️⃣ Instalar Chrome (Opcional)
Si prefieres Chrome para desarrollo web:

1. Descarga Chrome: https://www.google.com/chrome/
2. Instala en `/Applications/Google Chrome.app`
3. Elimina la línea `CHROME_EXECUTABLE` de `scripts/setup_mac.sh`

### 3️⃣ Usar Firefox (Alternativa)
Flutter también soporta Firefox:

```bash
export CHROME_EXECUTABLE="/Applications/Firefox.app/Contents/MacOS/firefox"
```

## Comandos de Desarrollo Web

```bash
# Ejecutar en modo web (desarrollo)
flutter run -d web-server

# Compilar para producción
flutter build web --release

# Ejecutar en Safari
flutter run -d safari
```

## Notas
- Safari es el navegador nativo de macOS y funciona excelente con Flutter
- Chrome no es obligatorio para desarrollo Flutter web
- Puedes instalar Chrome más adelante si lo necesitas
