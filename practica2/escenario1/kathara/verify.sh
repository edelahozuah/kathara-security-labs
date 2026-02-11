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
  --skip-host-ping          Omite ping desde host a maquinas del laboratorio
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

if ! kathara exec -d "${LAB_DIR}" --wait vpn "true" >/dev/null 2>&1; then
  echo "ERROR: el nodo vpn no esta en ejecucion. Arranca primero con ./start-lab.sh" >&2
  exit 1
fi

PLATFORM="$(detect_platform)"
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

echo "=== Verificacion escenario Kathara ==="
echo "Plataforma: ${PLATFORM}"
echo "Contenedor vpn: ${VPN_CONTAINER_ID}"
echo "Publicacion Docker ${WG_PORT}/udp: ${PORT_BINDING_COUNT} entrada(s)"
if [[ ${PROXY_RUNNING} -eq 1 ]]; then
  echo "Proxy UDP local: activo (${PROXY_NAME})"
else
  echo "Proxy UDP local: no activo"
fi
echo ""

echo "1) Verificando IP forwarding en routers"
echo "r1:"
kexec r1 "cat /proc/sys/net/ipv4/ip_forward"
echo "r2:"
kexec r2 "cat /proc/sys/net/ipv4/ip_forward"
echo ""

echo "2) Tablas de enrutamiento"
echo "r1:"
kexec r1 "ip route"
echo ""
echo "r2:"
kexec r2 "ip route"
echo ""

echo "3) Conectividad interna del laboratorio"
echo "h1 -> h3"
kexec h1 "ping -c 3 10.1.2.2"
echo ""
echo "h3 -> h1"
kexec h3 "ping -c 3 10.1.0.2"
echo ""

echo "4) Estado WireGuard en vpn"
kexec vpn "ip -brief a show wg0"
WG_STATUS="$(kexec vpn "wg show")"
echo "${WG_STATUS}"
echo ""

echo "5) Esperando handshake WireGuard (max ${WAIT_HANDSHAKE}s)"
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
echo ""

echo "6) Verificando fichero cliente generado"
CLIENT_CONF="$(get_client_conf_path)"
if [[ -n "${CLIENT_CONF}" && -f "${CLIENT_CONF}" ]]; then
  echo "OK: ${CLIENT_CONF}"
  CLIENT_ENDPOINT="$(sed -n 's/^Endpoint = //p' "${CLIENT_CONF}" | head -n 1)"
  if [[ -n "${CLIENT_ENDPOINT}" ]]; then
    echo "Endpoint cliente: ${CLIENT_ENDPOINT}"
  else
    echo "WARN: no se encontro linea Endpoint en ${CLIENT_CONF}" >&2
  fi
else
  echo "ERROR: no se encontro fichero de cliente WireGuard en ./shared/vpn" >&2
  exit 1
fi
echo ""

if [[ ${SKIP_HOST_PING} -eq 0 ]]; then
  echo "7) Verificando conectividad host -> laboratorio via VPN"
  ping -c 2 10.1.0.2
  ping -c 2 10.1.2.2
  echo ""
else
  echo "7) Ping host -> laboratorio omitido (--skip-host-ping)"
  echo ""
fi

if [[ ${VERBOSE} -eq 1 ]]; then
  echo "8) Diagnostico adicional"
  echo "docker inspect ports (vpn):"
  docker inspect "${VPN_CONTAINER_ID}" --format '{{json .NetworkSettings.Ports}}'
  if [[ ${PROXY_RUNNING} -eq 1 ]]; then
    echo "docker inspect ports (proxy):"
    docker inspect "${PROXY_NAME}" --format '{{json .NetworkSettings.Ports}}'
  fi
  echo ""
fi

echo "=== Verificacion completada: OK ==="
