#!/bin/bash
#
# Script 03: Iniciar Grupo
# Inicia un escenario específico de un grupo
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
    echo "  --con-ssh       Habilitar acceso SSH a nodos"
    echo "  -h, --help      Mostrar esta ayuda"
    echo ""
    echo "Ejemplo:"
    echo "  $0 grupo01"
    echo "  $0 grupo01 --con-ssh"
    exit 0
}

# Verificar argumentos
if [[ $# -lt 1 ]]; then
    usage
fi

GRUPO="$1"
shift

# Parsear opciones
CON_SSH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --con-ssh)
            CON_SSH=true
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
    echo "Ejecuta primero: ./01-generar-estructura-grupos.sh"
    exit 1
fi

# Extraer número de grupo y calcular parámetros
NUM_GRUPO=$(echo "$GRUPO" | grep -o '[0-9]*$' | sed 's/^0*//')
PUERTO_VPN=$((BASE_PORT_VPN + NUM_GRUPO - 1))
PUERTO_VNC=$((BASE_PORT_VNC + NUM_GRUPO - 1))
PUERTO_SSH=$((BASE_PORT_SSH + NUM_GRUPO - 1))
IP_LAN="${BASE_IP_LAN}.${NUM_GRUPO}"

echo "=========================================="
echo "Iniciando Grupo ${GRUPO}"
echo "=========================================="
echo ""
echo "Puerto VPN: ${PUERTO_VPN}"
echo "Puerto VNC: ${PUERTO_VNC}"
echo "Rango LAN: ${IP_LAN}.0/24"
if [[ "$CON_SSH" == true ]]; then
    echo "Puerto SSH: ${PUERTO_SSH} (mapeado a nodos)"
fi
echo ""

# Buscar directorio del escenario
DIR_ESCENARIO=$(find "$DIR_GRUPO" -name "lab.conf" -type f | head -1 | xargs dirname)

if [[ -z "$DIR_ESCENARIO" ]]; then
    echo "ERROR: No se encuentra lab.conf en el grupo"
    exit 1
fi

echo "Escenario: ${DIR_ESCENARIO}"
echo ""

# Verificar que no haya conflicto de puertos
if lsof -Pi :${PUERTO_VPN} -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "ERROR: El puerto ${PUERTO_VPN} ya está en uso"
    echo "¿El grupo ya está iniciado?"
    exit 1
fi

# Cambiar al directorio del escenario
cd "$DIR_ESCENARIO"

# Iniciar escenario
echo "Iniciando contenedores..."
kathara lstart -d "$DIR_ESCENARIO"

# Si se solicitó SSH, configurar mapeo de puertos
if [[ "$CON_SSH" == true && "$SSH_HABILITADO" == true ]]; then
    echo ""
    echo "Configurando acceso SSH..."
    
    # Detectar nodo router (o usar el primero disponible)
    NODO_ROUTER=$(kathara linfo -d "$DIR_ESCENARIO" 2>/dev/null | grep -E "router|r1" | head -1 | awk '{print $1}')
    
    if [[ -n "$NODO_ROUTER" ]]; then
        # Instalar y configurar SSH en el nodo
        kathara exec -d "$DIR_ESCENARIO" "$NODO_ROUTER" "apt-get update && apt-get install -y openssh-server" >/dev/null 2>&1 || true
        kathara exec -d "$DIR_ESCENARIO" "$NODO_ROUTER" "service ssh start" >/dev/null 2>&1 || true
        
        # Configurar contraseña root
        kathara exec -d "$DIR_ESCENARIO" "$NODO_ROUTER" "echo 'root:password' | chpasswd" >/dev/null 2>&1 || true
        
        # Obtener IP del nodo en el host
        # Nota: Esto requiere configuración adicional de Docker
        echo ""
        echo "SSH configurado en nodo: ${NODO_ROUTER}"
        echo "Usuario: root"
        echo "Contraseña: password"
        echo ""
        echo "Nota: Para acceso SSH externo, configura redirección de puertos"
        echo "      en el host Docker: ${PUERTO_SSH} -> nodo:22"
    fi
fi

# Guardar información de inicio
LOG_FILE="${DIR_GRUPO}/logs/inicio-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"
{
    echo "Inicio del grupo: $(date)"
    echo "Puerto VPN: ${PUERTO_VPN}"
    echo "Puerto VNC: ${PUERTO_VNC}"
    echo "Rango LAN: ${IP_LAN}.0/24"
    echo "SSH habilitado: ${CON_SSH}"
    echo ""
    echo "Contenedores activos:"
    kathara linfo -d "$DIR_ESCENARIO" 2>/dev/null || echo "No se pudo obtener info"
} > "$LOG_FILE"

echo ""
echo "=========================================="
echo "Grupo ${GRUPO} iniciado correctamente"
echo "=========================================="
echo ""
echo "Información de acceso:"
echo "  - VPN: Puerto UDP ${PUERTO_VPN}"
echo "  - VNC: ${IP_LAN}.2:${PUERTO_VNC} (dentro de la VPN)"
echo "  - Logs: ${LOG_FILE}"
echo ""
echo "Comandos útiles:"
echo "  ./04-detener-grupo.sh ${GRUPO}"
echo "  ./05-estado-grupos.sh"
echo "  ./08-monitor-grupo.sh ${GRUPO}"
echo ""
