#!/bin/bash
# 00-instalar-dependencias.sh
# Script de instalación de dependencias para despliegue docente
# Instala: Docker, Kathará, WireGuard, TigerVNC, openssh-server, utilidades

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de utilidad
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si se ejecuta como root
if [[ $EUID -eq 0 ]]; then
   print_error "No ejecutar este script como root. Se pedirá sudo cuando sea necesario."
   exit 1
fi

# Verificar sistema operativo
print_status "Verificando sistema operativo..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VERSION=$VERSION_ID
else
    print_error "No se puede determinar el sistema operativo"
    exit 1
fi

print_success "Sistema detectado: $OS $VERSION"

# ============================================
# 1. ACTUALIZAR SISTEMA
# ============================================
print_status "Actualizando lista de paquetes..."
sudo apt-get update

# ============================================
# 2. INSTALAR DEPENDENCIAS BÁSICAS
# ============================================
print_status "Instalando dependencias básicas..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    tree \
    jq \
    zip \
    unzip \
    net-tools \
    iputils-ping \
    dnsutils \
    tcpdump \
    nmap \
    iperf3 \
    bc \
    pwgen \
    qrencode \
    figlet \
    toilet \
    lolcat 2>/dev/null || true

print_success "Dependencias básicas instaladas"

# ============================================
# 3. INSTALAR DOCKER
# ============================================
print_status "Instalando Docker..."

if command -v docker &> /dev/null; then
    print_warning "Docker ya está instalado"
    docker --version
else
    # Instalar Docker según documentación oficial
    sudo apt-get install -y \
        ca-certificates \
        gnupg \
        lsb-release
    
    # Agregar clave GPG de Docker
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Configurar repositorio
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Agregar usuario al grupo docker
    sudo usermod -aG docker $USER
    
    print_success "Docker instalado correctamente"
    print_warning "Debes cerrar sesión y volver a iniciar para usar Docker sin sudo"
fi

# ============================================
# 4. INSTALAR KATHARÁ
# ============================================
print_status "Instalando Kathará..."

if command -v kathara &> /dev/null; then
    print_warning "Kathará ya está instalado"
    kathara --version
else
    # Instalar Kathará
    curl -fsSL https://raw.githubusercontent.com/KatharaFramework/Kathara/master/scripts/InstallLinux.sh | sudo bash
    
    print_success "Kathará instalado correctamente"
fi

# Verificar versión de Kathará
print_status "Verificando Kathará..."
kathara --version || print_warning "Reinicia la sesión para usar Kathará"

# ============================================
# 5. INSTALAR WIREGUARD
# ============================================
print_status "Instalando WireGuard..."

if command -v wg &> /dev/null && command -v wg-quick &> /dev/null; then
    print_warning "WireGuard ya está instalado"
    wg --version
else
    sudo apt-get install -y wireguard wireguard-tools
    
    print_success "WireGuard instalado correctamente"
fi

# ============================================
# 6. INSTALAR SERVIDOR VNC
# ============================================
print_status "Instalando servidor VNC..."

if command -v Xtigervnc &> /dev/null; then
    print_warning "TigerVNC ya está instalado"
else
    sudo apt-get install -y tigervnc-standalone-server tigervnc-viewer
    
    print_success "TigerVNC instalado correctamente"
fi

# ============================================
# 7. INSTALAR SERVIDOR SSH
# ============================================
print_status "Configurando servidor SSH..."

if systemctl is-active --quiet ssh; then
    print_warning "Servidor SSH ya está instalado y activo"
else
    sudo apt-get install -y openssh-server
    sudo systemctl enable ssh
    sudo systemctl start ssh
    
    print_success "Servidor SSH instalado y activado"
fi

# Configurar SSH para permitir múltiples puertos (si no está configurado)
if ! grep -q "^Port 22" /etc/ssh/sshd_config 2>/dev/null; then
    print_status "Configurando SSH en puerto 22..."
    sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
    sudo systemctl restart ssh
fi

# ============================================
# 8. INSTALAR UTILIDADES ADICIONALES
# ============================================
print_status "Instalando utilidades adicionales..."

# Herramientas de red
sudo apt-get install -y \
    bridge-utils \
    vlan \
    iptables-persistent \
    conntrack

# Herramientas de monitoreo
sudo apt-get install -y \
    sysstat \
    iftop \
    nethogs

print_success "Utilidades adicionales instaladas"

# ============================================
# 9. CONFIGURAR IPTABLES
# ============================================
print_status "Configurando iptables..."

# Habilitar IP forwarding
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    print_success "IP forwarding habilitado"
fi

# Configurar reglas básicas de iptables para NAT
if ! sudo iptables -t nat -L | grep -q "MASQUERADE"; then
    print_status "Configurando NAT..."
    # Estas reglas se aplicarán dinámicamente por los scripts de gestión
    print_warning "Las reglas de NAT se configurarán dinámicamente por los scripts"
fi

# ============================================
# 10. CREAR ESTRUCTURA DE DIRECTORIOS
# ============================================
print_status "Creando estructura de directorios..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

mkdir -p "$BASE_DIR"/config
mkdir -p "$BASE_DIR"/grupos
mkdir -p "$BASE_DIR"/listas
mkdir -p "$BASE_DIR"/docs
mkdir -p "$BASE_DIR"/vpn-configs

print_success "Estructura de directorios creada"

# ============================================
# 11. VERIFICAR INSTALACIÓN
# ============================================
print_status "Verificando instalación..."

echo ""
echo "========================================"
echo "   RESUMEN DE INSTALACIÓN"
echo "========================================"
echo ""

# Verificar cada componente
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $2: $($1 --version 2>/dev/null | head -n1 || echo 'instalado')"
    else
        echo -e "${RED}✗${NC} $2: No instalado"
    fi
}

check_command docker "Docker"
check_command kathara "Kathará"
check_command wg "WireGuard"
check_command Xtigervnc "TigerVNC"
check_command ssh "SSH Server"
check_command zip "ZIP"
check_command qrencode "QR Encode"

echo ""
echo "========================================"

# ============================================
# 12. MENSAJE FINAL
# ============================================
echo ""
print_success "Instalación completada!"
echo ""
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo "1. Cierra sesión y vuelve a iniciar para aplicar los cambios de grupo Docker"
echo "2. Verifica que Docker funciona sin sudo: docker run hello-world"
echo "3. Revisa la documentación en: $BASE_DIR/docs/"
echo ""
echo -e "${BLUE}Siguiente paso:${NC} Ejecuta el script 01 para generar la estructura de grupos"
echo "   ./scripts/01-generar-estructura-grupos.sh <numero_de_grupos>"
echo ""
