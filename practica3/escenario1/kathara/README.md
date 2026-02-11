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
cd kathara_migration_p3

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
- Bettercap UI: `http://192.168.0.3` (desde VPN)
- Atacante CLI: `kathara exec atacante "bettercap -iface eth0"`

## Documentation / Documentación

- Docs index: `docs/INDEX.md`
- Full guide: `docs/README.md`
- Quick commands: `docs/QUICKSTART.md`
- Architecture: `docs/ARCHITECTURE.md`
- Network details: `docs/NETWORK.md`
- MITM examples: `docs/EXAMPLES.md`
- Docker images: `docs/DOCKER.md`

## Practice Focus / Enfoque Práctico

Este escenario está diseñado específicamente para practicar ataques MITM HTTP:
- ARP Spoofing con ettercap/arpspoof
- Captura de credenciales HTTP
- Análisis de tráfico con Wireshark/tcpdump
- Intercepción de sesiones web no cifradas
