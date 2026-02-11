# Guía de Despliegue Docente - Laboratorios Kathará

## Índice
1. [Visión General](#visión-general)
2. [Requisitos del Sistema](#requisitos-del-sistema)
3. [Instalación](#instalación)
4. [Estructura del Sistema](#estructura-del-sistema)
5. [Flujo de Trabajo](#flujo-de-trabajo)
6. [Referencia de Scripts](#referencia-de-scripts)
7. [Configuración SSH](#configuración-ssh)
8. [Solución de Problemas](#solución-de-problemas)
9. [Seguridad](#seguridad)
10. [FAQ](#faq)

---

## Visión General

Este sistema permite a los profesores desplegar escenarios Kathará de ciberseguridad para múltiples grupos de estudiantes simultáneamente, con acceso remoto seguro mediante VPN WireGuard.

### Características Principales

- **Aislamiento**: Cada grupo tiene su propio escenario independiente
- **Acceso remoto**: Conexión VPN segura con WireGuard
- **Monitoreo**: Visualización en tiempo real de estado y recursos
- **Escalabilidad**: Soporta hasta 20 grupos simultáneos
- **Backup/Restore**: Snapshots completos del estado del laboratorio
- **Distribución segura**: Configuraciones VPN en ZIPs protegidos por contraseña

---

## Requisitos del Sistema

### Hardware Mínimo

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPU | 8 cores | 16+ cores |
| RAM | 16 GB | 32+ GB |
| Disco | 100 GB SSD | 200+ GB SSD |
| Red | 1 Gbps | 10 Gbps |

### Sistema Operativo

- **Ubuntu 20.04 LTS** o superior (recomendado)
- **Debian 11** o superior

### Requisitos de Red

- **IP pública** o acceso desde internet (para VPN)
- **Puertos disponibles**:
  - UDP 51820-51839 (WireGuard VPN)
  - TCP 5901-5920 (VNC - opcional)
  - TCP 22001-22020 (SSH directo - opcional)
  - TCP 22 (SSH administración)

---

## Instalación

### Paso 1: Clonar el Repositorio

```bash
cd /opt
git clone https://github.com/tu-usuario/lab-vnx-seguridad.git
cd lab-vnx-seguridad/despliegue-docente
```

### Paso 2: Ejecutar Script de Instalación

```bash
# Hacer ejecutables todos los scripts
chmod +x scripts/*.sh

# Ejecutar instalador de dependencias
./scripts/00-instalar-dependencias.sh
```

Este script instala:
- Docker y Docker Compose
- Kathará Framework
- WireGuard
- TigerVNC Server
- OpenSSH Server
- Utilidades de red y monitoreo

**⚠️ Importante**: Cierra sesión y vuelve a iniciar después de la instalación para aplicar los cambios de grupo Docker.

### Paso 3: Verificar Instalación

```bash
docker run hello-world
kathara --version
wg --version
```

---

## Estructura del Sistema

```
despliegue-docente/
├── config/
│   └── grupos.conf          # Configuración de grupos (IPs, puertos)
├── scripts/
│   ├── 00-instalar-dependencias.sh
│   ├── 01-generar-estructura-grupos.sh
│   ├── 02-generar-vpn-configs.sh
│   ├── 03-iniciar-grupo.sh
│   ├── 04-detener-grupo.sh
│   ├── 05-estado-grupos.sh
│   ├── 06-backup-grupo.sh
│   ├── 07-restore-grupo.sh
│   ├── 08-monitor-grupo.sh
│   └── 09-reset-grupo.sh
├── docs/
│   └── DESPLIEGUE_DOCENTE.md    # Esta documentación
├── grupos/                  # Escenarios de cada grupo (generado)
│   ├── grupo01/
│   ├── grupo02/
│   └── ...
├── listas/                  # Listas de estudiantes (email,nombre)
└── vpn-configs/            # Configuraciones VPN generadas
```

### Configuración de Grupos

Cada grupo tiene asignado:

| Parámetro | Grupo 1 | Grupo 2 | ... | Grupo 20 |
|-----------|---------|---------|-----|----------|
| Puerto VPN | 51820 | 51821 | ... | 51839 |
| Red LAN | 192.168.1.0/24 | 192.168.2.0/24 | ... | 192.168.20.0/24 |
| Red WireGuard | 10.99.1.0/24 | 10.99.2.0/24 | ... | 10.99.20.0/24 |
| Puerto SSH | 22001 | 22002 | ... | 22020 |
| Puerto VNC | 5901 | 5902 | ... | 5920 |

---

## Flujo de Trabajo

### Escenario: Inicio de Práctica

```bash
# 1. Preparar lista de estudiantes
cat > listas/estudiantes-practica1.txt << EOF
juan.perez@uah.es,Juan Pérez
maria.garcia@uah.es,María García
...
EOF

# 2. Generar estructura (si es primera vez)
./scripts/01-generar-estructura-grupos.sh 15

# 3. Generar configuraciones VPN
./scripts/02-generar-vpn-configs.sh listas/estudiantes-practica1.txt

# 4. Distribuir configuraciones a estudiantes
# Los archivos están en: vpn-configs/grupo01.zip, grupo02.zip, etc.

# 5. Iniciar todos los grupos
for i in $(seq -w 1 15); do
    ./scripts/03-iniciar-grupo.sh grupo$i
done

# 6. Monitorear estado
./scripts/05-estado-grupos.sh
```

### Escenario: Durante la Práctica

```bash
# Monitorear un grupo específico
./scripts/08-monitor-grupo.sh grupo05

# Ver estado de todos
./scripts/05-estado-grupos.sh
```

### Escenario: Fin de Práctica

```bash
# Opción A: Detener y guardar estado (para continuar después)
for i in $(seq -w 1 15); do
    ./scripts/04-detener-grupo.sh grupo$i --backup
done

# Opción B: Detener sin backup
./scripts/04-detener-grupo.sh grupo05

# Opción C: Reset completo (borrar todo)
./scripts/09-reset-grupo.sh grupo05
```

### Escenario: Recuperación

```bash
# Listar backups disponibles
ls -la grupos/grupo05/backups/

# Restaurar desde backup
./scripts/07-restore-grupo.sh grupo05 backups/grupo05-20240211-143022.tar.gz
```

---

## Referencia de Scripts

### 00-instalar-dependencias.sh
Instala todas las dependencias necesarias en el servidor.

```bash
./scripts/00-instalar-dependencias.sh
```

**Nota**: Requiere reinicio de sesión después de ejecutar.

---

### 01-generar-estructura-grupos.sh
Genera la estructura de directorios para N grupos.

```bash
./scripts/01-generar-estructura-grupos.sh <num_grupos>

# Ejemplo: Generar estructura para 15 grupos
./scripts/01-generar-estructura-grupos.sh 15
```

**Qué hace**:
- Crea directorios para cada grupo
- Genera `config/grupos.conf` con asignaciones de IPs/puertos
- Copia escenarios base desde directorio de origen
- Genera scripts auxiliares (status, backup, etc.)

---

### 02-generar-vpn-configs.sh
Genera configuraciones WireGuard masivamente desde una lista de emails.

```bash
./scripts/02-generar-vpn-configs.sh <archivo_lista>

# Ejemplo
./scripts/02-generar-vpn-configs.sh listas/estudiantes.txt
```

**Formato del archivo de lista**:
```
email1@uah.es,Nombre Apellido1
email2@uah.es,Otro Estudiante
```

**Salida**:
- `vpn-configs/grupo01/` - Configuración sin comprimir
- `vpn-configs/grupo01.zip` - ZIP protegido con contraseña

**Contraseñas**: Se generan automáticamente y se muestran en pantalla. También se guardan en `vpn-configs/contrasenas.txt`.

---

### 03-iniciar-grupo.sh
Inicia un escenario de grupo con todos sus servicios.

```bash
./scripts/03-iniciar-grupo.sh <grupo_id> [--enable-ssh]

# Ejemplos
./scripts/03-iniciar-grupo.sh grupo05
./scripts/03-iniciar-grupo.sh grupo05 --enable-ssh
```

**Parámetros**:
- `grupo_id`: Identificador del grupo (ej: grupo01)
- `--enable-ssh`: Habilita acceso SSH directo (opcional)

**Qué inicia**:
- Escenario Kathará (máquinas virtuales)
- Interfaz WireGuard para VPN
- Redes Docker aisladas
- Reglas de iptables para NAT

---

### 04-detener-grupo.sh
Detiene un grupo y opcionalmente crea backup.

```bash
./scripts/04-detener-grupo.sh <grupo_id> [--backup]

# Ejemplos
./scripts/04-detener-grupo.sh grupo05           # Solo detener
./scripts/04-detener-grupo.sh grupo05 --backup  # Detener y backup
```

---

### 05-estado-grupos.sh
Muestra tabla de estado de todos los grupos en tiempo real.

```bash
./scripts/05-estado-grupos.sh [--watch]

# Ejemplos
./scripts/05-estado-grupos.sh           # Ver estado una vez
./scripts/05-estado-grupos.sh --watch   # Monitoreo continuo
```

**Columnas mostradas**:
- ID del grupo
- Estado (Activo/Inactivo)
- Clientes VPN conectados
- Uso de CPU
- Uso de RAM
- Disco usado
- Puerto VPN

---

### 06-backup-grupo.sh
Crea snapshot completo de un grupo.

```bash
./scripts/06-backup-grupo.sh <grupo_id> [nombre_backup]

# Ejemplos
./scripts/06-backup-grupo.sh grupo05
./scripts/06-backup-grupo.sh grupo05 antes-cambios-importantes
```

**Qué incluye**:
- Estado de máquinas Kathará
- Archivos de laboratorio
- Configuraciones de red
- Capturas de tráfico (si existen)

---

### 07-restore-grupo.sh
Restaura un grupo desde backup.

```bash
./scripts/07-restore-grupo.sh <grupo_id> <ruta_backup>

# Ejemplo
./scripts/07-restore-grupo.sh grupo05 grupos/grupo05/backups/grupo05-20240211-143022.tar.gz
```

**⚠️ Precaución**: Esto sobrescribirá el estado actual del grupo.

---

### 08-monitor-grupo.sh
Monitoreo en tiempo real de un grupo específico.

```bash
./scripts/08-monitor-grupo.sh <grupo_id> [--logs] [--resources]

# Ejemplos
./scripts/08-monitor-grupo.sh grupo05              # Vista general
./scripts/08-monitor-grupo.sh grupo05 --logs       # Solo logs
./scripts/08-monitor-grupo.sh grupo05 --resources  # Solo recursos
```

---

### 09-reset-grupo.sh
Reset completo de un grupo al estado inicial.

```bash
./scripts/09-reset-grupo.sh <grupo_id> [--force]

# Ejemplos
./scripts/09-reset-grupo.sh grupo05         # Pide confirmación
./scripts/09-reset-grupo.sh grupo05 --force # Sin confirmación
```

**⚠️ Advertencia**: Esto borra TODO el estado del grupo. Considera hacer backup primero.

---

## Configuración SSH

### Acceso SSH Directo (Opcional)

Si habilitaste SSH al iniciar el grupo (`--enable-ssh`), los estudiantes pueden conectar directamente:

```bash
# Desde la máquina del estudiante
ssh -p <puerto_ssh> root@<ip_servidor>

# Ejemplo para grupo05 (puerto 22005)
ssh -p 22005 root@155.54.210.31
```

### Acceso SSH a través de VPN (Recomendado)

```bash
# 1. Conectar VPN WireGuard
wg-quick up ./grupo05.conf

# 2. Conectar por SSH usando IP interna
ssh root@192.168.5.10  # IP del pc1 del grupo5
```

### Configuración SSH del Servidor

El archivo `/etc/ssh/sshd_config` debe incluir:

```
# Puerto principal
Port 22

# Puertos adicionales para grupos (ejemplo)
Port 22001
Port 22002
...
Port 22020

# Configuración de seguridad
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

**Aplicar cambios**:
```bash
sudo systemctl restart sshd
```

---

## Solución de Problemas

### Problema: No se puede iniciar el escenario

**Síntoma**: Error al ejecutar `03-iniciar-grupo.sh`

**Solución**:
```bash
# 1. Verificar que Docker está corriendo
sudo systemctl status docker

# 2. Verificar permisos de usuario
sudo usermod -aG docker $USER
# Cerrar sesión y volver a iniciar

# 3. Verificar puertos en uso
sudo ss -tulnp | grep 5182
sudo ss -tulnp | grep 590

# 4. Limpiar redes Kathará huérfanas
kathara wipe -f
```

---

### Problema: VPN no conecta

**Síntoma**: El cliente WireGuard no establece conexión

**Solución**:
```bash
# 1. Verificar que el puerto está abierto
sudo wg show

# 2. Verificar reglas de firewall
sudo iptables -L -n -v | grep 5182

# 3. Verificar que la interfaz está activa
ip addr show wg-grupo01

# 4. Logs de WireGuard
sudo dmesg | grep wireguard

# 5. Verificar IP pública del servidor
curl ifconfig.me
```

---

### Problema: Kathará no encuentra imágenes

**Síntoma**: Error "image not found"

**Solución**:
```bash
# Descargar imágenes necesarias
docker pull kathara/base
kathara check
```

---

### Problema: Alto consumo de recursos

**Síntoma**: Servidor lento, swaps excesivo

**Solución**:
```bash
# 1. Ver recursos por grupo
./scripts/05-estado-grupos.sh

# 2. Limitar recursos en kathara.conf
echo "manager:
  image: docker.io/kathara/base
  resources:
    mem: 512m
    cpus: 1.0" > grupos/grupo01/lab/kathara.conf

# 3. Detener grupos no utilizados
./scripts/04-detener-grupo.sh grupo15
```

---

### Problema: Error "device or resource busy"

**Síntoma**: No se puede eliminar/redimensionar red o volumen

**Solución**:
```bash
# 1. Identificar procesos usando el recurso
sudo lsof | grep grupo01

# 2. Matar procesos Kathará huérfanos
sudo pkill -f kathara

# 3. Limpiar todo
kathara wipe -f
sudo docker system prune -a
```

---

## Seguridad

### Lista de Verificación de Seguridad

- [ ] **Firewall**: Solo puertos necesarios abiertos (51820-51839, 22, opcional 5901-5920, 22001-22020)
- [ ] **SSH**: Autenticación por clave, root deshabilitado
- [ ] **WireGuard**: Claves generadas con `wg genkey` (curve25519)
- [ ] **Backups**: Almacenados fuera del servidor o en ubicación segura
- [ ] **Actualizaciones**: Sistema operativo y dependencias actualizadas
- [ ] **Monitoreo**: Logs revisados regularmente (`/var/log/syslog`, `dmesg`)
- [ ] **Acceso**: Solo usuarios autorizados tienen acceso al servidor

### Configuración Recomendada de Firewall (UFW)

```bash
# Instalar UFW
sudo apt-get install ufw

# Política por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Puertos necesarios
sudo ufw allow 22/tcp      # SSH administración
sudo ufw allow 51820:51839/udp  # WireGuard VPN

# Opcionales
sudo ufw allow 5901:5920/tcp    # VNC
sudo ufw allow 22001:22020/tcp  # SSH directo grupos

# Habilitar
sudo ufw enable
sudo ufw status verbose
```

### Rotación de Logs

Configurar en `/etc/logrotate.d/kathara-labs`:

```
/var/log/kathara-labs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
```

---

## FAQ

**P: ¿Cuántos grupos puedo tener simultáneamente?**

R: Hasta 20 grupos, limitado por recursos del servidor (RAM, CPU).

**P: ¿Puedo usar diferentes escenarios para cada grupo?**

R: Sí. Copia el escenario deseado en `grupos/grupoXX/lab/` antes de iniciar.

**P: ¿Los estudiantes necesitan VPN?**

R: Es el método recomendado. Alternativamente, puedes usar VNC o SSH directo (--enable-ssh).

**P: ¿Cómo recupero las contraseñas de los ZIPs de VPN?**

R: Están en `vpn-configs/contrasenas.txt` (protege este archivo).

**P: ¿Puedo automatizar el inicio de todos los grupos?**

R: Sí:
```bash
for i in $(seq -w 1 15); do
    ./scripts/03-iniciar-grupo.sh grupo$i
done
```

**P: ¿Qué pasa si se reinicia el servidor?**

R: Los grupos se detienen. Para iniciarlos automáticamente, agrega a `/etc/rc.local` o usa systemd.

**P: ¿Cómo comparto archivos con los estudiantes?**

R: Coloca archivos en `grupos/grupoXX/lab/shared/` antes de iniciar el escenario.

---

## Soporte

Para reportar problemas o sugerencias:

- **Issues**: https://github.com/tu-usuario/lab-vnx-seguridad/issues
- **Email**: soporte.labs@uah.es

---

*Documento generado para el despliegue docente de laboratorios Kathará - Universidad de Alcalá*
