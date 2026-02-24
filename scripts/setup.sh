#!/bin/bash

echo "🚀 Pideloo Setup Script"

# Check Node version
if ! node -v | grep -q "v20"; then
    echo "❌ Node 20+ requerido. Actual: $(node -v)"
    exit 1
fi

# Check pnpm
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm no instalado. Instalando..."
    npm install -g pnpm
fi

echo "📦 Instalando dependencias..."
pnpm install

echo "🔧 Configurando Supabase..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "⚠️  Edita .env con tus credenciales de Supabase"
fi

echo "✅ Setup completo!"
echo ""
echo "Próximos pasos:"
echo "  1. Editar .env con credenciales"
echo "  2. pnpm dev (iniciar desarrollo)"
echo "  3. Abrir http://localhost:3001 (API) y Expo Go (Mobile)"
