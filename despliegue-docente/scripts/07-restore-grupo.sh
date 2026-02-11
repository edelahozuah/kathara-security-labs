#!/bin/bash
#
# Script 07: Restore de Grupo
# Restaura un grupo desde un backup
#

set -e

# Cargar configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/grupos.conf"

# Función de uso
usage() {
    echo "Uso: $0 <grupo> <nombre-backup>"
    echo ""
    echo "Parámetros:"
    echo "  grupo            Nombre del grupo (ej: grupo01)"
    echo "  nombre-backup    Nombre del backup a restaurar"
    echo ""
    echo "Ejemplo:"
    echo "  $0 grupo01 20240211-143000"
    echo "  $0 grupo01 sesion-martes"
    echo ""
    echo "Listar backups disponibles:"
    echo "  ls -lh grupos/grupo01/backups/"
    exit 0
}

# Verificar argumentos
if [[ $# -lt 2 ]]; then
    usage
fi

GRUPO="$1"
NOMBRE_BACKUP="$2"

# Validar grupo
DIR_GRUPO="${DIR_GRUPOS}/${GRUPO}"
if [[ ! -d "$DIR_GRUPO" ]]; then
    echo "ERROR: No existe el grupo: $GRUPO"
    exit 1
fi

# Buscar archivo de backup
ARCHIVO_TAR="${DIR_GRUPO}/backups/${GRUPO}-${NOMBRE_BACKUP}.tar.gz"

if [[ ! -f "$ARCHIVO_TAR" ]]; then
    # Intentar sin prefijo de grupo
    ARCHIVO_TAR="${DIR_GRUPO}/backups/${NOMBRE_BACKUP}.tar.gz"
    
    if [[ ! -f "$ARCHIVO_TAR" ]]; then
        echo "ERROR: No se encuentra el backup: ${NOMBRE_BACKUP}"
        echo ""
        echo "Backups disponibles:"
        ls -1 "${DIR_GRUPO}/backups/"/*.tar.gz 2>/dev/null | xargs -n1 basename || echo "  (ninguno)"
        exit 1
    fi
fi

echo "=========================================="
echo "Restore del Grupo ${GRUPO}"
echo "=========================================="
echo ""
echo "Backup: ${NOMBRE_BACKUP}"
echo "Archivo: ${ARCHIVO_TAR}"
echo ""

# Verificar si el grupo está corriendo
DIR_ESCENARIO=$(find "$DIR_GRUPO" -name "lab.conf" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)

if [[ -n "$DIR_ESCENARIO" ]]; then
    if kathara linfo -d "$DIR_ESCENARIO" 2>/dev/null | grep -q "Running"; then
        echo "AVISO: El grupo ${GRUPO} está actualmente en ejecución."
        echo "Es necesario detenerlo antes de restaurar."
        echo ""
        read -p "¿Detener grupo ahora? (si/no): " CONFIRMAR
        
        if [[ "$CONFIRMAR" == "si" ]]; then
            "${DIR_SCRIPTS}/04-detener-grupo.sh" "$GRUPO" --forzar
        else
            echo "Operación cancelada"
            exit 0
        fi
    fi
fi

# Crear backup de seguridad del estado actual (si existe)
if [[ -d "$DIR_ESCENARIO" ]]; then
    echo "Creando backup de seguridad del estado actual..."
    BACKUP_SEGURIDAD="pre-restore-$(date +%Y%m%d-%H%M%S)"
    "${DIR_SCRIPTS}/06-backup-grupo.sh" "$GRUPO" "$BACKUP_SEGURIDAD" >/dev/null 2>&1 || true
    echo "Backup de seguridad: ${BACKUP_SEGURIDAD}"
    echo ""
fi

# Descomprimir backup
echo "Descomprimiendo backup..."
DIR_TEMP="${DIR_GRUPO}/.restore-temp"
rm -rf "$DIR_TEMP"
mkdir -p "$DIR_TEMP"

tar -xzf "$ARCHIVO_TAR" -C "$DIR_TEMP"

# Buscar directorio extraído
DIR_BACKUP=$(find "$DIR_TEMP" -maxdepth 1 -type d | tail -1)

if [[ -z "$DIR_BACKUP" ]]; then
    echo "ERROR: No se pudo extraer el backup"
    rm -rf "$DIR_TEMP"
    exit 1
fi

# Restaurar configuraciones
echo "Restaurando configuraciones..."
if [[ -f "${DIR_BACKUP}/lab.conf" ]]; then
    cp "${DIR_BACKUP}/lab.conf" "$DIR_ESCENARIO/"
fi

if ls "${DIR_BACKUP}"/*.startup 1>/dev/null 2>&1; then
    cp "${DIR_BACKUP}"/*.startup "$DIR_ESCENARIO/"
fi

# Restaurar datos de shared
echo "Restaurando datos..."
if [[ -d "${DIR_BACKUP}/shared" ]]; then
    mkdir -p "${DIR_ESCENARIO}/shared"
    cp -r "${DIR_BACKUP}/shared/"* "${DIR_ESCENARIO}/shared/" 2>/dev/null || true
fi

# Limpiar temporal
rm -rf "$DIR_TEMP"

echo ""
echo "=========================================="
echo "Restore completado"
echo "=========================================="
echo ""
echo "El grupo ${GRUPO} ha sido restaurado al estado del backup."
echo ""
echo "Para iniciar el grupo:"
echo "  ./03-iniciar-grupo.sh ${GRUPO}"
echo ""
if [[ -n "$BACKUP_SEGURIDAD" ]]; then
    echo "Nota: Se creó backup de seguridad: ${BACKUP_SEGURIDAD}"
    echo "      Puedes restaurarlo si es necesario."
fi
echo ""
