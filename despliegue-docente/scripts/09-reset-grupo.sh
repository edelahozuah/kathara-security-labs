#!/bin/bash
#
# Script 09: Reset de Grupo
# Limpieza completa de un grupo (vuelve a estado inicial)
# ⚠️ ATENCIÓN: Esto elimina todos los datos y contenedores
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
    echo "  grupo           Nombre del grupo (ej: grupo01)"
    echo ""
    echo "Opciones:"
    echo "  --forzar        No pedir confirmación"
    echo "  --sin-backup    No crear backup antes de resetear"
    echo "  -h, --help      Mostrar esta ayuda"
    echo ""
    echo "⚠️  ADVERTENCIA:"
    echo "   Este comando elimina TODOS los datos del grupo:"
    echo "   - Contenedores y redes Docker"
    echo "   - Archivos en shared/"
    echo "   - Configuraciones modificadas"
    echo "   - Logs y datos de sesiones"
    echo ""
    echo "   El grupo volverá al estado inicial del escenario."
    echo ""
    exit 0
}

# Verificar argumentos
if [[ $# -lt 1 ]]; then
    usage
fi

GRUPO="$1"
shift

# Parsear opciones
FORZAR=false
SIN_BACKUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --forzar)
            FORZAR=true
            shift
            ;;
        --sin-backup)
            SIN_BACKUP=true
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

echo "=========================================="
echo "RESET del Grupo ${GRUPO}"
echo "=========================================="
echo ""

# Advertencia
if [[ "$FORZAR" != true ]]; then
    echo "⚠️  ADVERTENCIA ⚠️"
    echo ""
    echo "Estás a punto de RESETEAR completamente el grupo ${GRUPO}."
    echo ""
    echo "Esto eliminará:"
    echo "  ❌ Todos los contenedores Docker"
    echo "  ❌ Todas las redes del grupo"
    echo "  ❌ Archivos en shared/"
    echo "  ❌ Configuraciones modificadas"
    echo "  ❌ Logs y datos de sesiones"
    echo ""
    
    if [[ "$SIN_BACKUP" != true ]]; then
        echo "Se creará un backup automático antes del reset."
    else
        echo "⚠️  NO se creará backup (--sin-backup especificado)"
    fi
    
    echo ""
    echo "El grupo volverá al estado inicial del escenario."
    echo ""
    read -p "¿Estás seguro? Escribe 'RESET' para confirmar: " CONFIRMAR
    
    if [[ "$CONFIRMAR" != "RESET" ]]; then
        echo "Operación cancelada"
        exit 0
    fi
fi

# Crear backup antes de resetear (si no se especificó lo contrario)
if [[ "$SIN_BACKUP" != true ]]; then
    echo "Creando backup de seguridad..."
    BACKUP_PRE="pre-reset-$(date +%Y%m%d-%H%M%S)"
    "${DIR_SCRIPTS}/06-backup-grupo.sh" "$GRUPO" "$BACKUP_PRE" >/dev/null 2>&1 || true
    echo "Backup creado: ${BACKUP_PRE}"
    echo ""
fi

# Buscar directorio del escenario
DIR_ESCENARIO=$(find "$DIR_GRUPO" -name "lab.conf" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)

# Detener si está corriendo
if [[ -n "$DIR_ESCENARIO" ]]; then
    if kathara linfo -d "$DIR_ESCENARIO" 2>/dev/null | grep -q "Running"; then
        echo "Deteniendo contenedores..."
        kathara lclean -d "$DIR_ESCENARIO" 2>/dev/null || true
    fi
fi

# Eliminar redes Docker del grupo
echo "Eliminando redes..."
NUM_GRUPO=$(echo "$GRUPO" | grep -o '[0-9]*$' | sed 's/^0*//')
docker network ls --format "{{.Name}}" | grep "${GRUPO}" | while read network; do
    docker network rm "$network" 2>/dev/null || true
done

# Eliminar contenedores huérfanos
echo "Limpiando contenedores..."
docker ps -a --format "{{.Names}}" | grep "${GRUPO}" | while read container; do
    docker rm -f "$container" 2>/dev/null || true
done

# Limpiar directorio shared
echo "Limpiando datos..."
if [[ -d "${DIR_ESCENARIO}/shared" ]]; then
    rm -rf "${DIR_ESCENARIO}/shared/*"
    mkdir -p "${DIR_ESCENARIO}/shared"
fi

# Restaurar configuraciones originales
echo "Restaurando configuraciones originales..."
if [[ -f "${DIR_ESCENARIO}/lab.conf.original" ]]; then
    cp "${DIR_ESCENARIO}/lab.conf.original" "${DIR_ESCENARIO}/lab.conf"
fi

# Limpiar logs antiguos (opcional - mantener los últimos 10)
echo "Limpiando logs antiguos..."
if [[ -d "${DIR_GRUPO}/logs" ]]; then
    ls -t "${DIR_GRUPO}/logs/"/*.log 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
fi

# Guardar registro del reset
LOG_RESET="${DIR_GRUPO}/logs/reset-$(date +%Y%m%d-%H%M%S).log"
{
    echo "Reset del grupo: $(date)"
    echo "Backup previo: ${BACKUP_PRE:-Ninguno}"
} > "$LOG_RESET"

echo ""
echo "=========================================="
echo "Reset completado"
echo "=========================================="
echo ""
echo "El grupo ${GRUPO} ha sido reseteado al estado inicial."
echo ""
if [[ -n "$BACKUP_PRE" ]]; then
    echo "Backup de seguridad: ${BACKUP_PRE}"
fi
echo ""
echo "Para iniciar el grupo de nuevo:"
echo "  ./03-iniciar-grupo.sh ${GRUPO}"
echo ""
