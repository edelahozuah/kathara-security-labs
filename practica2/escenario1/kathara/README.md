# Escenario p2_1 - Kathara (GUI por VPN)

Este escenario mantiene `h1` con GUI (LXQt + VNC), pero el acceso se hace por VPN WireGuard.
No se publica el puerto VNC en el host.

## 1) Construir imagenes necesarias

```bash
cd kathara_migration
docker build -t kathara-lubuntu -f Dockerfile.h1 .
docker build -t kathara-vpn -f Dockerfile.vpn .
```

## 2) Configuracion inicial recomendada

Da permisos a scripts de gestion:

```bash
chmod +x start-lab.sh stop-lab.sh verify.sh
```

En `lab.conf` puedes dejar el valor por defecto de endpoint:

```txt
vpn[env]="WG_ENDPOINT=CHANGE_ME_HOST_OR_DNS"
```

`start-lab.sh` ajusta automaticamente el endpoint del fichero cliente para uso local.

## 3) Arrancar escenario (cross-platform)

```bash
./start-lab.sh
```

Que hace este script:

- Arranca el escenario con `kathara lstart` (o reutiliza uno ya arrancado)
- Detecta plataforma (`linux`, `macos`, `windows-wsl`)
- Comprueba si la publicacion UDP de `vpn` es usable
- Si hace falta, crea proxy UDP local (`wg-proxy`) en `55182/udp`
- Actualiza `./shared/vpn/<cliente>.conf` con endpoint funcional para el host local

Opciones utiles:

```bash
./start-lab.sh --endpoint-host 127.0.0.1
./start-lab.sh --force-proxy
./start-lab.sh --no-proxy
```

## 4) Conectar estudiante por WireGuard

1. Importa `./shared/vpn/student1.conf` en el cliente WireGuard del estudiante.
2. Activa el tunel.
3. Accede por VNC a `10.1.0.2:5901` (`h1`).

Password VNC por defecto: `password`.

Escritorio por defecto: LXQt con tema oscuro (window manager `openbox`).
Aplicaciones preinstaladas: `qterminal`, `firefox-esr`, `featherpad`.

## 5) Verificacion rapida

```bash
./verify.sh --wait-for-handshake 30
```

Incluye:

- estado de forwarding y rutas en routers
- conectividad interna entre nodos
- handshake WireGuard (espera configurable)
- deteccion de proxy UDP local
- ping desde host a `10.1.0.2` y `10.1.2.2`

Modo detallado:

```bash
./verify.sh --wait-for-handshake 30 --verbose
```

## 6) Parada limpia

```bash
./stop-lab.sh
```

Este script ejecuta:

- `kathara lclean`
- eliminacion del proxy UDP local (`wg-proxy`) si existe

## Personalizacion por estudiante

En `lab.conf` puedes ajustar:

- `WG_CLIENT_NAME` (nombre del fichero cliente)
- `WG_CLIENT_CIDR` (IP del cliente VPN)
- `WG_SERVER_CIDR` (IP del servidor VPN)
- `WG_ALLOWED_IPS` (redes accesibles desde VPN)

## Compatibilidad por sistema operativo

| Plataforma | Estado | Notas |
|---|---|---|
| Linux + Docker Engine nativo | OK | Suele funcionar en UDP/51820 directo |
| macOS + Docker Desktop | OK | Puede requerir proxy UDP local (automatico con `start-lab.sh`) |
| Windows + Docker Desktop/WSL2 | OK | Puede requerir proxy UDP local (automatico con `start-lab.sh`) |

## Troubleshooting cross-platform

### No hay handshake WireGuard

1. Verifica con:

```bash
kathara exec -d "$(pwd)" vpn "wg show"
```

2. Si no aparece `latest handshake`, relanza usando:

```bash
./start-lab.sh --force-proxy
```

3. Reimporta `./shared/vpn/student1.conf` en el cliente WireGuard y reconecta.

### `kathara exec vpn ...` dice que `vpn` no esta running

Lanza comandos con `-d` o desde la carpeta del escenario:

```bash
kathara exec -d /ruta/a/kathara_migration vpn "wg show"
```

### WireGuard dice "activo" pero no hay ping

Ese estado puede significar solo interfaz local activa. La prueba real es:

- `latest handshake` presente en `wg show`
- contadores `transfer` aumentando

Usa `./verify.sh --wait-for-handshake 30` para validar extremo a extremo.

## Notas operativas

- `./shared` se monta en `/shared` en todos los nodos.
- La topologia original (h1-h4, r1-r2) se mantiene; se anade nodo `vpn` en Net0.
