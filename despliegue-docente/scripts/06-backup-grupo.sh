#!/bin/bash
#
# Script 06: Backup de Grupo
# Crea un snapshot completo del estado de un grupo
#

set -e

# Cargar configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/grupos.conf"

# Función de uso
usage() {
    echo "Uso: $0 <grupo> [nombre-backup]"
    echo ""
    echo "Parámetros:"
    echo "  grupo            Nombre del grupo (ej: grupo01)"
    echo "  nombre-backup    Nombre descriptivo (opcional, default: fecha-hora)"
    echo ""
    echo "Ejemplo:"
    echo "  $0 grupo01"
    echo "  $0 grupo01 sesion-martes"
    exit 0
}

# Verificar argumentos
if [[ $# -lt 1 ]]; then
    usage
fi

GRUPO="$1"
NOMBRE_BACKUP="${2:-$(date +%Y%m%d-%H%M%S)}"

# Validar grupo
DIR_GRUPO="${DIR_GRUPOS}/${GRUPO}"
if [[ ! -d "$DIR_GRUPO" ]]; then
    echo "ERROR: No existe el grupo: $GRUPO"
    exit 1
fi

# Buscar directorio del escenario
DIR_ESCENARIO=$(find "$DIR_GRUPO" -name "lab.conf" -type f | head -1 | xargs dirname)

if [[ -z "$DIR_ESCENARIO" ]]; then
    echo "ERROR: No se encuentra lab.conf en el grupo"
    exit 1
fi

# Crear directorio de backups
DIR_BACKUP="${DIR_GRUPO}/backups/${NOMBRE_BACKUP}"
mkdir -p "$DIR_BACKUP"

echo "=========================================="
echo "Backup del Grupo ${GRUPO}"
echo "=========================================="
echo ""
echo "Nombre: ${NOMBRE_BACKUP}"
echo "Destino: ${DIR_BACKUP}"
echo ""

# Guardar información del estado
echo "Guardando información del estado..."
{
    echo "Backup creado: $(date)"
    echo "Grupo: ${GRUPO}"
    echo ""
    echo "Información de contenedores:"
    kathara linfo -d "$DIR_ESCENARIO" 2>/dev/null || echo "No se pudo obtener info"
} > "${DIR_BACKUP}/info.txt"

# Guardar configuraciones actuales
echo "Guardando configuraciones..."
cp -r "${DIR_ESCENARIO}/lab.conf" "$DIR_BACKUP/" 2>/dev/null || true
cp -r "${DIR_ESCENARIO}"/*.startup "$DIR_BACKUP/" 2>/dev/null || true

# Guardar datos de /shared
echo "Guardando datos de shared/..."
if [[ -d "${DIR_ESCENARIO}/shared" ]]; then
    cp -r "${DIR_ESCENARIO}/shared" "${DIR_BACKUP}/" 2>/dev/null || true
fi

# Crear archivo de metadatos
cat > "${DIR_BACKUP}/metadata.txt" << EOF
GRUPO=${GRUPO}
FECHA=$(date -Iseconds)
NOMBRE=${NOMBRE_BACKUP}
ESCENARIO=${DIR_ESCENARIO}
ESTADO=$(kathara linfo -d "$DIR_ESCENARIO" 2>/dev/null | grep -c "Running" || echo "0") contenedores activos
EOF

# Comprimir backup
ARCHIVO_TAR="${DIR_GRUPO}/backups/${GRUPO}-${NOMBRE_BACKUP}.tar.gz"
echo "Comprimiendo backup..."
tar -czf "$ARCHIVO_TAR" -C "${DIR_GRUPO}/backups" "$NOMBRE_BACKUP"

# Limpiar directorio temporal
rm -rf "$DIR_BACKUP"

echo ""
echo "=========================================="
echo "Backup completado"
echo "=========================================="
echo ""
echo "Archivo: ${ARCHIVO_TAR}"
echo "Tamaño: $(du -h "$ARCHIVO_TAR" | cut -f1)"
echo ""
echo "Para restaurar:"
echo "  ./07-restore-grupo.sh ${GRUPO} ${NOMBRE_BACKUP}"
echo ""
echo "Listar backups:"
echo "  ls -lh ${DIR_GRUPO}/backups/"
echo ""
