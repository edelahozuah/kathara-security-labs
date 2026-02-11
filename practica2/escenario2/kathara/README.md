# p2_2 Security Lab / Laboratorio p2_2

[ES]
Escenario de ciberseguridad con LAN atacante-victima, salida a Internet por NAT,
acceso remoto seguro por WireGuard y escritorio grafico por VNC.

[EN]
Cybersecurity scenario with attacker-victim LAN, Internet egress via NAT,
secure remote access through WireGuard, and graphical desktop over VNC.

## Quick Start / Inicio Rapido

```bash
cd kathara_migration_p2_2
docker build -t kathara-desktop -f Dockerfile.desktop .
docker build -t kathara-vpn -f Dockerfile.vpn .
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
- VNC desktop: `192.168.0.5:5901`
- VNC password: `password`

## Documentation / Documentacion

- Common prerequisites and tool installation: `../../../INSTALL.md`, `../../../README.md`, `../../../USO.md`
- Docs index: `docs/INDEX.md`
- Full guide: `docs/README.md`
- Quick commands: `docs/QUICKSTART.md`
- Architecture: `docs/ARCHITECTURE.md`
- Network details: `docs/NETWORK.md`
- Practical examples: `docs/EXAMPLES.md`
- Docker images: `docs/DOCKER.md`
