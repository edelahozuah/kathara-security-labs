#!/bin/bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_NAME="${WG_PROXY_NAME:-wg-proxy}"
PROXY_PORT="${WG_PROXY_PORT:-55182}"
WG_PORT="${WG_PORT:-51820}"
WAIT_SECONDS="${WAIT_SECONDS:-30}"

FORCE_PROXY=0
NO_PROXY=0
CLI_ONLY=0
ENDPOINT_HOST_OVERRIDE=""

usage() {
  cat <<'EOF'
Uso: ./start-lab.sh [opciones]

Opciones:
  --cli-only              Arranca solo base/router/natgw
  --endpoint-host <host>  Host/IP para Endpoint cliente (por defecto 127.0.0.1)
  --force-proxy           Fuerza proxy UDP local
  --no-proxy              Desactiva proxy UDP local
  --wait-seconds <n>      Segundos maximos para esperar a vpn (por defecto 30)
  -h, --help              Muestra esta ayuda

Variables opcionales:
  WG_PROXY_NAME           Nombre del contenedor proxy (por defecto wg-proxy)
  WG_PROXY_PORT           Puerto UDP del proxy local (por defecto 55182)
  WG_PORT                 Puerto UDP WireGuard interno (por defecto 51820)
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

start_nodes() {
  local node
  local missing=()

  for node in "$@"; do
    if ! is_node_running "${node}"; then
      missing+=("${node}")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Arrancando nodos: ${missing[*]}"
    kathara lstart -d "${LAB_DIR}" "${missing[@]}"
  else
    echo "Nodos requeridos ya estaban arrancados."
  fi
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
    echo "${candidate}"
    return 0
  fi

  for candidate in "${LAB_DIR}"/shared/vpn/*.conf; do
    if [[ -f "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done

  echo ""
}

wait_for_vpn() {
  local i

  for ((i = 0; i < WAIT_SECONDS; i++)); do
    if kathara exec -d "${LAB_DIR}" --wait vpn "true" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  return 1
}

wait_for_client_conf() {
  local client_conf="$1"
  local i

  for ((i = 0; i < WAIT_SECONDS; i++)); do
    if [[ -f "${client_conf}" ]]; then
      return 0
    fi
    sleep 1
  done

  return 1
}

update_client_endpoint() {
  local client_conf="$1"
  local endpoint="$2"

  if grep -q '^Endpoint = ' "${client_conf}"; then
    sed -i.bak -E "s|^Endpoint = .*|Endpoint = ${endpoint}|" "${client_conf}"
    rm -f "${client_conf}.bak"
    return 0
  fi

  echo "WARN: no se encontro linea Endpoint en ${client_conf}; no se actualiza." >&2
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cli-only)
      CLI_ONLY=1
      ;;
    --endpoint-host)
      shift
      if [[ $# -eq 0 ]]; then
        echo "ERROR: falta valor para --endpoint-host" >&2
        exit 1
      fi
      ENDPOINT_HOST_OVERRIDE="$1"
      ;;
    --force-proxy)
      FORCE_PROXY=1
      ;;
    --no-proxy)
      NO_PROXY=1
      ;;
    --wait-seconds)
      shift
      if [[ $# -eq 0 ]]; then
        echo "ERROR: falta valor para --wait-seconds" >&2
        exit 1
      fi
      WAIT_SECONDS="$1"
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

if [[ ! "${WAIT_SECONDS}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --wait-seconds debe ser un entero >= 0" >&2
  exit 1
fi

if [[ ${FORCE_PROXY} -eq 1 && ${NO_PROXY} -eq 1 ]]; then
  echo "ERROR: --force-proxy y --no-proxy son excluyentes" >&2
  exit 1
fi

if [[ ! -f "${LAB_DIR}/lab.conf" ]]; then
  echo "ERROR: no se encontro lab.conf en ${LAB_DIR}" >&2
  exit 1
fi

if ! command -v kathara >/dev/null 2>&1; then
  echo "ERROR: kathara no esta instalado o no esta en PATH" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker no esta disponible o no esta en ejecucion" >&2
  exit 1
fi

mkdir -p "${LAB_DIR}/shared/vpn"

echo "== Inicio plantilla escenario Kathara (cross-platform) =="
PLATFORM="$(detect_platform)"
echo "Plataforma detectada: ${PLATFORM}"

echo "Verificando imagenes Docker de plantilla..."
if ! docker image inspect kathara-vpn >/dev/null 2>&1; then
  echo "- Construyendo kathara-vpn"
  docker build -t kathara-vpn -f "${LAB_DIR}/Dockerfile.vpn" "${LAB_DIR}"
else
  echo "- kathara-vpn ya existe"
fi

if ! docker image inspect kathara-desktop >/dev/null 2>&1; then
  echo "- Construyendo kathara-desktop"
  docker build -t kathara-desktop -f "${LAB_DIR}/Dockerfile.desktop" "${LAB_DIR}"
else
  echo "- kathara-desktop ya existe"
fi

if [[ ${CLI_ONLY} -eq 1 ]]; then
  docker rm -f "${PROXY_NAME}" >/dev/null 2>&1 || true

  if is_node_running vpn || is_node_running desktop; then
    echo "Modo CLI-only solicitado; reiniciando escenario sin vpn/desktop..."
    kathara lclean -d "${LAB_DIR}" >/dev/null 2>&1 || true
  fi

  start_nodes base router natgw

  echo ""
  echo "=== Escenario listo (modo CLI-only) ==="
  echo "Nodos activos: base router natgw"
  echo "Sin WireGuard ni desktop VNC en este modo."
  echo ""
  echo "Siguientes pasos:"
  echo "1) Verifica con: ./verify.sh"
  echo "2) Para modo completo (VPN+GUI): ./start-lab.sh"
  exit 0
fi

start_nodes base router natgw vpn desktop

if ! wait_for_vpn; then
  echo "ERROR: el nodo vpn no esta listo tras ${WAIT_SECONDS}s" >&2
  exit 1
fi

VPN_CONTAINER_ID="$(get_vpn_container_id | tr -d '[:space:]')"
if [[ -z "${VPN_CONTAINER_ID}" ]]; then
  echo "ERROR: no se pudo obtener el contenedor de vpn" >&2
  exit 1
fi

PORT_BINDING_COUNT="$(docker inspect "${VPN_CONTAINER_ID}" --format "{{with index .NetworkSettings.Ports \"${WG_PORT}/udp\"}}{{len .}}{{else}}0{{end}}" 2>/dev/null || echo 0)"
PORT_BINDING_COUNT="${PORT_BINDING_COUNT//[[:space:]]/}"

USE_PROXY=0
if [[ ${NO_PROXY} -eq 1 ]]; then
  USE_PROXY=0
elif [[ ${FORCE_PROXY} -eq 1 ]]; then
  USE_PROXY=1
elif [[ "${PORT_BINDING_COUNT}" == "0" ]]; then
  USE_PROXY=1
fi

docker rm -f "${PROXY_NAME}" >/dev/null 2>&1 || true

ENDPOINT_HOST="${ENDPOINT_HOST_OVERRIDE:-127.0.0.1}"
ENDPOINT_PORT="${WG_PORT}"
MODE_LABEL="directo"

if [[ ${USE_PROXY} -eq 1 ]]; then
  VPN_BRIDGE_IP="$(docker inspect "${VPN_CONTAINER_ID}" --format '{{with index .NetworkSettings.Networks "bridge"}}{{.IPAddress}}{{end}}' 2>/dev/null || true)"

  if [[ -z "${VPN_BRIDGE_IP}" ]]; then
    echo "ERROR: no se pudo obtener IP bridge del contenedor vpn" >&2
    exit 1
  fi

  echo "No hay publicacion UDP util en ${WG_PORT}/udp; creando proxy local ${PROXY_PORT}/udp..."
  docker run -d --name "${PROXY_NAME}" --restart unless-stopped \
    -p "${PROXY_PORT}:${PROXY_PORT}/udp" --network bridge \
    alpine/socat -T30 "UDP-LISTEN:${PROXY_PORT},fork,reuseaddr" "UDP:${VPN_BRIDGE_IP}:${WG_PORT}" >/dev/null

  ENDPOINT_PORT="${PROXY_PORT}"
  MODE_LABEL="proxy"
fi

CLIENT_CONF="$(get_client_conf_path)"
if [[ -z "${CLIENT_CONF}" ]]; then
  echo "ERROR: no se pudo resolver el fichero de cliente WireGuard" >&2
  exit 1
fi

if ! wait_for_client_conf "${CLIENT_CONF}"; then
  echo "ERROR: no se genero el fichero de cliente ${CLIENT_CONF}" >&2
  exit 1
fi

FINAL_ENDPOINT="${ENDPOINT_HOST}:${ENDPOINT_PORT}"
update_client_endpoint "${CLIENT_CONF}" "${FINAL_ENDPOINT}" >/dev/null || true

echo ""
echo "=== Escenario listo (modo completo) ==="
echo "Modo de conectividad UDP: ${MODE_LABEL}"
echo "Contenedor vpn: ${VPN_CONTAINER_ID}"
echo "Config cliente: ${CLIENT_CONF}"
echo "Endpoint aplicado: ${FINAL_ENDPOINT}"
echo "Base node: 192.168.0.2"
echo "VNC desktop: 192.168.0.5:5901"
echo ""
echo "Siguientes pasos:"
echo "1) Importa ${CLIENT_CONF} en WireGuard"
echo "2) Activa el tunel"
echo "3) Conecta por VNC a 192.168.0.5:5901 (password: password)"
echo "4) Verifica con: ./verify.sh --wait-for-handshake 30"
