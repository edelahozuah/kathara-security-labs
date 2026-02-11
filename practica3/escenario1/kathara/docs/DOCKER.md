# Docker Images - p3 MITM HTTP

Navigation / Navegación: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)

## Español

## Imágenes utilizadas

| Imagen | Nodo | Propósito | Tamaño aprox. |
|---|---|---|---|
| `kathara/base` | router, natgw | Base Debian con herramientas de red | ~150MB |
| `kathara-kali` | atacante | Kali Linux con bettercap + herramientas MITM | ~2GB |
| `kathara-desktop` | victima | Ubuntu con LXQt + Firefox + VNC | ~800MB |
| `kathara-vpn` | vpn | Debian + WireGuard tools | ~200MB |

## Construcción de imágenes personalizadas

### kathara-desktop (víctima)

```bash
docker build -t kathara-desktop -f Dockerfile.desktop .
```

**Incluye:**
- LXQt desktop environment (tema oscuro)
- TigerVNC server
- Firefox ESR (navegador objetivo para MITM)
- qterminal (terminal Qt)
- Network tools (ping, curl, wget, dnsutils)

**Usuario:** root (por defecto en Kathara)  
**VNC Password:** password  
**Display:** :1 (puerto 5901)

### kathara-vpn

```bash
docker build -t kathara-vpn -f Dockerfile.vpn .
```

**Incluye:**
- wireguard-tools
- wireguard-go (para compatibilidad)
- iptables
- iproute2

### kathara-kali (atacante)

```bash
docker build -t kathara-kali -f Dockerfile.kali .
```

**Incluye:**
- bettercap + bettercap-ui (web UI en puerto 80)
- ettercap-text-only
- arpspoof, dsniff
- tcpdump, tshark (CLI)
- mitmproxy
- nmap, netcat

**Bettercap UI:** http://192.168.0.3 (accesible desde VPN)  
**Puertos expuestos:** 80, 443, 8080, 8443

## Personalización de imágenes

### Añadir paquetes al atacante

Editar `atacante.startup` (instala en cada arranque):

```bash
apt-get update && apt-get install -y nombre-paquete
```

### Crear imagen personalizada del atacante

Crear `Dockerfile.atacante`:

```dockerfile
FROM kathara/kali

RUN apt-get update && apt-get install -y \
    herramienta-extra1 \
    herramienta-extra2 \
    && rm -rf /var/lib/apt/lists/*
```

Construir:

```bash
docker build -t kathara-kali-custom -f Dockerfile.atacante .
```

Y modificar `lab.conf`:

```bash
atacante[image]="kathara-kali-custom"
```

### Optimización de tamaño

Las imágenes Kathara se pueden optimizar:

```dockerfile
# Limpiar caché
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Usar --no-install-recommends
RUN apt-get install -y --no-install-recommends paquete
```

## Redes Docker

Kathara gestiona automáticamente las redes entre contenedores. No es necesario crear redes Docker manualmente.

**Nota:** El modo `bridged` en `lab.conf` usa la red del host Docker, no redes Docker bridge personalizadas.

## Volúmenes

La carpeta `./shared` se monta en `/shared` en todos los nodos:

```bash
# lab.conf
victima[folder]="./shared"
victima[bind]="/shared"
```

Esto permite transferencia de archivos entre host y contenedores.

---

## English

## Images used

| Image | Node | Purpose | Approx. size |
|---|---|---|---|
| `kathara/base` | router, natgw | Base Debian with network tools | ~150MB |
| `kathara-kali` | atacante | Kali Linux with bettercap + MITM tools | ~2GB |
| `kathara-desktop` | victima | Ubuntu with LXQt + Firefox + VNC | ~800MB |
| `kathara-vpn` | vpn | Debian + WireGuard tools | ~200MB |

## Building custom images

### kathara-desktop (victim)

```bash
docker build -t kathara-desktop -f Dockerfile.desktop .
```

**Includes:**
- LXQt desktop environment (dark theme)
- TigerVNC server
- Firefox ESR (target browser for MITM)
- qterminal (Qt terminal)
- Network tools (ping, curl, wget, dnsutils)

**User:** root (Kathara default)  
**VNC Password:** password  
**Display:** :1 (port 5901)

### kathara-vpn

```bash
docker build -t kathara-vpn -f Dockerfile.vpn .
```

**Includes:**
- wireguard-tools
- wireguard-go (for compatibility)
- iptables
- iproute2

### kathara-kali (attacker)

```bash
docker build -t kathara-kali -f Dockerfile.kali .
```

**Includes:**
- bettercap + bettercap-ui (web UI on port 80)
- ettercap-text-only
- arpspoof, dsniff
- tcpdump, tshark (CLI)
- mitmproxy
- nmap, netcat

**Bettercap UI:** http://192.168.0.3 (accessible via VPN)  
**Exposed ports:** 80, 443, 8080, 8443

## Customizing images

### Adding packages to attacker

Edit `atacante.startup` (installs on each boot):

```bash
apt-get update && apt-get install -y package-name
```

### Creating custom attacker image

Create `Dockerfile.atacante`:

```dockerfile
FROM kathara/kali

RUN apt-get update && apt-get install -y \
    extra-tool1 \
    extra-tool2 \
    && rm -rf /var/lib/apt/lists/*
```

Build:

```bash
docker build -t kathara-kali-custom -f Dockerfile.atacante .
```

And modify `lab.conf`:

```bash
atacante[image]="kathara-kali-custom"
```

### Size optimization

Kathara images can be optimized:

```dockerfile
# Clean cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Use --no-install-recommends
RUN apt-get install -y --no-install-recommends package
```

## Docker Networks

Kathara automatically manages networks between containers. No need to create Docker networks manually.

**Note:** The `bridged` mode in `lab.conf` uses the host Docker network, not custom Docker bridge networks.

## Volumes

The `./shared` folder is mounted to `/shared` in all nodes:

```bash
# lab.conf
victima[folder]="./shared"
victima[bind]="/shared"
```

This allows file transfer between host and containers.
