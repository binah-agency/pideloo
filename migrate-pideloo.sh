
```zsh
#!/bin/zsh

# Pideloo Monorepo Migration Script
# Transforma estructura actual en monorepo con docs, Zustand, Zod, Supabase

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'
BOLD='\033[1m'

ROOT_DIR=$(pwd)
BACKEND_DIR="$ROOT_DIR/backend/pideloo-backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

log_info() { echo -e "${BLUE}ℹ${RESET} $1"; }
log_success() { echo -e "${GREEN}✓${RESET} $1"; }
log_warning() { echo -e "${YELLOW}⚠${RESET} $1"; }
log_section() { echo -e "\n${BOLD}${MAGENTA}$1${RESET}\n"; }


# ============================================
# FASE 10: RESUMEN Y LIMPIEZA
# ============================================

print_summary() {
    log_section "✅ MIGRACIÓN COMPLETADA"
    
    echo -e "${GREEN}Estructura final:${RESET}"
    if command -v tree &> /dev/null; then
        tree -L 2 "$ROOT_DIR" 2>/dev/null || find "$ROOT_DIR" -maxdepth 2 -type d | head -20
    else
        find "$ROOT_DIR" -maxdepth 2 -type d | sed 's|[^/]*/| |g' | head -20
    fi
    
    echo ""
    echo -e "${CYAN}Resumen de cambios:${RESET}"
    echo "  • Backend migrado: backend/pideloo-backend → apps/api"
    echo "  • Mobile migrado: frontend/pideloo-mobile → apps/mobile"
    echo "  • Web migrado: frontend/pideloo-front → apps/web"
    echo "  • Landing migrado: frontend/pideloo-landing → apps/landing"
    echo "  • Zustand stores creados en apps/mobile/src/stores/"
    echo "  • Zod schemas creados en apps/mobile/src/schemas/"
    echo "  • Documentación completa en docs/"
    echo "  • Packages compartidos creados"
    
    echo ""
    echo -e "${YELLOW}Próximos pasos:${RESET}"
    echo "  1. Revisar archivos migrados en apps/"
    echo "  2. Copiar .env.example a .env y configurar"
    echo "  3. pnpm install"
    echo "  4. pnpm dev"
    
    echo ""
    echo -e "${MAGENTA}📚 Documentación disponible:${RESET}"
    echo "  • docs/modules/identity.md"
    echo "  • docs/modules/catalog.md"
    echo "  • docs/modules/ordering.md"
    echo "  • docs/modules/network.md"
    echo "  • docs/flows/"
    echo "  • docs/architecture/"
}

# ============================================
# EJECUCIÓN PRINCIPAL
# ============================================

main() {
    review_current
    create_monorepo_structure
    migrate_backend
    migrate_mobile
    migrate_web
    migrate_landing
    create_packages
    create_documentation
    create_final_root_files
    print_summary
}

main "$@"
```

