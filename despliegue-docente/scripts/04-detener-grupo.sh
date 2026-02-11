#!/bin/bash
#
# Script 04: Detener Grupo
# Detiene un escenario específico de un grupo
# Opcionalmente guarda el estado antes de detener
#

set -e

# Cargar configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/grupos.conf"

# Función de uso
usage() {
    echo "Uso: $0 <grupo> [opciones]"
    echo ""
    echo "Parámetros:"
    echo "  grupo              Nombre del grupo (ej: grupo01)"
    echo ""
    echo "Opciones:"
    echo "  --guardar-estado   Crear backup antes de detener"
    echo "  --forzar           Detener sin confirmación"
    echo "  -h, --help         Mostrar esta ayuda"
    echo ""
    echo "Ejemplo:"
    echo "  $0 grupo01"
    echo "  $0 grupo01 --guardar-estado"
    exit 0
}

# Verificar argumentos
if [[ $# -lt 1 ]]; then
    usage
fi

GRUPO="$1"
shift

# Parsear opciones
GUARDAR_ESTADO=false
FORZAR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --guardar-estado)
            GUARDAR_ESTADO=true
            shift
            ;;
        --forzar)
            FORZAR=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Opción desconocida: $1"
            usage
            ;;
    esac
done

# Validar grupo
DIR_GRUPO="${DIR_GRUPOS}/${GRUPO}"
if [[ ! -d "$DIR_GRUPO" ]]; then
    echo "ERROR: No existe el grupo: $GRUPO"
    exit 1
fi

# Buscar directorio del escenario
DIR_ESCENARIO=$(find "$DIR_GRUPO" -name "lab.conf" -type f | head -1 | xargs dirname)

if [[ -z "$DIR_ESCENARIO" ]]; then
    echo "ERROR: No se encuentra lab.conf en el grupo"
    exit 1
fi

# Verificar si está corriendo
if ! kathara linfo -d "$DIR_ESCENARIO" 2>/dev/null | grep -q "Running"; then
    echo "El grupo ${GRUPO} no está en ejecución"
    exit 0
fi

echo "=========================================="
echo "Deteniendo Grupo ${GRUPO}"
echo "=========================================="
echo ""

# Confirmar si no es forzado
if [[ "$FORZAR" != true ]]; then
    echo "¿Estás seguro de que quieres detener el grupo ${GRUPO}?"
    echo "Los contenedores se detendrán y las conexiones se perderán."
    echo ""
    read -p "Escribe 'si' para confirmar: " CONFIRMA
    
    if [[ "$CONFIRMA" != "si" ]]; then
        echo "Operación cancelada"
        exit 0
    fi
fi

# Guardar estado si se solicitó
if [[ "$GUARDAR_ESTADO" == true ]]; then
    echo "Guardando estado antes de detener..."
    "${DIR_SCRIPTS}/06-backup-grupo.sh" "$GRUPO" "auto-$(date +%Y%m%d-%H%M%S)"
    echo ""
fi

# Cambiar al directorio del escenario
cd "$DIR_ESCENARIO"

# Detener escenario
echo "Deteniendo contenedores..."
kathara lclean -d "$DIR_ESCENARIO"

# Guardar información de detención
LOG_FILE="${DIR_GRUPO}/logs/detencion-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"
{
    echo "Detención del grupo: $(date)"
    echo "Estado guardado: ${GUARDAR_ESTADO}"
} > "$LOG_FILE"

echo ""
echo "=========================================="
echo "Grupo ${GRUPO} detenido correctamente"
echo "=========================================="
echo ""
if [[ "$GUARDAR_ESTADO" == true ]]; then
    echo "Estado guardado. Puedes restaurarlo con:"
    echo "  ./07-restore-grupo.sh ${GRUPO} <nombre-backup>"
fi
echo ""
