#!/bin/bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_NAME="${WG_PROXY_NAME:-wg-proxy}"
WG_PORT="${WG_PORT:-51820}"

WAIT_HANDSHAKE=25
VERBOSE=0
SKIP_HOST_PING=0

usage() {
  cat <<'EOF'
Uso: ./verify.sh [opciones]

Opciones:
  --wait-for-handshake <n>  Segundos maximos esperando handshake (por defecto 25)
  --skip-host-ping          Omite ping desde host al laboratorio via VPN
  -v, --verbose             Muestra diagnostico adicional
  -h, --help                Muestra esta ayuda
EOF
}

detect_platform() {
  local uname_s
  uname_s="$(uname -s 2>/dev/null || echo unknown)"

  case "${uname_s}" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "windows-wsl"
      else
        echo "linux"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "windows"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

kexec() {
  local node="$1"
  local cmd="$2"
  kathara exec -d "${LAB_DIR}" "${node}" "${cmd}"
}

is_node_running() {
  local node="$1"
  kathara exec -d "${LAB_DIR}" "${node}" "true" >/dev/null 2>&1
}

get_vpn_container_id() {
  local target_bridge_ip
  local container_id
  local candidate_bridge_ip

  target_bridge_ip="$(kexec vpn "ip -4 -o addr show dev eth1" 2>/dev/null | sed -n 's/.*inet \([0-9.]*\)\/.*/\1/p' | head -n 1 || true)"

  if [[ -n "${target_bridge_ip}" ]]; then
    while IFS= read -r container_id; do
      [[ -z "${container_id}" ]] && continue
      candidate_bridge_ip="$(docker inspect "${container_id}" --format '{{with index .NetworkSettings.Networks "bridge"}}{{.IPAddress}}{{end}}' 2>/dev/null || true)"
      if [[ "${candidate_bridge_ip}" == "${target_bridge_ip}" ]]; then
        echo "${container_id}"
        return 0
      fi
    done < <(docker ps --filter "label=app=kathara" --filter "label=name=vpn" --filter "status=running" --format '{{.ID}}')
  fi

  docker ps --filter "label=app=kathara" --filter "label=name=vpn" --filter "status=running" --format '{{.ID}}' | head -n 1
}

get_client_name() {
  sed -n 's/^vpn\[env\]="WG_CLIENT_NAME=\([^"]*\)".*/\1/p' "${LAB_DIR}/lab.conf" | tail -n 1
}

get_client_conf_path() {
  local client_name
  local candidate
  client_name="$(get_client_name)"

  if [[ -n "${client_name}" ]]; then
    candidate="${LAB_DIR}/shared/vpn/${client_name}.conf"
    if [[ -f "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  fi

  for candidate in "${LAB_DIR}"/shared/vpn/*.conf; do
    if [[ -f "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done

  echo ""
}

has_handshake() {
  local wg_output="$1"
  [[ "${wg_output}" == *"latest handshake"* ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wait-for-handshake)
      shift
      if [[ $# -eq 0 ]]; then
        echo "ERROR: falta valor para --wait-for-handshake" >&2
        exit 1
      fi
      WAIT_HANDSHAKE="$1"
      ;;
    --skip-host-ping)
      SKIP_HOST_PING=1
      ;;
    -v|--verbose)
      VERBOSE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: opcion no reconocida: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ ! "${WAIT_HANDSHAKE}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --wait-for-handshake debe ser un entero >= 0" >&2
  exit 1
fi

BASE_NODES=(victima atacante router natgw)
MISSING_NODES=()
for node in "${BASE_NODES[@]}"; do
  if ! is_node_running "${node}"; then
    MISSING_NODES+=("${node}")
  fi
done

if [[ ${#MISSING_NODES[@]} -gt 0 ]]; then
  echo "ERROR: faltan nodos base en ejecucion: ${MISSING_NODES[*]}" >&2
  echo "Sugerencia: ejecuta ./start-lab.sh o ./start-lab.sh --cli-only" >&2
  exit 1
fi

PLATFORM="$(detect_platform)"
VPN_RUNNING=0
DESKTOP_RUNNING=0
if is_node_running vpn; then
  VPN_RUNNING=1
fi
if is_node_running desktop; then
  DESKTOP_RUNNING=1
fi

echo "=== Verificacion escenario p2_2 ==="
echo "Plataforma: ${PLATFORM}"
if [[ ${VPN_RUNNING} -eq 1 && ${DESKTOP_RUNNING} -eq 1 ]]; then
  echo "Modo detectado: completo (VPN + GUI)"
elif [[ ${VPN_RUNNING} -eq 0 && ${DESKTOP_RUNNING} -eq 0 ]]; then
  echo "Modo detectado: CLI-only"
else
  echo "Modo detectado: mixto (revisar arranque)"
fi
echo ""

echo "1) Verificando forwarding"
echo "router:"
kexec router "cat /proc/sys/net/ipv4/ip_forward"
echo "natgw:"
kexec natgw "cat /proc/sys/net/ipv4/ip_forward"
if [[ ${VPN_RUNNING} -eq 1 ]]; then
  echo "vpn:"
  kexec vpn "cat /proc/sys/net/ipv4/ip_forward"
fi
echo ""

echo "2) Tablas de enrutamiento"
echo "router:"
kexec router "ip route"
echo "natgw:"
kexec natgw "ip route"
echo ""

echo "3) Conectividad LAN interna"
kexec victima "ping -c 2 192.168.0.3"
kexec atacante "ping -c 2 192.168.0.2"
echo ""

echo "4) Salida hacia gateway WAN"
kexec victima "ping -c 2 10.255.0.1"
echo ""

echo "5) Prueba opcional de Internet"
if kexec victima "ping -c 2 1.1.1.1"; then
  echo "Internet OK"
else
  echo "Internet no disponible desde el laboratorio (revisar salida del host)."
fi
echo ""

if [[ ${DESKTOP_RUNNING} -eq 1 ]]; then
  echo "6) Verificando nodo desktop (GUI + VNC)"
  kexec desktop "ping -c 2 192.168.0.2"
  kexec desktop "ping -c 2 192.168.0.3"

  if kexec desktop "bash -lc 'exec 3<>/dev/tcp/127.0.0.1/5901'" >/dev/null 2>&1; then
    echo "OK: VNC escuchando en desktop:5901"
  else
    echo "ERROR: VNC no esta escuchando en desktop:5901" >&2
    exit 1
  fi

  if kexec desktop "bash -lc 'command -v qterminal >/dev/null && command -v firefox-esr >/dev/null && command -v featherpad >/dev/null && command -v wireshark >/dev/null'"; then
    echo "OK: aplicaciones GUI requeridas instaladas"
  else
    echo "ERROR: faltan aplicaciones GUI requeridas en desktop" >&2
    exit 1
  fi
  echo ""
else
  echo "6) Nodo desktop no activo (modo CLI-only)"
  echo ""
fi

if [[ ${VPN_RUNNING} -eq 1 ]]; then
  VPN_CONTAINER_ID="$(get_vpn_container_id | tr -d '[:space:]')"
  if [[ -z "${VPN_CONTAINER_ID}" ]]; then
    echo "ERROR: no se pudo obtener el contenedor Docker del nodo vpn" >&2
    exit 1
  fi

  PORT_BINDING_COUNT="$(docker inspect "${VPN_CONTAINER_ID}" --format "{{with index .NetworkSettings.Ports \"${WG_PORT}/udp\"}}{{len .}}{{else}}0{{end}}" 2>/dev/null || echo 0)"
  PORT_BINDING_COUNT="${PORT_BINDING_COUNT//[[:space:]]/}"

  PROXY_RUNNING=0
  if docker inspect "${PROXY_NAME}" >/dev/null 2>&1; then
    if [[ "$(docker inspect "${PROXY_NAME}" --format '{{.State.Running}}')" == "true" ]]; then
      PROXY_RUNNING=1
    fi
  fi

  echo "7) Verificando WireGuard"
  echo "Contenedor vpn: ${VPN_CONTAINER_ID}"
  echo "Publicacion Docker ${WG_PORT}/udp: ${PORT_BINDING_COUNT} entrada(s)"
  if [[ ${PROXY_RUNNING} -eq 1 ]]; then
    echo "Proxy UDP local: activo (${PROXY_NAME})"
  else
    echo "Proxy UDP local: no activo"
  fi

  kexec vpn "ip -brief a show wg0"
  WG_STATUS="$(kexec vpn "wg show")"
  echo "${WG_STATUS}"

  echo "Esperando handshake WireGuard (max ${WAIT_HANDSHAKE}s)"
  if ! has_handshake "${WG_STATUS}"; then
    for ((i = 0; i < WAIT_HANDSHAKE; i++)); do
      sleep 1
      WG_STATUS="$(kexec vpn "wg show")"
      if has_handshake "${WG_STATUS}"; then
        break
      fi
    done
  fi

  if has_handshake "${WG_STATUS}"; then
    echo "OK: handshake detectado"
  else
    echo "ERROR: no hay handshake WireGuard detectado" >&2
    if [[ "${PORT_BINDING_COUNT}" == "0" && ${PROXY_RUNNING} -eq 0 ]]; then
      echo "Sugerencia: ejecuta ./start-lab.sh para activar proxy UDP automatico" >&2
    fi
    exit 1
  fi

  CLIENT_CONF="$(get_client_conf_path)"
  if [[ -n "${CLIENT_CONF}" && -f "${CLIENT_CONF}" ]]; then
    echo "OK: fichero cliente ${CLIENT_CONF}"
    CLIENT_ENDPOINT="$(sed -n 's/^Endpoint = //p' "${CLIENT_CONF}" | head -n 1)"
    if [[ -n "${CLIENT_ENDPOINT}" ]]; then
      echo "Endpoint cliente: ${CLIENT_ENDPOINT}"
    fi
  else
    echo "ERROR: no se encontro fichero cliente WireGuard en ./shared/vpn" >&2
    exit 1
  fi

  if [[ ${SKIP_HOST_PING} -eq 0 ]]; then
    echo "Verificando conectividad host -> LAN via VPN"
    ping -c 2 192.168.0.2
    if [[ ${DESKTOP_RUNNING} -eq 1 ]]; then
      ping -c 2 192.168.0.5
    else
      ping -c 2 192.168.0.3
    fi
  else
    echo "Ping host -> LAN omitido (--skip-host-ping)"
  fi
  echo ""
else
  echo "7) Nodo vpn no activo (modo CLI-only)"
  echo ""
fi

if [[ ${VERBOSE} -eq 1 ]]; then
  echo "8) Diagnostico adicional"
  kathara linfo -d "${LAB_DIR}"
  if [[ ${VPN_RUNNING} -eq 1 ]]; then
    echo "docker inspect ports (vpn):"
    docker inspect "${VPN_CONTAINER_ID}" --format '{{json .NetworkSettings.Ports}}'
    if docker inspect "${PROXY_NAME}" >/dev/null 2>&1; then
      echo "docker inspect ports (proxy):"
      docker inspect "${PROXY_NAME}" --format '{{json .NetworkSettings.Ports}}'
    fi
  fi
  echo ""
fi

echo "=== Verificacion completada: OK ==="
