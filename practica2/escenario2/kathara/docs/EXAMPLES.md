# Examples - p2_2

Navigation / Navegacion: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)

## Espanol

## 1. Flujo completo: VPN + VNC + pruebas basicas

```bash
cd kathara_migration_p2_2
./start-lab.sh
```

1. Importar `./shared/vpn/student1.conf` en WireGuard.
2. Activar tunel.
3. Abrir VNC a `192.168.0.5:5901`.
4. Desde `qterminal` en desktop:

```bash
ping -c 2 192.168.0.2
ping -c 2 192.168.0.3
```

## 2. Analisis con Wireshark en desktop

1. Conectar por VNC al desktop.
2. Abrir `wireshark` desde menu o terminal.
3. Capturar en interfaz `eth0`.
4. En otra consola, generar trafico:

```bash
kathara exec -d "$(pwd)" atacante "ping -c 5 192.168.0.2"
```

5. Observar en Wireshark el trafico ICMP en LAN.

## 3. Prueba de salida a Internet

```bash
kathara exec -d "$(pwd)" victima "ping -c 2 1.1.1.1"
kathara exec -d "$(pwd)" atacante "ping -c 2 8.8.8.8"
```

Si falla, revisar `natgw`:

```bash
kathara exec -d "$(pwd)" natgw "ip route"
kathara exec -d "$(pwd)" natgw "iptables -t nat -S POSTROUTING"
```

## 4. Verificacion automatizada

### Modo completo

```bash
./verify.sh --wait-for-handshake 30
```

### Modo CLI-only

```bash
./start-lab.sh --cli-only
./verify.sh
```

## 5. Diagnostico de handshake WireGuard

Estado en servidor VPN:

```bash
kathara exec -d "$(pwd)" vpn "wg show"
```

Si no aparece `latest handshake`:

```bash
./start-lab.sh --force-proxy
```

Reimportar `student1.conf` y reconectar.

## 6. Flujo de parada segura

```bash
./stop-lab.sh
```

Luego validar que no quedan nodos:

```bash
kathara linfo -d "$(pwd)"
```

## 7. Uso de carpeta compartida

Host:

```bash
cp ./docs/QUICKSTART.md ./shared/
```

Dentro de nodos:

```bash
kathara exec -d "$(pwd)" victima "ls -la /shared"
kathara exec -d "$(pwd)" desktop "ls -la /shared"
```

---

## English

## 1. Full flow: VPN + VNC + basic checks

```bash
cd kathara_migration_p2_2
./start-lab.sh
```

1. Import `./shared/vpn/student1.conf` into WireGuard.
2. Activate tunnel.
3. Open VNC to `192.168.0.5:5901`.
4. From desktop `qterminal`:

```bash
ping -c 2 192.168.0.2
ping -c 2 192.168.0.3
```

## 2. Traffic analysis with Wireshark on desktop

1. Connect to desktop via VNC.
2. Open `wireshark` from menu or terminal.
3. Capture on interface `eth0`.
4. In another shell, generate traffic:

```bash
kathara exec -d "$(pwd)" atacante "ping -c 5 192.168.0.2"
```

5. Observe LAN ICMP traffic in Wireshark.

## 3. Internet egress test

```bash
kathara exec -d "$(pwd)" victima "ping -c 2 1.1.1.1"
kathara exec -d "$(pwd)" atacante "ping -c 2 8.8.8.8"
```

If it fails, inspect `natgw`:

```bash
kathara exec -d "$(pwd)" natgw "ip route"
kathara exec -d "$(pwd)" natgw "iptables -t nat -S POSTROUTING"
```

## 4. Automated verification

### Full mode

```bash
./verify.sh --wait-for-handshake 30
```

### CLI-only mode

```bash
./start-lab.sh --cli-only
./verify.sh
```

## 5. WireGuard handshake diagnostics

VPN server status:

```bash
kathara exec -d "$(pwd)" vpn "wg show"
```

If `latest handshake` is missing:

```bash
./start-lab.sh --force-proxy
```

Re-import `student1.conf` and reconnect.

## 6. Safe shutdown flow

```bash
./stop-lab.sh
```

Then verify no running nodes:

```bash
kathara linfo -d "$(pwd)"
```

## 7. Shared folder usage

Host:

```bash
cp ./docs/QUICKSTART.md ./shared/
```

Inside nodes:

```bash
kathara exec -d "$(pwd)" victima "ls -la /shared"
kathara exec -d "$(pwd)" desktop "ls -la /shared"
```

---

Navigation / Navegacion: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)
