# Quick Start - p2_2

Navigation / Navegacion: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)

## Espanol

### Modo completo (VPN + GUI)

```bash
cd kathara_migration_p2_2
docker build -t kathara-desktop -f Dockerfile.desktop .
docker build -t kathara-vpn -f Dockerfile.vpn .
chmod +x start-lab.sh stop-lab.sh verify.sh
./start-lab.sh
```

1. Importa `./shared/vpn/student1.conf` en WireGuard.
2. Activa el tunel.
3. Abre VNC en `192.168.0.5:5901`.
4. Password: `password`.

Validacion recomendada:

```bash
./verify.sh --wait-for-handshake 30
```

Parada:

```bash
./stop-lab.sh
```

### Modo CLI-only (sin VPN ni GUI)

```bash
./start-lab.sh --cli-only
./verify.sh
```

Para volver a modo completo:

```bash
./start-lab.sh
```

### Diagnostico express

Estado WireGuard en servidor:

```bash
kathara exec -d "$(pwd)" vpn "wg show"
```

Estado VNC en desktop:

```bash
kathara exec -d "$(pwd)" desktop "ss -ltn"
```

Si no hay handshake en macOS/Windows:

```bash
./start-lab.sh --force-proxy
```

---

## English

### Full mode (VPN + GUI)

```bash
cd kathara_migration_p2_2
docker build -t kathara-desktop -f Dockerfile.desktop .
docker build -t kathara-vpn -f Dockerfile.vpn .
chmod +x start-lab.sh stop-lab.sh verify.sh
./start-lab.sh
```

1. Import `./shared/vpn/student1.conf` into WireGuard.
2. Activate the tunnel.
3. Open VNC at `192.168.0.5:5901`.
4. Password: `password`.

Recommended validation:

```bash
./verify.sh --wait-for-handshake 30
```

Stop:

```bash
./stop-lab.sh
```

### CLI-only mode (no VPN, no GUI)

```bash
./start-lab.sh --cli-only
./verify.sh
```

Return to full mode:

```bash
./start-lab.sh
```

### Express diagnostics

WireGuard server status:

```bash
kathara exec -d "$(pwd)" vpn "wg show"
```

VNC status in desktop:

```bash
kathara exec -d "$(pwd)" desktop "ss -ltn"
```

If handshake is missing on macOS/Windows:

```bash
./start-lab.sh --force-proxy
```

---

Navigation / Navegacion: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)
