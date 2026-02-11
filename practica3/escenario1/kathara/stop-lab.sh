#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

echo "Deteniendo laboratorio Practica3..."

# Stop Kathara lab
kathara lclean -d "$SCRIPT_DIR" 2>/dev/null || true

# Stop UDP proxy if running
if docker ps --format "table {{.Names}}" | grep -q "^wg-proxy$"; then
    echo "  Deteniendo proxy UDP..."
    docker stop wg-proxy &>/dev/null || true
    docker rm wg-proxy &>/dev/null || true
fi

echo "Laboratorio detenido."
