#!/bin/bash
#
# Script 01: Generar Estructura de Grupos
# Crea la estructura de directorios para N grupos con escenarios independientes
#

set -e

# Cargar configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/grupos.conf"

# Función de uso
usage() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --practica <nombre>     Nombre de la práctica (default: ${PRACTICA_DEFAULT})"
    echo "  --escenario <nombre>    Nombre del escenario (default: ${ESCENARIO_DEFAULT})"
    echo "  --num-grupos <n>        Número de grupos a crear (default: ${NUM_GRUPOS})"
    echo "  -h, --help              Mostrar esta ayuda"
    echo ""
    echo "Ejemplo:"
    echo "  $0 --practica practica3 --escenario escenario1 --num-grupos 20"
    exit 0
}

# Parsear argumentos
PRACTICA="${PRACTICA_DEFAULT}"
ESCENARIO="${ESCENARIO_DEFAULT}"
NUM_GRUPOS_INPUT="${NUM_GRUPOS}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --practica)
            PRACTICA="$2"
            shift 2
            ;;
        --escenario)
            ESCENARIO="$2"
            shift 2
            ;;
        --num-grupos)
            NUM_GRUPOS_INPUT="$2"
            shift 2
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

# Validar escenario base
ESCENARIO_BASE_PATH="${DIR_BASE}/../${PRACTICA}/${ESCENARIO}/kathara"
if [[ ! -d "$ESCENARIO_BASE_PATH" ]]; then
    echo "ERROR: No se encuentra el escenario base: ${ESCENARIO_BASE_PATH}"
    echo "Verifica que la práctica y el escenario existen."
    exit 1
fi

echo "=========================================="
echo "Generando Estructura de Grupos"
echo "=========================================="
echo ""
echo "Práctica: ${PRACTICA}"
echo "Escenario: ${ESCENARIO}"
echo "Número de grupos: ${NUM_GRUPOS_INPUT}"
echo ""

# Crear directorios base
mkdir -p "${DIR_LISTAS}"

# Generar cada grupo
for ((i=1; i<=NUM_GRUPOS_INPUT; i++)); do
    # Formatear número con leading zero (01, 02, ..., 20)
    NUM_GRUPO=$(printf "%02d" $i)
    DIR_GRUPO="${DIR_GRUPOS}/${GRUPO_PREFIX}${NUM_GRUPO}"
    
    echo -n "Generando grupo ${NUM_GRUPO}... "
    
    # Crear estructura de directorios
    mkdir -p "${DIR_GRUPO}/${PRACTICA}/${ESCENARIO}"
    mkdir -p "${DIR_GRUPO}/configs"
    mkdir -p "${DIR_GRUPO}/backups"
    mkdir -p "${DIR_GRUPO}/logs"
    
    # Calcular valores específicos del grupo
    PUERTO_VPN=$((BASE_PORT_VPN + i - 1))
    PUERTO_VNC=$((BASE_PORT_VNC + i - 1))
    PUERTO_SSH=$((BASE_PORT_SSH + i - 1))
    IP_LAN="${BASE_IP_LAN}.${i}"
    IP_WG="${BASE_IP_WG}.${i}"
    
    # Copiar escenario base
    cp -r "${ESCENARIO_BASE_PATH}/"* "${DIR_GRUPO}/${PRACTICA}/${ESCENARIO}/"
    
    # Modificar lab.conf con valores específicos del grupo
    LAB_CONF="${DIR_GRUPO}/${PRACTICA}/${ESCENARIO}/lab.conf"
    
    if [[ -f "$LAB_CONF" ]]; then
        # Crear backup del original
        cp "$LAB_CONF" "${LAB_CONF}.original"
        
        # Modificar configuración VPN si existe
        if grep -q "vpn\[0\]" "$LAB_CONF"; then
            # Actualizar puerto VPN
            sed -i.bak "s/vpn\[port\]=\"51820:51820\/udp\"/vpn[port]=\"${PUERTO_VPN}:51820\/udp\"/g" "$LAB_CONF"
            
            # Actualizar IPs VPN
            sed -i.bak "s/192\.168\.0\./${IP_LAN}./g" "$LAB_CONF"
            
            # Actualizar rango WireGuard
            sed -i.bak "s/10\.99\.0\./${IP_WG}./g" "$LAB_CONF"
            
            # Actualizar CIDRs
            sed -i.bak "s/192\.168\.0\.0\/24/${IP_LAN}.0\/24/g" "$LAB_CONF"
            sed -i.bak "s/10\.99\.0\.0\/24/${IP_WG}.0\/24/g" "$LAB_CONF"
        fi
        
        # Añadir metadatos al final del lab.conf
        cat >> "$LAB_CONF" << EOF

# ============================================
# METADATOS DEL GRUPO ${NUM_GRUPO}
# ============================================
# Generado automáticamente por 01-generar-estructura-grupos.sh
# Fecha: $(date '+%Y-%m-%d %H:%M:%S')
#
# Puerto VPN: ${PUERTO_VPN}
# Puerto VNC: ${PUERTO_VNC}
# Puerto SSH: ${PUERTO_SSH}
# Rango LAN: ${IP_LAN}.0/24
# Rango WireGuard: ${IP_WG}.0/24
# ============================================
EOF
        
        rm -f "${LAB_CONF}.bak"
    fi
    
    # Crear archivo de lista vacío para el grupo
    touch "${DIR_LISTAS}/${GRUPO_PREFIX}${NUM_GRUPO}-estudiantes.txt"
    
    # Crear README específico del grupo
    cat > "${DIR_GRUPO}/README.txt" << EOF
Grupo ${NUM_GRUPO}
==========

Configuración:
- Puerto VPN: ${PUERTO_VPN}
- Puerto VNC: ${PUERTO_VNC}
- Puerto SSH: ${PUERTO_SSH}
- Rango LAN: ${IP_LAN}.0/24
- Rango WireGuard: ${IP_WG}.0/24

Estructura:
- ${PRACTICA}/${ESCENARIO}/    - Escenario Kathara
- configs/            - Configuraciones VPN de estudiantes
- backups/            - Snapshots del estado
- logs/               - Logs de ejecución

Comandos útiles:
  ./scripts/03-iniciar-grupo.sh ${GRUPO_PREFIX}${NUM_GRUPO}
  ./scripts/04-detener-grupo.sh ${GRUPO_PREFIX}${NUM_GRUPO}
  ./scripts/05-estado-grupos.sh
EOF
    
    echo "OK"
done

echo ""
echo "=========================================="
echo "Estructura generada correctamente"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Edita los archivos en ${DIR_LISTAS}/"
echo "   Ejemplo: ${GRUPO_PREFIX}01-estudiantes.txt"
echo "   (Un email por línea)"
echo ""
echo "2. Ejecuta: ./scripts/02-generar-vpn-configs.sh"
echo ""
echo "3. Inicia los grupos: ./scripts/03-iniciar-grupo.sh ${GRUPO_PREFIX}01"
echo ""
