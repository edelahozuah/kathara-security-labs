#!/bin/bash
#
# Script 08: Monitor de Grupo
# Muestra logs en tiempo real de un grupo
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
    echo "  --recursos      Mostrar uso de CPU/RAM"
    echo "  --logs          Mostrar logs de contenedores"
    echo "  -h, --help      Mostrar esta ayuda"
    echo ""
    echo "Ejemplo:"
    echo "  $0 grupo01"
    echo "  $0 grupo01 --recursos"
    exit 0
}

# Verificar argumentos
if [[ $# -lt 1 ]]; then
    usage
fi

GRUPO="$1"
shift

# Parsear opciones
MOSTRAR_RECURSOS=false
MOSTRAR_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --recursos)
            MOSTRAR_RECURSOS=true
            shift
            ;;
        --logs)
            MOSTRAR_LOGS=true
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
DIR_ESCENARIO=$(find "$DIR_GRUPO" -name "lab.conf" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)

if [[ -z "$DIR_ESCENARIO" ]]; then
    echo "ERROR: No se encuentra lab.conf en el grupo"
    exit 1
fi

# Verificar si está corriendo
if ! kathara linfo -d "$DIR_ESCENARIO" 2>/dev/null | grep -q "Running"; then
    echo "El grupo ${GRUPO} no está en ejecución"
    exit 1
fi

echo "=========================================="
echo "Monitor del Grupo ${GRUPO}"
echo "=========================================="
echo ""
echo "Presiona Ctrl+C para salir"
echo ""

# Si se solicitaron recursos
if [[ "$MOSTRAR_RECURSOS" == true ]]; then
    echo "Uso de recursos (actualización cada 2 segundos):"
    echo ""
    
    while true; do
        clear
        echo "=========================================="
        echo "Recursos - Grupo ${GRUPO}"
        echo "=========================================="
        echo ""
        
        # Obtener información de Docker
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null | grep -E "(kathara|NAME)" || echo "No se pudo obtener estadísticas"
        
        echo ""
        echo "Actualizado: $(date '+%H:%M:%S')"
        echo "Presiona Ctrl+C para salir"
        
        sleep 2
    done
fi

# Si se solicitaron logs
if [[ "$MOSTRAR_LOGS" == true ]]; then
    echo "Logs de contenedores (últimas 50 líneas, modo follow):"
    echo ""
    
    # Obtener lista de nodos
    NODOS=$(kathara linfo -d "$DIR_ESCENARIO" 2>/dev/null | grep "Running" | awk '{print $1}' | head -5)
    
    if [[ -z "$NODOS" ]]; then
        echo "No hay nodos en ejecución"
        exit 1
    fi
    
    # Mostrar logs del primer nodo
    PRIMER_NODO=$(echo "$NODOS" | head -1)
    echo "Mostrando logs del nodo: ${PRIMER_NODO}"
    echo "(Otros nodos: $(echo "$NODOS" | tail -n +2 | tr '\n' ' '))"
    echo ""
    
    docker logs -f --tail 50 "kathara_${GRUPO}_${PRIMER_NODO}" 2>/dev/null || \
        echo "No se pudieron obtener logs"
    
    exit 0
fi

# Por defecto: información general
echo "Información del grupo:"
echo ""

while true; do
    clear
    echo "=========================================="
    echo "Grupo ${GRUPO} - $(date '+%H:%M:%S')"
    echo "=========================================="
    echo ""
    
    # Estado de nodos
    echo "Estado de nodos:"
    kathara linfo -d "$DIR_ESCENARIO" 2>/dev/null || echo "No se pudo obtener información"
    
    echo ""
    echo "Conexiones activas:"
    
    # Extraer número de grupo para el puerto
    NUM_GRUPO=$(echo "$GRUPO" | grep -o '[0-9]*$' | sed 's/^0*//')
    PUERTO_VPN=$((BASE_PORT_VPN + NUM_GRUPO - 1))
    
    # Verificar conexiones WireGuard (si está disponible wg)
    if command -v wg &> /dev/null; then
        wg show | grep -A5 "${PUERTO_VPN}" 2>/dev/null | head -10 || echo "  (WireGuard no disponible o sin conexiones)"
    else
        echo "  (Comando wg no disponible)"
    fi
    
    echo ""
    echo "Puerto VPN: ${PUERTO_VPN}"
    echo ""
    echo "Comandos útiles:"
    echo "  ./08-monitor-grupo.sh ${GRUPO} --recursos   # Ver recursos"
    echo "  ./08-monitor-grupo.sh ${GRUPO} --logs       # Ver logs"
    echo ""
    echo "Presiona Ctrl+C para salir"
    
    sleep 5
done
