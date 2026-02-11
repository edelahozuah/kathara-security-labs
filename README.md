# Laboratorios de Seguridad con Kathara

[![Multi-Arch](https://img.shields.io/badge/arquitectura-x86__64%20%7C%20ARM64-success)](https://github.com/edelahozuah/kathara-security-labs)
[![Docker](https://img.shields.io/badge/Docker-Soportado-blue?logo=docker)](https://www.docker.com/)
[![Kathara](https://img.shields.io/badge/Kathara-v2.0+-blueviolet)](https://www.kathara.org/)
[![WireGuard](https://img.shields.io/badge/WireGuard-VPN%20disponible-lightblue)](https://www.wireguard.com/)

[![GitHub last commit](https://img.shields.io/github/last-commit/edelahozuah/kathara-security-labs)](https://github.com/edelahozuah/kathara-security-labs/commits/main)
[![GitHub repo size](https://img.shields.io/github/repo-size/edelahozuah/kathara-security-labs)](https://github.com/edelahozuah/kathara-security-labs)

**Universidad de Alcalá**

Repositorio de prácticas de laboratorio de la asignatura **Seguridad** para los grados:
- Grado en Ingeniería Informática
- Grado en Ingeniería Telemática
- Grado en Ingeniería de Computadores

## Autor

**Enrique de la Hoz** - Profesor de la Universidad de Alcalá

## 🤖 Nota sobre el Uso de Herramientas de IA

Este material educativo ha sido desarrollado empleando **opencode**, una herramienta de asistencia por IA que integra múltiples modelos de lenguaje (Claude, GPT-4, etc.).

La IA ha contribuido a:
- Migrar escenarios de VNX a Kathara
- Estandarizar configuraciones multi-arquitectura (x86_64/ARM64)
- Generar documentación técnica completa (guías, ejemplos, troubleshooting)
- Optimizar Dockerfiles para compatibilidad multi-plataforma
- Crear scripts de automatización y verificación

El profesorado ha supervisado, validado y adaptado todo el contenido para garantizar su adecuación pedagógica y técnica.

## 📋 Uso del Repositorio / Repository Usage

**⚠️ IMPORTANTE: ¿Docente o Estudiante?**

Este material soporta dos modalidades de uso:

### 👨‍🏫 Docentes (Plataforma Centralizada)
- **Escenario**: Servidor compartido en laboratorio/departamento
- **VPN**: ✅ **SÍ** - Usa WireGuard para acceso remoto seguro
- **Guía**: Ver [`practica3/escenario1/kathara/docs/USO.md`](practica3/escenario1/kathara/docs/USO.md)

### 👨‍🎓 Estudiantes (Equipo Local)
- **Escenario**: Laptop/PC personal
- **VPN**: ❌ **NO** - Accede directamente por localhost (sin VPN)
- **Guía**: Ver [`practica3/escenario1/kathara/docs/USO.md`](practica3/escenario1/kathara/docs/USO.md)

📖 **Documentación completa de uso por perfil**: [`docs/USO.md`](practica3/escenario1/kathara/docs/USO.md)

---

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

## 📚 Documentación / Documentation

Cada escenario incluye documentación detallada en su carpeta `kathara/docs/`:

- **[USO.md](practica3/escenario1/kathara/docs/USO.md)** - Guía por perfil (docente vs estudiante) ⚡ **Importante**
- **[INSTALL.md](practica3/escenario1/kathara/docs/INSTALL.md)** - Instalación de Kathara
- **[QUICKSTART.md](practica3/escenario1/kathara/docs/QUICKSTART.md)** - Inicio rápido
- **[README.md](practica3/escenario1/kathara/docs/README.md)** - Guía completa del escenario
- **[EXAMPLES.md](practica3/escenario1/kathara/docs/EXAMPLES.md)** - Ejemplos de ataques MITM

## Requisitos

- **[Kathara](practica3/escenario1/kathara/docs/INSTALL.md)** - Ver guía de instalación
- **Docker** - Docker Desktop (macOS/Windows) o Docker Engine (Linux)
- **WireGuard** - Solo para docentes en modo centralizado (ver [USO.md](practica3/escenario1/kathara/docs/USO.md))
