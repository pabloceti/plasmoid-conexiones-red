#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ID="plasmoid-conexiones-red"
SOURCE_DIR="${SCRIPT_DIR}"
TARGET_BASE="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids"
TARGET_DIR="${TARGET_BASE}/${APP_ID}"
RELOAD_PLASMA=1
DRY_RUN=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [--target-dir PATH] [--no-reload] [--dry-run]

Instala el plasmoide en el directorio local de Plasma.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target-dir)
            [[ $# -ge 2 ]] || { echo "Falta el valor de --target-dir" >&2; exit 1; }
            TARGET_DIR="$2"
            shift 2
            ;;
        --no-reload)
            RELOAD_PLASMA=0
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Opción desconocida: $1" >&2
            usage
            exit 1
            ;;
    esac
done

check_dependency() {
    local module_name="$1"
    local package_name="$2"

    if ! python3 - <<PY >/dev/null 2>&1
import importlib.util
raise SystemExit(0 if importlib.util.find_spec("${module_name}") else 1)
PY
    then
        echo "Falta la dependencia de Python: ${package_name}" >&2
        echo "Instálala con tu gestor de paquetes o pip antes de usar el plasmoide." >&2
        exit 1
    fi
}

check_dependency "psutil" "psutil"
check_dependency "requests" "requests"

if [[ ! -f "${SOURCE_DIR}/metadata.json" ]]; then
    echo "No se encontró metadata.json en ${SOURCE_DIR}" >&2
    exit 1
fi

mkdir -p "${TARGET_DIR}"

if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "Instalación en modo prueba"
    echo "Origen:      ${SOURCE_DIR}"
    echo "Destino:     ${TARGET_DIR}"
    echo "Acción:      copiar carpeta completa"
    exit 0
fi

rm -rf "${TARGET_DIR}"
cp -a "${SOURCE_DIR}" "${TARGET_DIR}"
chmod +x "${TARGET_DIR}/contents/scripts/network_table.py"

if [[ "${RELOAD_PLASMA}" -eq 1 ]]; then
    if command -v kquitapp5 >/dev/null 2>&1 && command -v kstart5 >/dev/null 2>&1; then
        if pgrep -x plasmashell >/dev/null 2>&1; then
            kquitapp5 plasmashell >/dev/null 2>&1 || true
            nohup kstart5 plasmashell >/dev/null 2>&1 &
        fi
    elif command -v kquitapp6 >/dev/null 2>&1 && command -v kstart6 >/dev/null 2>&1; then
        if pgrep -x plasmashell >/dev/null 2>&1; then
            kquitapp6 plasmashell >/dev/null 2>&1 || true
            nohup kstart6 plasmashell >/dev/null 2>&1 &
        fi
    fi
fi

echo "Plasmoide instalado en: ${TARGET_DIR}"
echo "Busca 'Conexiones de Red' en la lista de widgets de Plasma."
