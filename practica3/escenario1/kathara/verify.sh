#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAIT_FOR_HANDSHAKE=0
VERBOSE=false

usage() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --wait-for-handshake N   Esperar N segundos por handshake WireGuard"
    echo "  --verbose                Mostrar salida detallada"
    echo "  -h, --help              Mostrar ayuda"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --wait-for-handshake) WAIT_FOR_HANDSHAKE="$2"; shift 2 ;;
        --verbose) VERBOSE=true; shift ;;
        -h|--help) usage ;;
        *) echo "Opcion desconocida: $1"; usage ;;
    esac
done

cd "$SCRIPT_DIR"

ERRORS=0

check_cmd() {
    local node="$1"
    local cmd="$2"
    local desc="$3"
    
    if [[ "$VERBOSE" == true ]]; then
        echo "  Verificando: $desc"
        if kathara exec -d "$SCRIPT_DIR" "$node" "$cmd" &>/dev/null; then
            echo "    [OK] $desc"
            return 0
        else
            echo "    [FAIL] $desc"
            ((ERRORS++)) || true
            return 1
        fi
    else
        if kathara exec -d "$SCRIPT_DIR" "$node" "$cmd" &>/dev/null; then
            echo "  [OK] $desc"
            return 0
        else
            echo "  [FAIL] $desc"
            ((ERRORS++)) || true
            return 1
        fi
    fi
}

echo "=== Verificacion Practica3 ==="
echo ""

# Check if lab is running
if ! kathara list 2>/dev/null | grep -q "Practica3_kathara"; then
    echo "ERROR: El laboratorio no esta corriendo"
    exit 1
fi

# 1. Check routing and forwarding
echo "[1/6] Verificando enrutamiento..."
check_cmd router "cat /proc/sys/net/ipv4/ip_forward | grep -q 1" "IP forwarding en router"
check_cmd natgw "cat /proc/sys/net/ipv4/ip_forward | grep -q 1" "IP forwarding en natgw"
check_cmd vpn "cat /proc/sys/net/ipv4/ip_forward | grep -q 1" "IP forwarding en vpn"

# 2. Check LAN connectivity
echo ""
echo "[2/6] Verificando conectividad LAN..."
check_cmd victima "ping -c 1 -W 2 192.168.0.3" "victima -> atacante"
check_cmd atacante "ping -c 1 -W 2 192.168.0.2" "atacante -> victima"
check_cmd victima "ping -c 1 -W 2 192.168.0.1" "victima -> router"
check_cmd atacante "ping -c 1 -W 2 192.168.0.1" "atacante -> router"

# 3. Check WAN connectivity
echo ""
echo "[3/6] Verificando conectividad WAN..."
check_cmd router "ping -c 1 -W 2 10.255.0.1" "router -> natgw"
check_cmd natgw "ping -c 1 -W 2 10.255.0.2" "natgw -> router"

# 4. Check Internet access
echo ""
echo "[4/6] Verificando acceso a Internet..."
check_cmd victima "ping -c 1 -W 3 8.8.8.8" "victima -> Internet (8.8.8.8)"
check_cmd atacante "ping -c 1 -W 3 8.8.8.8" "atacante -> Internet (8.8.8.8)"
check_cmd router "ping -c 1 -W 3 8.8.8.8" "router -> Internet (8.8.8.8)"

# 5. Check DNS
echo ""
echo "[5/6] Verificando DNS..."
check_cmd victima "nslookup google.com" "victima DNS"
check_cmd atacante "nslookup google.com" "atacante DNS"

# 6. Check WireGuard (if vpn node exists)
if kathara list 2>/dev/null | grep -q "vpn"; then
    echo ""
    echo "[6/6] Verificando WireGuard..."
    
    # Check if WireGuard interface exists
    if kathara exec -d "$SCRIPT_DIR" vpn "ip link show wg0" &>/dev/null; then
        echo "  [OK] Interfaz wg0 existe"
        
        # Wait for handshake if requested
        if [[ $WAIT_FOR_HANDSHAKE -gt 0 ]]; then
            echo "  Esperando handshake (${WAIT_FOR_HANDSHAKE}s)..."
            HANDSHAKE_OK=false
            for i in $(seq 1 $WAIT_FOR_HANDSHAKE); do
                if kathara exec -d "$SCRIPT_DIR" vpn "wg show | grep -q 'latest handshake'" &>/dev/null; then
                    HANDSHAKE_OK=true
                    break
                fi
                sleep 1
            done
            
            if [[ "$HANDSHAKE_OK" == true ]]; then
                echo "  [OK] Handshake WireGuard detectado"
            else
                echo "  [WARN] No se detecto handshake (puede ser normal si no hay cliente conectado)"
            fi
        fi
        
        # Show WireGuard status
        if [[ "$VERBOSE" == true ]]; then
            echo ""
            echo "  Estado WireGuard:"
            kathara exec -d "$SCRIPT_DIR" vpn "wg show" || true
        fi
    else
        echo "  [FAIL] Interfaz wg0 no encontrada"
        ((ERRORS++)) || true
    fi
fi

# 7. Check VNC (if victima exists)
if kathara list 2>/dev/null | grep -q "victima"; then
    echo ""
    echo "[7/6] Verificando VNC en victima..."
    if kathara exec -d "$SCRIPT_DIR" victima "ss -tln | grep -q ':5901'" &>/dev/null; then
        echo "  [OK] Servidor VNC escuchando en :5901"
    else
        echo "  [FAIL] Servidor VNC no disponible"
        ((ERRORS++)) || true
    fi
fi

echo ""
echo "=== Resumen ==="
if [[ $ERRORS -eq 0 ]]; then
    echo "Todas las verificaciones pasaron correctamente."
    exit 0
else
    echo "Se encontraron $ERRORS errores."
    exit 1
fi
