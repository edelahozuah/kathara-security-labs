#!/bin/bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_NAME="${WG_PROXY_NAME:-wg-proxy}"

echo "== Parada plantilla escenario Kathara =="
echo "Directorio escenario: ${LAB_DIR}"

if kathara lclean -d "${LAB_DIR}" >/dev/null 2>&1; then
  echo "Escenario detenido con kathara lclean."
else
  echo "WARN: kathara lclean devolvio error (puede que el escenario ya estuviera parado)." >&2
fi

if docker inspect "${PROXY_NAME}" >/dev/null 2>&1; then
  docker rm -f "${PROXY_NAME}" >/dev/null
  echo "Proxy UDP eliminado: ${PROXY_NAME}"
else
  echo "No existe proxy UDP activo (${PROXY_NAME})."
fi

echo "Parada completada."
