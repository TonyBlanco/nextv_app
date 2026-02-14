# Despliegue en Vercel - NeXtv Website

## 🚀 Deployment Rápido

### Opción 1: Vercel CLI (Recomendado)

1. **Instalar Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Navegar al directorio del website**
   ```bash
   cd /Users/luisblancofontela/Development/nextv_app/docs/web
   ```

3. **Iniciar sesión en Vercel**
   ```bash
   vercel login
   ```
   - Selecciona tu método de autenticación (email, GitHub, GitLab, Bitbucket)
   - Completa el proceso de login en el navegador

4. **Desplegar (Primera vez)**
   ```bash
   vercel
   ```
   - Presiona **Enter** para confirmar el proyecto
   - Selecciona tu cuenta/team
   - Presiona **Enter** para las configuraciones por defecto
   - Espera a que se complete el deployment
   - ¡Tu sitio estará en vivo! 🎉

5. **Desplegar actualizaciones (Production)**
   ```bash
   vercel --prod
   ```

### Opción 2: Vercel Dashboard (Web)

1. **Ir a Vercel**
   - Visita [vercel.com](https://vercel.com)
   - Inicia sesión con tu cuenta

2. **Importar Proyecto**
   - Click en **"Add New..."** → **"Project"**
   - Selecciona **"Import Git Repository"** o arrastra la carpeta

3. **Configurar Proyecto**
   - **Framework Preset**: Selecciona "Other" (sitio estático)
   - **Root Directory**: Deja por defecto o selecciona `docs/web`
   - **Build Command**: Déjalo vacío (no necesita build)
   - **Output Directory**: `.` (punto)

4. **Deploy**
   - Click en **"Deploy"**
   - Espera 1-2 minutos
   - ¡Listo! Tu sitio estará en vivo

### Opción 3: Deploy desde GitHub

1. **Subir a GitHub** (si no lo has hecho)
   ```bash
   cd /Users/luisblancofontela/Development/nextv_app
   git add docs/web
   git commit -m "feat: website completo listo para Vercel"
   git push origin main
   ```

2. **Conectar en Vercel**
   - En Vercel Dashboard, click **"Import Git Repository"**
   - Autoriza Vercel para acceder a GitHub
   - Selecciona tu repositorio `nextv_app`
   - En **Root Directory**, ingresa: `docs/web`
   - Click **"Deploy"**

## 📝 Variables de Entorno (Opcional)

Si necesitas APIs o configuraciones, crea `.env` en `docs/web`:

```bash
# Analytics
NEXT_PUBLIC_GA_ID=G-XXXXXXXXXX
NEXT_PUBLIC_HOTJAR_ID=XXXXXXX

# Newsletter
NEWSLETTER_API_KEY=tu_api_key
```

En Vercel Dashboard:
1. Ve a **Settings** → **Environment Variables**
2. Agrega cada variable
3. Redeploy el proyecto

## 🔗 Dominio Personalizado

### Agregar tu Dominio:

1. **En Vercel Dashboard**
   - Ve a tu proyecto
   - Click en **Settings** → **Domains**
   - Agrega tu dominio: `nextv.app` o `www.nextv.app`

2. **Configurar DNS**
   - Ve a tu proveedor de dominios (GoDaddy, Namecheap, etc.)
   - Agrega los registros DNS que Vercel te proporcione:
     ```
     Type: CNAME
     Name: www
     Value: cname.vercel-dns.com
     
     Type: A
     Name: @
     Value: 76.76.21.21
     ```

3. **Verificación**
   - Vercel verificará automáticamente
   - SSL se configurará automáticamente (HTTPS)
   - ¡Listo en 2-5 minutos!

## 🎨 Actualizaciones

### Actualizar el sitio:

1. **Hacer cambios locales**
   ```bash
   # Edita archivos en docs/web/
   code docs/web/index.html
   ```

2. **Desplegar cambios**
   ```bash
   cd docs/web
   vercel --prod
   ```

### Auto-deploy desde Git:

Si conectaste GitHub, cada `git push` desplegará automáticamente:
- Push a `main` → Production deployment
- Push a otras ramas → Preview deployment

## 📊 Monitoreo

### Ver Analytics en Vercel:

1. Ve a tu proyecto en Vercel Dashboard
2. Click en **Analytics** tab
3. Ve:
   - Visitas por país
   - Páginas más vistas
   - Velocidad de carga
   - Errores 404

### Logs:

```bash
vercel logs [deployment-url]
```

## ⚡ Optimizaciones Activas

El sitio ya incluye:
- ✅ **Cache headers** para CSS/JS/imágenes (1 año)
- ✅ **Compresión Gzip/Brotli** automática
- ✅ **CDN global** de Vercel
- ✅ **SSL/HTTPS** automático
- ✅ **HTTP/2** y **HTTP/3**
- ✅ **Image optimization** (si usas Vercel Image)

## 🔧 Configuración Avanzada

### Preview Deployments:

Cada deployment genera una URL única:
```bash
vercel
# Output: https://nextv-website-abc123.vercel.app
```

### Rollback:

Si algo sale mal:
1. Ve a **Deployments** en Dashboard
2. Click en deployment anterior
3. Click **"Promote to Production"**

### Protección con Password:

En `vercel.json`, agrega:
```json
{
  "build": {
    "env": {
      "PASSWORD": "tu_password"
    }
  }
}
```

## 🌐 URLs del Proyecto

Después del deployment, tendrás:

- **Production**: `https://nextv-website.vercel.app`
- **Preview**: `https://nextv-website-git-<branch>.vercel.app`
- **Deployment**: `https://nextv-website-<hash>.vercel.app`

## 🐛 Troubleshooting

### Error: "No vercel.json found"
- Asegúrate de estar en `/docs/web`
- El archivo `vercel.json` debe estar en esa carpeta

### Error: "Build failed"
- Sitios estáticos HTML no necesitan build
- Verifica que `vercel.json` esté correcto

### 404 en rutas
- Verifica que los archivos existan
- Verifica mayúsculas/minúsculas en nombres

### Imágenes no cargan
- Asegúrate de que las rutas sean relativas: `images/logo.png`
- No uses rutas absolutas: `/images/logo.png`

## 📞 Soporte

- **Documentación Vercel**: [vercel.com/docs](https://vercel.com/docs)
- **Community**: [github.com/vercel/vercel/discussions](https://github.com/vercel/vercel/discussions)
- **Status**: [vercel-status.com](https://vercel-status.com)

## ✨ Features de Vercel

- 🌍 **CDN Global**: 70+ ubicaciones
- ⚡ **Edge Network**: Ultra rápido
- 🔒 **SSL Automático**: HTTPS gratis
- 📊 **Analytics**: Incluido en Free tier
- 🚀 **Instant Rollback**: Un click
- 🔄 **Git Integration**: Auto-deploy
- 👥 **Colaboración**: Teams y permisos
- 💬 **Preview Comments**: Feedback en PRs

## 💰 Pricing

**Free Tier incluye:**
- Deployments ilimitados
- 100 GB bandwidth/mes
- HTTPS automático
- Analytics básicos
- Perfecto para este proyecto

**Pro Tier ($20/mes) incluye:**
- 1 TB bandwidth
- Analytics avanzados
- Password protection
- Priority support

---

**¡Tu sitio NeXtv estará en vivo en menos de 5 minutos! 🚀**
