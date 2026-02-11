# Plantilla escenario base Kathara

Plantilla reutilizable para crear nuevos escenarios con un esqueleto comun del
repositorio:

- acceso remoto por VPN WireGuard
- desktop grafico por VNC
- salida a Internet por `router` + `natgw`
- nodo base (`kathara/base`) para pruebas iniciales

## Estructura incluida

- `lab.conf`
- `start-lab.sh`, `verify.sh`, `stop-lab.sh`
- `Dockerfile.vpn`, `Dockerfile.desktop`
- `base.startup`, `router.startup`, `natgw.startup`, `vpn.startup`, `desktop.startup`
- `shared/vpn/` para config y claves WireGuard

## Crear un escenario nuevo desde la plantilla

```bash
cp -R plantillas/escenario-base/kathara practicaX/escenarioY/kathara
cd practicaX/escenarioY/kathara
chmod +x *.sh *.startup
```

`start-lab.sh` construye automaticamente `kathara-vpn` y `kathara-desktop`
si no existen en tu host.

## Flujo recomendado para diseno de topologia

1. Edita `lab.conf` y anade nodos internos en la seccion `EXTENSION ZONE`.
2. Crea los `*.startup` nuevos para esos nodos.
3. Si anades nuevas subredes, actualiza en `lab.conf`:
   - `vpn[env]="WG_ALLOWED_IPS=..."`
   - `vpn[env]="VPN_ACCESS_NETS=..."`
   - `natgw[env]="NAT_NETS=..."`
4. Arranca y verifica:

```bash
./start-lab.sh
./verify.sh --wait-for-handshake 30
```

5. Para pruebas sin VPN ni GUI:

```bash
./start-lab.sh --cli-only
./verify.sh
```

6. Parada:

```bash
./stop-lab.sh
```

## Documentacion comun (no duplicar instalacion aqui)

- `../../../INSTALL.md`
- `../../../USO.md`
- `../../../README.md`
