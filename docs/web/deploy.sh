#!/bin/bash

# NeXtv Website - Deploy to Vercel Script
# Este script automatiza el deployment del website a Vercel

set -e

echo "🚀 NeXtv Website - Vercel Deployment"
echo "===================================="
echo ""

# Check if we're in the right directory
if [ ! -f "index.html" ]; then
    echo "❌ Error: Debes ejecutar este script desde /docs/web"
    echo "   Usa: cd docs/web && ./deploy.sh"
    exit 1
fi

# Check if vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "📦 Instalando Vercel CLI..."
    npm install -g vercel
    echo "✅ Vercel CLI instalado"
    echo ""
fi

# Check if user is logged in
echo "🔐 Verificando autenticación..."
if ! vercel whoami &> /dev/null; then
    echo "⚠️  No has iniciado sesión en Vercel"
    echo "   Iniciando sesión..."
    vercel login
fi

echo ""
echo "👤 Usuario: $(vercel whoami)"
echo ""

# Ask deployment type
echo "Selecciona el tipo de deployment:"
echo "  1) Preview (desarrollo/testing)"
echo "  2) Production (público)"
read -p "Opción [1/2]: " deploy_type

echo ""

if [ "$deploy_type" = "2" ]; then
    echo "🚀 Desplegando a PRODUCTION..."
    vercel --prod
else
    echo "🧪 Desplegando PREVIEW..."
    vercel
fi

echo ""
echo "✅ ¡Deployment completado!"
echo ""
echo "📊 Para ver tu sitio: vercel ls"
echo "📝 Para ver logs: vercel logs"
echo "🔗 Para abrir en navegador: vercel open"
echo ""
