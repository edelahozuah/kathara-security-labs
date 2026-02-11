# Docker Images - p2_2

Navigation / Navegacion: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)

## Espanol

## 1. Imagen `kathara-vpn`

Archivo: `Dockerfile.vpn`

Base:

- `kathara/base`

Paquetes principales:

- `wireguard-tools`
- `wireguard-go`
- `iproute2`
- `iptables`
- `iputils-ping`
- `procps`

Objetivo:

- ejecutar servidor WireGuard en el nodo `vpn`
- crear y mantener interfaz `wg0`
- aplicar reglas de FORWARD/NAT

Exposicion:

- `EXPOSE 51820/udp`

## 2. Imagen `kathara-desktop`

Archivo: `Dockerfile.desktop`

Base:

- `kathara/base`

Stack grafico principal:

- `lxqt-core`, `lxqt-session`, `lxqt-panel`, `lxqt-config`, `lxqt-themes`
- `openbox`
- `pcmanfm-qt`
- `tightvncserver`

Aplicaciones solicitadas:

- `qterminal`
- `firefox-esr`
- `featherpad`
- `wireshark`

Soporte adicional:

- `dbus-x11`
- `xfonts-base`
- `xdg-utils`
- `adwaita-icon-theme`

Configuracion incluida:

- password VNC por defecto: `password`
- script `~/.vnc/xstartup` para iniciar LXQt con `dbus-launch`

Exposicion:

- `EXPOSE 5901`

## 3. Construccion

```bash
cd kathara_migration_p2_2
docker build -t kathara-vpn -f Dockerfile.vpn .
docker build -t kathara-desktop -f Dockerfile.desktop .
```

## 4. Verificacion de imagenes

```bash
docker image ls kathara-vpn kathara-desktop
```

## 5. Personalizacion rapida

### Agregar paquete a desktop

1. Editar `Dockerfile.desktop`.
2. Rebuild:

```bash
docker build -t kathara-desktop -f Dockerfile.desktop .
```

3. Reiniciar escenario:

```bash
./stop-lab.sh
./start-lab.sh
```

### Cambiar password VNC

Editar bloque en `Dockerfile.desktop`:

```bash
echo "password" | vncpasswd -f > /root/.vnc/passwd
```

Despues rebuild + restart.

## 6. Notas operativas

- `wireshark` puede requerir privilegios segun captura deseada.
- En este lab, el usuario de desktop es `root` dentro del contenedor.
- `start-lab.sh` y `desktop.startup` aplican la configuracion final en runtime.

---

## English

## 1. `kathara-vpn` image

File: `Dockerfile.vpn`

Base:

- `kathara/base`

Main packages:

- `wireguard-tools`
- `wireguard-go`
- `iproute2`
- `iptables`
- `iputils-ping`
- `procps`

Purpose:

- run WireGuard server on node `vpn`
- create and manage `wg0` interface
- apply FORWARD/NAT rules

Exposure:

- `EXPOSE 51820/udp`

## 2. `kathara-desktop` image

File: `Dockerfile.desktop`

Base:

- `kathara/base`

Main graphical stack:

- `lxqt-core`, `lxqt-session`, `lxqt-panel`, `lxqt-config`, `lxqt-themes`
- `openbox`
- `pcmanfm-qt`
- `tightvncserver`

Requested applications:

- `qterminal`
- `firefox-esr`
- `featherpad`
- `wireshark`

Additional support:

- `dbus-x11`
- `xfonts-base`
- `xdg-utils`
- `adwaita-icon-theme`

Included configuration:

- default VNC password: `password`
- `~/.vnc/xstartup` launching LXQt with `dbus-launch`

Exposure:

- `EXPOSE 5901`

## 3. Build

```bash
cd kathara_migration_p2_2
docker build -t kathara-vpn -f Dockerfile.vpn .
docker build -t kathara-desktop -f Dockerfile.desktop .
```

## 4. Image verification

```bash
docker image ls kathara-vpn kathara-desktop
```

## 5. Quick customization

### Add package to desktop

1. Edit `Dockerfile.desktop`.
2. Rebuild:

```bash
docker build -t kathara-desktop -f Dockerfile.desktop .
```

3. Restart scenario:

```bash
./stop-lab.sh
./start-lab.sh
```

### Change VNC password

Edit this block in `Dockerfile.desktop`:

```bash
echo "password" | vncpasswd -f > /root/.vnc/passwd
```

Then rebuild + restart.

## 6. Operational notes

- `wireshark` privileges depend on capture method.
- In this lab, desktop user is `root` inside container.
- `start-lab.sh` and `desktop.startup` apply final runtime config.

---

Navigation / Navegacion: [Index](INDEX.md) | [Guide](README.md) | [Quickstart](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Network](NETWORK.md) | [Examples](EXAMPLES.md) | [Docker](DOCKER.md)
