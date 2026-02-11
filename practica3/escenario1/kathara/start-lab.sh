#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_NAME="Practica3_kathara"
WG_PORT=51820
FORCE_PROXY=false
CLI_ONLY=false

usage() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --cli-only       Modo solo CLI (sin VPN ni escritorio)"
    echo "  --force-proxy    Forzar uso de proxy UDP local"
    echo "  -h, --help       Mostrar ayuda"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --cli-only) CLI_ONLY=true; shift ;;
        --force-proxy) FORCE_PROXY=true; shift ;;
        -h|--help) usage ;;
        *) echo "Opcion desconocida: $1"; usage ;;
    esac
done

cd "$SCRIPT_DIR"

echo "=== Practica 3 MITM HTTP - Kathara ==="
echo ""

# Check if kathara is installed
if ! command -v kathara &> /dev/null; then
    echo "ERROR: Kathara no esta instalado"
    exit 1
fi

# Check Docker
if ! docker info &>/dev/null; then
    echo "ERROR: Docker no esta corriendo"
    exit 1
fi

# Build images (conditional)
echo "[0/6] Verificando imagenes Docker..."

if ! docker image inspect kathara-vpn &>/dev/null; then
    echo "  - Construyendo kathara-vpn..."
    docker build -t kathara-vpn -f Dockerfile.vpn .
else
    echo "  ✓ kathara-vpn existe"
fi

if ! docker image inspect kathara-desktop &>/dev/null; then
    echo "  - Construyendo kathara-desktop..."
    docker build -t kathara-desktop -f Dockerfile.desktop .
else
    echo "  ✓ kathara-desktop existe"
fi

if ! docker image inspect kathara-kali &>/dev/null; then
    echo "  - Construyendo kathara-kali..."
    docker build -t kathara-kali -f Dockerfile.kali .
else
    echo "  ✓ kathara-kali existe"
fi

# Prepare shared directory
mkdir -p shared/vpn
chmod 755 shared/vpn

# Detect if we need UDP proxy (macOS/Windows)
NEEDS_PROXY=false
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    NEEDS_PROXY=true
fi
if [[ "$FORCE_PROXY" == true ]]; then
    NEEDS_PROXY=true
fi

# Clean any existing lab
echo "[1/6] Limpiando laboratorio anterior..."
kathara lclean -d "$SCRIPT_DIR" 2>/dev/null || true

# Start the lab
echo "[2/6] Iniciando laboratorio..."
if [[ "$CLI_ONLY" == true ]]; then
    echo "  Modo: CLI-only (victima, atacante, router, natgw)"
    kathara lstart -d "$SCRIPT_DIR" victima atacante router natgw
else
    echo "  Modo: Completo (incluye VPN y escritorio)"
    kathara lstart -d "$SCRIPT_DIR"
fi

# Setup WireGuard endpoint
if [[ "$CLI_ONLY" == false ]]; then
    echo ""
    echo "[3/6] Configurando WireGuard..."
    
    # Get host IP for WireGuard endpoint
    HOST_IP=""
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        HOST_IP=$(hostname -I | awk '{print $1}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        HOST_IP=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | head -n1 | awk '{print $2}')
    fi
    
    if [[ -z "$HOST_IP" ]]; then
        HOST_IP="127.0.0.1"
    fi
    
    # Setup UDP proxy if needed
    PROXY_PORT=""
    if [[ "$NEEDS_PROXY" == true ]]; then
        echo "  Detectado sistema que requiere proxy UDP..."
        
        # Kill existing proxy
        if docker ps --format "table {{.Names}}" | grep -q "^wg-proxy$"; then
            docker stop wg-proxy &>/dev/null || true
            docker rm wg-proxy &>/dev/null || true
        fi
        
        # Find available port
        PROXY_PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()")
        
        # Start UDP proxy
        docker run -d --name wg-proxy --network host \
            -p "${PROXY_PORT}:${WG_PORT}/udp" \
            --restart unless-stopped \
            alpine/socat UDP-LISTEN:"${PROXY_PORT}",fork UDP:127.0.0.1:"${WG_PORT}" &>/dev/null
        
        echo "  Proxy UDP iniciado en puerto ${PROXY_PORT}"
        HOST_IP="127.0.0.1"
        WG_ENDPOINT_PORT="$PROXY_PORT"
    else
        WG_ENDPOINT_PORT="$WG_PORT"
    fi
    
    # Wait for VPN to be ready
    echo "  Esperando a que VPN este listo..."
    sleep 3
    
    # Update client config with correct endpoint
    sed -i.bak "s/CHANGE_ME_HOST_OR_DNS/${HOST_IP}/g" shared/vpn/student1.conf 2>/dev/null || true
    sed -i.bak "s/:51820/:${WG_ENDPOINT_PORT}/g" shared/vpn/student1.conf 2>/dev/null || true
    rm -f shared/vpn/student1.conf.bak
    
    echo ""
    echo "[4/6] Resumen de acceso:"
    echo "  - VPN Config: ./shared/vpn/student1.conf"
    echo "  - Endpoint: ${HOST_IP}:${WG_ENDPOINT_PORT}"
    echo "  - VNC Server: 192.168.0.2:5901"
    echo "  - VNC Password: password"
    echo "  - Bettercap UI: http://192.168.0.3 (desde VPN)"
    echo ""
    echo "Para conectar:"
    echo "  1. Importa ./shared/vpn/student1.conf en tu cliente WireGuard"
    echo "  2. Activa el tunel VPN"
    echo "  3. Conecta VNC a 192.168.0.2:5901"
    echo "  4. Accede a Bettercap UI en http://192.168.0.3"
    echo ""
fi

echo "[5/6] Laboratorio iniciado correctamente."
echo ""
echo "Comandos utiles:"
echo "  ./verify.sh        # Verificar conectividad"
echo "  ./stop-lab.sh      # Detener laboratorio"
echo ""
echo "[6/6] Configuracion completada."
