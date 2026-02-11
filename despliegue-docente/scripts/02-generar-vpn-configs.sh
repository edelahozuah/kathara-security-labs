#!/bin/bash
#
# Script 02: Generar Configs VPN
# Genera configuraciones WireGuard individuales para cada estudiante
# Las configs se protegen con contraseña ZIP
#

set -e

# Cargar configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/grupos.conf"

# Función de uso
usage() {
    echo "Uso: $0 <archivo-lista-estudiantes> <grupo>"
    echo ""
    echo "Parámetros:"
    echo "  archivo-lista-estudiantes   Archivo con emails (uno por línea)"
    echo "  grupo                       Nombre del grupo (ej: grupo01)"
    echo ""
    echo "Ejemplo:"
    echo "  $0 ../listas/grupo01-estudiantes.txt grupo01"
    echo ""
    echo "Salida:"
    echo "  - grupos/grupo01/configs/        (configs individuales)"
    echo "  - grupos/grupo01/configs.zip     (protegido con contraseña)"
    echo "  - grupos/grupo01/_maestro.txt    (resumen de asignaciones)"
    exit 0
}

# Verificar argumentos
if [[ $# -lt 2 ]]; then
    usage
fi

ARCHIVO_LISTA="$1"
GRUPO="$2"

# Validar archivo de lista
if [[ ! -f "$ARCHIVO_LISTA" ]]; then
    echo "ERROR: No se encuentra el archivo de lista: $ARCHIVO_LISTA"
    exit 1
fi

# Validar grupo
DIR_GRUPO="${DIR_GRUPOS}/${GRUPO}"
if [[ ! -d "$DIR_GRUPO" ]]; then
    echo "ERROR: No existe el grupo: $GRUPO"
    echo "Ejecuta primero: ./01-generar-estructura-grupos.sh"
    exit 1
fi

# Extraer número de grupo
NUM_GRUPO=$(echo "$GRUPO" | grep -o '[0-9]*$' | sed 's/^0*//')
if [[ -z "$NUM_GRUPO" ]]; then
    echo "ERROR: Formato de grupo inválido. Usa: grupo01, grupo02, etc."
    exit 1
fi

# Calcular parámetros del grupo
PUERTO_VPN=$((BASE_PORT_VPN + NUM_GRUPO - 1))
IP_WG_BASE="${BASE_IP_WG}.${NUM_GRUPO}"

echo "=========================================="
echo "Generando Configs VPN"
echo "=========================================="
echo ""
echo "Grupo: ${GRUPO}"
echo "Puerto VPN: ${PUERTO_VPN}"
echo "Rango WireGuard: ${IP_WG_BASE}.0/24"
echo "Archivo lista: ${ARCHIVO_LISTA}"
echo ""

# Contar estudiantes
NUM_ESTUDIANTES=$(wc -l < "$ARCHIVO_LISTA")
echo "Número de estudiantes: ${NUM_ESTUDIANTES}"
echo ""

# Directorio de salida
DIR_CONFIGS="${DIR_GRUPO}/configs"
mkdir -p "$DIR_CONFIGS"

# Limpiar configs anteriores
rm -f "${DIR_CONFIGS}"/*.conf
rm -f "${DIR_CONFIGS}"/_maestro.txt

# Archivo maestro
ARCHIVO_MAESTRO="${DIR_CONFIGS}/_maestro.txt"

# Cabecera del archivo maestro
cat > "$ARCHIVO_MAESTRO" << EOF
# ============================================
# RESUMEN DE ASIGNACIONES VPN
# Grupo: ${GRUPO}
# Fecha: $(date '+%Y-%m-%d %H:%M:%S')
# Puerto VPN: ${PUERTO_VPN}
# ============================================
#
# Formato: EMAIL | IP_WIREGUARD | CLAVE_PUBLICA
#
EOF

# Generar claves del servidor (una sola vez por grupo)
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

# Guardar claves del servidor
echo "$SERVER_PRIVATE_KEY" > "${DIR_CONFIGS}/.server-private.key"
echo "$SERVER_PUBLIC_KEY" > "${DIR_CONFIGS}/.server-public.key"

# Leer lista de estudiantes y generar configs
IP_COUNTER=2  # Empezar en .2 (.1 es el servidor)

while IFS= read -r EMAIL || [[ -n "$EMAIL" ]]; do
    # Limpiar email (quitar espacios)
    EMAIL=$(echo "$EMAIL" | tr -d '[:space:]')
    
    # Saltar líneas vacías o comentarios
    [[ -z "$EMAIL" || "$EMAIL" =~ ^# ]] && continue
    
    # Validar formato de email
    if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "AVISO: Email inválido, saltando: $EMAIL"
        continue
    fi
    
    echo -n "Generando config para ${EMAIL}... "
    
    # Generar IP del cliente
    IP_CLIENTE="${IP_WG_BASE}.${IP_COUNTER}"
    
    # Generar par de claves para el cliente
    CLIENT_PRIVATE_KEY=$(wg genkey)
    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
    
    # Nombre del archivo (reemplazar @ y . por _ para evitar problemas)
    NOMBRE_ARCHIVO=$(echo "$EMAIL" | tr '@.' '__')
    ARCHIVO_CONFIG="${DIR_CONFIGS}/${NOMBRE_ARCHIVO}.conf"
    
    # Crear archivo de configuración
    cat > "$ARCHIVO_CONFIG" << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${IP_CLIENTE}/32
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = SERVIDOR_UAH:${PUERTO_VPN}
AllowedIPs = ${BASE_IP_LAN}.${NUM_GRUPO}.0/24, ${IP_WG_BASE}.0/24
PersistentKeepalive = 25
EOF
    
    # Añadir al archivo maestro
    echo "${EMAIL} | ${IP_CLIENTE} | ${CLIENT_PUBLIC_KEY}" >> "$ARCHIVO_MAESTRO"
    
    echo "OK (${IP_CLIENTE})"
    
    # Incrementar contador de IP
    IP_COUNTER=$((IP_COUNTER + 1))
    
    # Verificar límite de IPs (254 máximo)
    if [[ $IP_COUNTER -gt 254 ]]; then
        echo "ERROR: Límite de IPs alcanzado (254 máximo por grupo)"
        exit 1
    fi
done < "$ARCHIVO_LISTA"

echo ""
echo "Configs generadas en: ${DIR_CONFIGS}/"
echo ""

# Proteger con contraseña ZIP
echo "=========================================="
echo "Protegiendo configs con contraseña"
echo "=========================================="
echo ""
echo "Se creará un archivo ZIP encriptado con todas las configs."
echo "Se te pedirá que introduzcas una contraseña."
echo ""

ARCHIVO_ZIP="${DIR_GRUPO}/configs-${GRUPO}.zip"

# Crear ZIP con contraseña
if command -v zip &> /dev/null; then
    cd "$DIR_CONFIGS"
    zip -e -r "$ARCHIVO_ZIP" . -x "*.key" "_maestro.txt"
    cd - > /dev/null
    
    echo ""
    echo "=========================================="
    echo "Configs protegidas correctamente"
    echo "=========================================="
    echo ""
    echo "Archivo: ${ARCHIVO_ZIP}"
    echo ""
    echo "IMPORTANTE:"
    echo "- Guarda la contraseña de forma segura"
    echo "- Distribuye el ZIP a los estudiantes"
    echo "- Cada estudiante debe buscar su config por email"
    echo ""
else
    echo "AVISO: Comando 'zip' no encontrado."
    echo "Configs sin proteger en: ${DIR_CONFIGS}/"
    echo "Instala zip: sudo apt-get install zip"
fi

echo "Resumen guardado en: ${ARCHIVO_MAESTRO}"
echo ""
echo "Comandos útiles:"
echo "  ./03-iniciar-grupo.sh ${GRUPO}"
echo "  ./05-estado-grupos.sh"
echo ""
