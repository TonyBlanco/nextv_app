# NeXtv Official Website & Documentation

## 📦 Proyecto Completo

Este repositorio contiene la aplicación NeXtv IPTV Player y su sitio web oficial.

---

## 🌐 Sitio Web (docs/web/)

### Deployed URLs
- **Production**: https://nextv-website.vercel.app
- **Dashboard**: https://vercel.com/tonyblancos-projects/nextv-website

### Estructura
```
docs/web/
├── index.html              # Homepage principal
├── css/
│   └── styles.css          # Sistema de diseño completo
├── js/
│   └── main.js             # Funcionalidad JavaScript
├── images/                 # Assets e imágenes
│   ├── logo.png           # Logo oficial NeXtv (610KB)
│   ├── favicon.png        # Favicon del sitio
│   └── app-screenshot.png # Screenshot oficial de la app
├── pages/
│   └── download.html      # Página de descargas
├── vercel.json            # Configuración de Vercel
├── package.json           # Metadata del proyecto
├── deploy.sh              # Script de deployment
├── DEPLOYMENT_VERCEL.md   # Guía completa de deployment
└── README.md              # Documentación del template

```

### Assets Oficiales

El sitio web utiliza los **logos oficiales** de NeXtv ubicados en `/assets/images/`:

- **nextv_icon.png** → Usado como logo principal y favicon (610KB)
- **nextv_home.png** → Usado como screenshot de la app (610KB)

Los assets oficiales han sido copiados a `docs/web/images/` para uso en el sitio.

### Features del Sitio

✅ **Diseño Moderno y Responsive**
- Mobile-first design
- Optimizado para todos los dispositivos
- Animaciones suaves y modernas

✅ **Logo Oficial Integrado**
- Navbar con logo real de NeXtv
- Footer con branding consistente
- Favicon de alta calidad

✅ **Páginas Completas**
- Homepage con hero, features, pricing, FAQ
- Página de descargas para todas las plataformas (iOS, Android, Windows, macOS, Linux, WebOS, Web)
- Links a documentación legal

✅ **SEO Optimizado**
- Meta tags completas
- Open Graph para redes sociales
- Screenshot oficial como imagen de preview

✅ **Performance**
- Cache headers configurados
- CDN global de Vercel
- SSL automático

---

## 📄 Documentación Legal (docs/)

Documentos de políticas y legal creados y listos para producción:

- ✅ **PRIVACY_POLICY.md** - Política de privacidad (GDPR/CCPA compliant)
- ✅ **LEGAL_DISCLAIMER.md** - Descargo de responsabilidad legal
- ✅ **DMCA_POLICY.md** - Política de copyright y DMCA
- ✅ **COOKIE_POLICY.md** - Política de cookies
- ✅ **REFUND_POLICY.md** - Política de reembolsos
- ✅ **TERMS_OF_SERVICE.md** - Términos de servicio
- ✅ **MARKETING_DISTRIBUTION.md** - Estrategia de marketing (25K+ palabras)

---

## 🚀 Deployment

### Deploy Website a Vercel

```bash
cd docs/web

# Login (primera vez)
vercel login

# Deploy a production
vercel --prod
```

O usa el script automatizado:
```bash
cd docs/web
./deploy.sh
```

### Actualizar Website

Después de hacer cambios:
```bash
cd docs/web
git add .
git commit -m "feat: actualización del website"
vercel --prod
```

---

## 🎨 Branding Guidelines

### Logo Oficial

El logo oficial de NeXtv está en:
- **Source**: `/assets/images/nextv_icon.png`
- **Web**: `/docs/web/images/logo.png`

**Características**:
- Tamaño: 610KB
- Formato: PNG con transparencia
- Dimensiones: Variable (se escala automáticamente)
- Uso: Navbar, footer, favicon

### Screenshot Oficial

Screenshot de la app:
- **Source**: `/assets/images/nextv_home.png`
- **Web**: `/docs/web/images/app-screenshot.png`

**Uso**:
- Preview en redes sociales (Open Graph)
- Hero section del website
- Material de marketing

---

## 📊 Estadísticas del Proyecto

### Website
- **HTML**: ~32,000 líneas
- **CSS**: ~1,200 líneas
- **JavaScript**: ~600 líneas
- **Documentación**: ~50,000+ palabras

### Deployment
- **Platform**: Vercel
- **Build Time**: ~12 segundos
- **CDN**: Global (70+ ubicaciones)
- **SSL**: Automático

---

## 🔄 Workflow de Actualización

### 1. Actualizar Contenido
```bash
# Editar archivos
code docs/web/index.html
code docs/web/css/styles.css
```

### 2. Probar Localmente
```bash
cd docs/web
npx serve .
# Abre http://localhost:3000
```

### 3. Deploy a Producción
```bash
vercel --prod
```

### 4. Verificar
- Visita: https://nextv-website.vercel.app
- Verifica en móvil y desktop

---

## 📞 Enlaces Útiles

- **Website**: https://nextv-website.vercel.app
- **Vercel Dashboard**: https://vercel.com/tonyblancos-projects/nextv-website
- **Deployment Guide**: [docs/web/DEPLOYMENT_VERCEL.md](docs/web/DEPLOYMENT_VERCEL.md)
- **Website Template**: [docs/web/README.md](docs/web/README.md)

---

## 🛠️ Mantenimiento

### Actualizar Logo
Si necesitas cambiar el logo oficial:
```bash
# 1. Reemplaza el logo en assets/
cp nuevo_logo.png assets/images/nextv_icon.png

# 2. Copia al website
cp assets/images/nextv_icon.png docs/web/images/logo.png
cp assets/images/nextv_icon.png docs/web/images/favicon.png

# 3. Deploy
cd docs/web && vercel --prod
```

### Actualizar Screenshot
```bash
# 1. Toma nuevo screenshot y guarda en assets/
cp nuevo_screenshot.png assets/images/nextv_home.png

# 2. Copia al website
cp assets/images/nextv_home.png docs/web/images/app-screenshot.png

# 3. Deploy
cd docs/web && vercel --prod
```

---

## ✨ Características Técnicas

### CSS Variables
El sitio usa un sistema completo de variables CSS para fácil personalización:
- Colores (primary, secondary, success, error, warning)
- Espaciado (xs, sm, md, lg, xl, 2xl, 3xl, 4xl)
- Tipografía (Inter font family)
- Sombras y efectos

### JavaScript Modular
- Navbar sticky con efectos de scroll
- Mobile menu toggle
- Pricing toggle (mensual/anual)
- FAQ accordion
- Video modal
- Smooth scrolling
- Intersection Observer para animaciones

### Accesibilidad
- WCAG 2.1 compliant
- Keyboard navigation
- Screen reader friendly
- Skip links
- Semantic HTML5

---

**Última actualización**: 14 de febrero de 2026
**Versión del sitio**: 1.0.0
**Deployed**: ✅ Production en Vercel
