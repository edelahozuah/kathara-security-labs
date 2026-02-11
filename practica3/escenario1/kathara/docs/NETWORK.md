# Network - p3 MITM HTTP

Navigation / Navegación: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)

## Español

## 1. Topología de red (ASCII)

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
       +-------------+--------+-------------+
       |                      |             
 +-----+------+        +------+-------+     
 | victima    |        | atacante     |     
 | 192.168.0.2|        | 192.168.0.3  |     
 | VNC :5901  |        | Kali CLI     |     
 +------------+        +--------------+     
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

- **LAN**: `192.168.0.0/24`
- **WAN**: `10.255.0.0/30`
- **VPN**: `10.99.0.0/24`

## 3. Direccionamiento por nodo

| Nodo | Interfaz | Dirección | Gateway |
|---|---|---|---|
| `victima` | `eth0` | `192.168.0.2/24` | `192.168.0.1` |
| `atacante` | `eth0` | `192.168.0.3/24` | `192.168.0.1` |
| `vpn` | `eth0` | `192.168.0.4/24` | n/a |
| `vpn` | `wg0` | `10.99.0.1/24` | n/a |
| `router` | `eth0` | `192.168.0.1/24` | n/a |
| `router` | `eth1` | `10.255.0.2/30` | `10.255.0.1` |
| `natgw` | `eth0` | `10.255.0.1/30` | n/a |

## 4. Rutas clave

### `victima` y `atacante`

- default via `192.168.0.1` (`router`)

### `router`

- `192.168.0.0/24` conectado en `eth0`
- `10.255.0.0/30` conectado en `eth1`
- default via `10.255.0.1`

### `natgw`

- `10.255.0.0/30` conectado en `eth0`
- ruta a `192.168.0.0/24` via `10.255.0.2`
- default via interfaz bridged (`eth1`, según host)

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

## 6. Consideraciones para MITM

### Posicionamiento del atacante

El atacante está en la misma LAN (`192.168.0.0/24`) que la víctima, lo que permite:
- ARP Spoofing directo sin enrutamiento
- Captura de tráfico broadcast/multicast
- Posición "man-in-the-middle" al suplantar al gateway

### Tráfico típico MITM

```
Víctima (192.168.0.2) ──ARP spoof──> Atacante (192.168.0.3) ──forward──> Router (192.168.0.1)
                              <─────────────────────────────────────────────────────────────
```

### TTL y forwarding

- El atacante debe tener `ip_forward=1` para reenviar paquetes
- El router decrementa TTL en cada salto WAN
- El NATGW aplica MASQUERADE ocultando la LAN privada

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
       +-------------+--------+-------------+
       |                      |             
 +-----+------+        +------+-------+     
 | victima    |        | atacante     |     
 | 192.168.0.2|        | 192.168.0.3  |     
 | VNC :5901  |        | Kali CLI     |     
 +------------+        +--------------+     
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

- **LAN**: `192.168.0.0/24`
- **WAN**: `10.255.0.0/30`
- **VPN**: `10.99.0.0/24`

## 3. Node addressing

| Node | Interface | Address | Gateway |
|---|---|---|---|
| `victima` | `eth0` | `192.168.0.2/24` | `192.168.0.1` |
| `atacante` | `eth0` | `192.168.0.3/24` | `192.168.0.1` |
| `vpn` | `eth0` | `192.168.0.4/24` | n/a |
| `vpn` | `wg0` | `10.99.0.1/24` | n/a |
| `router` | `eth0` | `192.168.0.1/24` | n/a |
| `router` | `eth1` | `10.255.0.2/30` | `10.255.0.1` |
| `natgw` | `eth0` | `10.255.0.1/30` | n/a |

## 4. Key routes

### `victima` and `atacante`

- default via `192.168.0.1` (`router`)

### `router`

- `192.168.0.0/24` connected on `eth0`
- `10.255.0.0/30` connected on `eth1`
- default via `10.255.0.1`

### `natgw`

- `10.255.0.0/30` connected on `eth0`
- route to `192.168.0.0/24` via `10.255.0.2`
- default via bridged interface (`eth1`, depending on host)

### `vpn`

- LAN on `eth0`
- VPN on `wg0`
- iptables for FORWARD/NAT between `wg0` and `eth0`

## 5. Important iptables rules

### On `vpn`

- `POSTROUTING`: MASQUERADE from `10.99.0.0/24` to `eth0`
- `FORWARD`: allow `wg0 -> eth0` to `192.168.0.0/24`
- `FORWARD`: allow return `eth0 -> wg0` (ESTABLISHED,RELATED)

### On `natgw`

- `POSTROUTING`: MASQUERADE from `192.168.0.0/24` to uplink
- `FORWARD`: allow LAN->uplink
- `FORWARD`: allow return uplink->LAN (ESTABLISHED,RELATED)

## 6. MITM considerations

### Attacker positioning

The attacker is on the same LAN (`192.168.0.0/24`) as the victim, enabling:
- Direct ARP Spoofing without routing
- Broadcast/multicast traffic capture
- "Man-in-the-middle" position by impersonating the gateway

### Typical MITM traffic

```
Victim (192.168.0.2) ──ARP spoof──> Attacker (192.168.0.3) ──forward──> Router (192.168.0.1)
                              <─────────────────────────────────────────────────────────────
```

### TTL and forwarding

- Attacker must have `ip_forward=1` to forward packets
- Router decrements TTL on each WAN hop
- NATGW applies MASQUERADE hiding the private LAN
