#!/bin/bash
#
# Script 05: Estado de Grupos
# Muestra el estado de todos los grupos en formato de tabla
#

set -e

# Cargar configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/grupos.conf"

# Función para obtener estado de un grupo
get_estado_grupo() {
    local grupo="$1"
    local dir_grupo="${DIR_GRUPOS}/${grupo}"
    
    if [[ ! -d "$dir_grupo" ]]; then
        echo "NO_EXISTE"
        return
    fi
    
    # Buscar escenario
    local dir_escenario=$(find "$dir_grupo" -name "lab.conf" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
    
    if [[ -z "$dir_escenario" ]]; then
        echo "SIN_ESCENARIO"
        return
    fi
    
    # Verificar si está corriendo
    if kathara linfo -d "$dir_escenario" 2>/dev/null | grep -q "Running"; then
        echo "ACTIVO"
    else
        echo "DETENIDO"
    fi
}

# Función para obtener número de estudiantes configurados
get_num_estudiantes() {
    local grupo="$1"
    local dir_configs="${DIR_GRUPOS}/${grupo}/configs"
    
    if [[ ! -d "$dir_configs" ]]; then
        echo "0"
        return
    fi
    
    ls -1 "${dir_configs}"/*.conf 2>/dev/null | grep -v "_maestro.txt" | wc -l
}

# Función para obtener información de recursos
get_recursos() {
    local grupo="$1"
    local dir_escenario=$(find "${DIR_GRUPOS}/${grupo}" -name "lab.conf" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
    
    if [[ -z "$dir_escenario" ]]; then
        echo "N/A"
        return
    fi
    
    # Contar contenedores
    local num_contenedores=$(kathara linfo -d "$dir_escenario" 2>/dev/null | grep -c "Running" || echo "0")
    echo "${num_contenedores} nodos"
}

echo "=========================================="
echo "Estado de los Grupos"
echo "=========================================="
echo ""

# Verificar si existen grupos
if [[ ! -d "$DIR_GRUPOS" ]] || [[ -z "$(ls -A $DIR_GRUPOS 2>/dev/null)" ]]; then
    echo "No se encontraron grupos."
    echo "Ejecuta primero: ./01-generar-estructura-grupos.sh"
    exit 0
fi

# Imprimir cabecera de tabla
printf "%-10s | %-12s | %-10s | %-15s | %s\n" "GRUPO" "ESTADO" "ESTUDIANTES" "RECURSOS" "PUERTO VPN"
printf "%s\n" "-----------+--------------+------------+-----------------+-----------"

# Iterar sobre todos los grupos
for ((i=1; i<=NUM_GRUPOS; i++)); do
    NUM_GRUPO=$(printf "%02d" $i)
    GRUPO="${GRUPO_PREFIX}${NUM_GRUPO}"
    
    ESTADO=$(get_estado_grupo "$GRUPO")
    
    # Saltar si no existe
    if [[ "$ESTADO" == "NO_EXISTE" ]]; then
        continue
    fi
    
    NUM_ESTUDIANTES=$(get_num_estudiantes "$GRUPO")
    RECURSOS=$(get_recursos "$GRUPO")
    PUERTO_VPN=$((BASE_PORT_VPN + i - 1))
    
    # Color según estado
    if [[ "$ESTADO" == "ACTIVO" ]]; then
        ESTADO_DISPLAY="✅ ACTIVO"
    elif [[ "$ESTADO" == "DETENIDO" ]]; then
        ESTADO_DISPLAY="⏹️  DETENIDO"
    else
        ESTADO_DISPLAY="⚠️  ${ESTADO}"
    fi
    
    printf "%-10s | %-12s | %-10s | %-15s | %s\n" \
        "$GRUPO" "$ESTADO_DISPLAY" "$NUM_ESTUDIANTES" "$RECURSOS" "$PUERTO_VPN"
done

echo ""
echo "=========================================="
echo ""
echo "Resumen:"
echo "  Total grupos: ${NUM_GRUPOS}"
echo "  Activos: $(for g in ${DIR_GRUPOS}/${GRUPO_PREFIX}*; do get_estado_grupo "$(basename $g)"; done 2>/dev/null | grep -c "ACTIVO" || echo 0)"
echo ""
echo "Comandos útiles:"
echo "  ./03-iniciar-grupo.sh grupo01       # Iniciar un grupo"
echo "  ./04-detener-grupo.sh grupo01       # Detener un grupo"
echo "  ./06-backup-grupo.sh grupo01        # Backup de un grupo"
echo ""
