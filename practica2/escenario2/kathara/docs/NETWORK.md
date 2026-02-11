# Network - p2_2

Navigation / Navegacion: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)

## Espanol

## 1. Topologia de red (ASCII)

```text
                           Host (WireGuard Client)
                                   |
                             UDP 51820/55182
                                   |
                        +----------------------+
                        | vpn                  |
                        | eth0 192.168.0.4/24 |
                        | wg0  10.99.0.1/24   |
                        +----------+-----------+
                                   |
                    LAN 192.168.0.0/24
      +-------------+--------+--------+-------------+
      |                      |                      |
+-----+------+        +------+-------+      +-------+------+
| victima    |        | atacante     |      | desktop      |
| 192.168.0.2|        | 192.168.0.3  |      | 192.168.0.5  |
+------------+        +--------------+      +--------------+
                                   |
                            +------+------+
                            | router      |
                            | LAN .0.1    |
                            | WAN .1.2    |
                            +------+------+
                                   |
                         WAN 10.255.0.0/30
                                   |
                            +------+------+
                            | natgw       |
                            | 10.255.0.1  |
                            | + bridged   |
                            +------+------+
                                   |
                                Internet
```

## 2. Subredes

- LAN: `192.168.0.0/24`
- WAN: `10.255.0.0/30`
- VPN: `10.99.0.0/24`

## 3. Direccionamiento por nodo

| Nodo | Interfaz | Direccion | Gateway |
|---|---|---|---|
| `victima` | `eth0` | `192.168.0.2/24` | `192.168.0.1` |
| `atacante` | `eth0` | `192.168.0.3/24` | `192.168.0.1` |
| `desktop` | `eth0` | `192.168.0.5/24` | `192.168.0.1` |
| `vpn` | `eth0` | `192.168.0.4/24` | n/a |
| `vpn` | `wg0` | `10.99.0.1/24` | n/a |
| `router` | `eth0` | `192.168.0.1/24` | n/a |
| `router` | `eth1` | `10.255.0.2/30` | `10.255.0.1` |
| `natgw` | `eth0` | `10.255.0.1/30` | n/a |

## 4. Rutas clave

### `victima`, `atacante`, `desktop`

- default via `192.168.0.1` (`router`)

### `router`

- `192.168.0.0/24` conectado en `eth0`
- `10.255.0.0/30` conectado en `eth1`
- default via `10.255.0.1`

### `natgw`

- `10.255.0.0/30` conectado en `eth0`
- ruta a `192.168.0.0/24` via `10.255.0.2`
- default via interfaz bridged (`eth1`, segun host)

### `vpn`

- LAN en `eth0`
- VPN en `wg0`
- iptables para FORWARD/NAT entre `wg0` y `eth0`

## 5. Reglas iptables importantes

### En `vpn`

- `POSTROUTING`: MASQUERADE de `10.99.0.0/24` hacia `eth0`
- `FORWARD`: permitir `wg0 -> eth0` hacia `192.168.0.0/24`
- `FORWARD`: permitir retorno `eth0 -> wg0` (ESTABLISHED,RELATED)

### En `natgw`

- `POSTROUTING`: MASQUERADE de `192.168.0.0/24` hacia uplink
- `FORWARD`: permitir ida LAN->uplink
- `FORWARD`: permitir retorno uplink->LAN (ESTABLISHED,RELATED)

## 6. Flujo de paquetes

### Caso A: Host remoto -> `victima`

```text
WG Client (10.99.0.2)
  -> vpn:wg0 (10.99.0.1)
  -> FORWARD wg0->eth0
  -> victima (192.168.0.2)
  -> respuesta
  -> vpn:eth0->wg0
  -> WG Client
```

### Caso B: `victima` -> Internet

```text
victima (192.168.0.2)
  -> router (192.168.0.1)
  -> natgw (10.255.0.1)
  -> MASQUERADE
  -> Internet
```

## 7. Comandos de diagnostico

Rutas y forwarding:

```bash
kathara exec -d "$(pwd)" router "ip route"
kathara exec -d "$(pwd)" natgw "ip route"
kathara exec -d "$(pwd)" router "cat /proc/sys/net/ipv4/ip_forward"
kathara exec -d "$(pwd)" natgw "cat /proc/sys/net/ipv4/ip_forward"
```

WireGuard y VPN:

```bash
kathara exec -d "$(pwd)" vpn "wg show"
kathara exec -d "$(pwd)" vpn "ip -brief a show wg0"
```

Conectividad:

```bash
kathara exec -d "$(pwd)" victima "ping -c 2 192.168.0.3"
kathara exec -d "$(pwd)" victima "ping -c 2 10.255.0.1"
kathara exec -d "$(pwd)" victima "ping -c 2 1.1.1.1"
```

---

## English

## 1. Network topology (ASCII)

```text
                           Host (WireGuard Client)
                                   |
                             UDP 51820/55182
                                   |
                        +----------------------+
                        | vpn                  |
                        | eth0 192.168.0.4/24 |
                        | wg0  10.99.0.1/24   |
                        +----------+-----------+
                                   |
                    LAN 192.168.0.0/24
      +-------------+--------+--------+-------------+
      |                      |                      |
+-----+------+        +------+-------+      +-------+------+
| victima    |        | atacante     |      | desktop      |
| 192.168.0.2|        | 192.168.0.3  |      | 192.168.0.5  |
+------------+        +--------------+      +--------------+
                                   |
                            +------+------+
                            | router      |
                            | LAN .0.1    |
                            | WAN .1.2    |
                            +------+------+
                                   |
                         WAN 10.255.0.0/30
                                   |
                            +------+------+
                            | natgw       |
                            | 10.255.0.1  |
                            | + bridged   |
                            +------+------+
                                   |
                                Internet
```

## 2. Subnets

- LAN: `192.168.0.0/24`
- WAN: `10.255.0.0/30`
- VPN: `10.99.0.0/24`

## 3. Per-node addressing

| Node | Interface | Address | Gateway |
|---|---|---|---|
| `victima` | `eth0` | `192.168.0.2/24` | `192.168.0.1` |
| `atacante` | `eth0` | `192.168.0.3/24` | `192.168.0.1` |
| `desktop` | `eth0` | `192.168.0.5/24` | `192.168.0.1` |
| `vpn` | `eth0` | `192.168.0.4/24` | n/a |
| `vpn` | `wg0` | `10.99.0.1/24` | n/a |
| `router` | `eth0` | `192.168.0.1/24` | n/a |
| `router` | `eth1` | `10.255.0.2/30` | `10.255.0.1` |
| `natgw` | `eth0` | `10.255.0.1/30` | n/a |

## 4. Key routes

### `victima`, `atacante`, `desktop`

- default via `192.168.0.1` (`router`)

### `router`

- `192.168.0.0/24` connected on `eth0`
- `10.255.0.0/30` connected on `eth1`
- default via `10.255.0.1`

### `natgw`

- `10.255.0.0/30` connected on `eth0`
- route to `192.168.0.0/24` via `10.255.0.2`
- default via bridged uplink (`eth1`, host-dependent)

### `vpn`

- LAN on `eth0`
- VPN on `wg0`
- iptables FORWARD/NAT between `wg0` and `eth0`

## 5. Important iptables rules

### On `vpn`

- `POSTROUTING`: MASQUERADE `10.99.0.0/24` out `eth0`
- `FORWARD`: allow `wg0 -> eth0` to `192.168.0.0/24`
- `FORWARD`: allow return `eth0 -> wg0` (ESTABLISHED,RELATED)

### On `natgw`

- `POSTROUTING`: MASQUERADE `192.168.0.0/24` to uplink
- `FORWARD`: allow outbound LAN->uplink
- `FORWARD`: allow inbound uplink->LAN (ESTABLISHED,RELATED)

## 6. Packet flow

### Case A: Remote host -> `victima`

```text
WG Client (10.99.0.2)
  -> vpn:wg0 (10.99.0.1)
  -> FORWARD wg0->eth0
  -> victima (192.168.0.2)
  -> reply
  -> vpn:eth0->wg0
  -> WG Client
```

### Case B: `victima` -> Internet

```text
victima (192.168.0.2)
  -> router (192.168.0.1)
  -> natgw (10.255.0.1)
  -> MASQUERADE
  -> Internet
```

## 7. Diagnostic commands

Routes and forwarding:

```bash
kathara exec -d "$(pwd)" router "ip route"
kathara exec -d "$(pwd)" natgw "ip route"
kathara exec -d "$(pwd)" router "cat /proc/sys/net/ipv4/ip_forward"
kathara exec -d "$(pwd)" natgw "cat /proc/sys/net/ipv4/ip_forward"
```

WireGuard and VPN:

```bash
kathara exec -d "$(pwd)" vpn "wg show"
kathara exec -d "$(pwd)" vpn "ip -brief a show wg0"
```

Connectivity:

```bash
kathara exec -d "$(pwd)" victima "ping -c 2 192.168.0.3"
kathara exec -d "$(pwd)" victima "ping -c 2 10.255.0.1"
kathara exec -d "$(pwd)" victima "ping -c 2 1.1.1.1"
```

---

Navigation / Navegacion: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)
