# Laboratorios de Seguridad con Kathara

[![UAH](https://img.shields.io/badge/Universidad-Alcalá-red)](https://www.uah.es/)
[![Grado](https://img.shields.io/badge/Grado-Ingeniería%20Informática-blue)](https://www.uah.es/es/estudios/estudios-oficiales-grado/ingenieria-informatica/)
[![Asignatura](https://img.shields.io/badge/Asignatura-Seguridad-orange)](https://www.uah.es/)

[![Multi-Arch](https://img.shields.io/badge/arquitectura-x86__64%20%7C%20ARM64-success)](https://github.com/edelahozuah/kathara-security-labs)
[![Docker](https://img.shields.io/badge/Docker-Soportado-blue?logo=docker)](https://www.docker.com/)
[![Kathara](https://img.shields.io/badge/Kathara-v2.0+-blueviolet)](https://www.kathara.org/)
[![WireGuard](https://img.shields.io/badge/WireGuard-VPN%20disponible-lightblue)](https://www.wireguard.com/)

[![GitHub last commit](https://img.shields.io/github/last-commit/edelahozuah/kathara-security-labs)](https://github.com/edelahozuah/kathara-security-labs/commits/main)
[![GitHub repo size](https://img.shields.io/github/repo-size/edelahozuah/kathara-security-labs)](https://github.com/edelahozuah/kathara-security-labs)

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
