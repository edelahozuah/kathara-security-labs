# Laboratorios de Seguridad con Kathara

Repositorio de prácticas de laboratorio de la asignatura **Seguridad** del Grado en Ingeniería Informática de la Universidad de Alcalá.

## Autor

**Enrique de la Hoz** - Profesor de la Universidad de Alcalá

## Descripción

Este repositorio contiene los escenarios de red empleados en las prácticas de laboratorio, migrados desde la plataforma de emulación **VNX** a **Kathara**.

## Estructura

- `practica2/escenario1/` - Topología básica (h1-h4, r1-r2)
- `practica2/escenario2/` - Escenario de ataque
- `practica3/escenario1/` - Configuración de firewall

Cada escenario contiene:
- `original/` - Ficheros XML originales de VNX
- `kathara/` - Implementación en Kathara (lab.conf, .startup, scripts)

## Uso

```bash
cd practica2/escenario1/kathara
./start-lab.sh
./verify.sh
./stop-lab.sh
```

## Requisitos

- Kathara
- Docker
- WireGuard (para escenarios con VPN)
