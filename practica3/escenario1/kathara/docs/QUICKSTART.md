# Quick Start - p3 MITM HTTP

Navigation / Navegación: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)

## Español

### Modo completo (VPN + GUI)

```bash
cd kathara_migration_p3
docker build -t kathara-vpn -f Dockerfile.vpn .
docker build -t kathara-desktop -f Dockerfile.desktop .
chmod +x start-lab.sh stop-lab.sh verify.sh
./start-lab.sh
```

1. Importa `./shared/vpn/student1.conf` en WireGuard.
2. Activa el túnel.
3. Abre VNC en `192.168.0.2:5901` (víctima).
4. Password: `password`.

Validación recomendada:

```bash
./verify.sh --wait-for-handshake 30
```

Parada:

```bash
./stop-lab.sh
```

### Práctica MITM HTTP rápida

Una vez conectado por VNC a la víctima:

1. En víctima (VNC): Abrir Firefox y navegar a `http://testphp.vulnweb.com/login.php`
2. En atacante (CLI):
   ```bash
   kathara exec -d "$(pwd)" atacante "arpspoof -i eth0 -t 192.168.0.2 192.168.0.1"
   ```
3. Capturar tráfico:
   ```bash
   kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -w /shared/mitm.pcap"
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

### Diagnóstico express

Estado WireGuard en servidor:

```bash
kathara exec -d "$(pwd)" vpn "wg show"
```

Estado VNC en víctima:

```bash
kathara exec -d "$(pwd)" victima "ss -ltn"
```

Si no hay handshake en macOS/Windows:

```bash
./start-lab.sh --force-proxy
```

---

## English

### Full mode (VPN + GUI)

```bash
cd kathara_migration_p3
docker build -t kathara-vpn -f Dockerfile.vpn .
docker build -t kathara-desktop -f Dockerfile.desktop .
chmod +x start-lab.sh stop-lab.sh verify.sh
./start-lab.sh
```

1. Import `./shared/vpn/student1.conf` into WireGuard.
2. Activate the tunnel.
3. Open VNC at `192.168.0.2:5901` (victim).
4. Password: `password`.

Recommended validation:

```bash
./verify.sh --wait-for-handshake 30
```

Stop:

```bash
./stop-lab.sh
```

### Quick MITM HTTP practice

Once connected via VNC to the victim:

1. In victim (VNC): Open Firefox and browse to `http://testphp.vulnweb.com/login.php`
2. In attacker (CLI):
   ```bash
   kathara exec -d "$(pwd)" atacante "arpspoof -i eth0 -t 192.168.0.2 192.168.0.1"
   ```
3. Capture traffic:
   ```bash
   kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -w /shared/mitm.pcap"
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

VNC status in victim:

```bash
kathara exec -d "$(pwd)" victima "ss -ltn"
```

If handshake is missing on macOS/Windows:

```bash
./start-lab.sh --force-proxy
```
