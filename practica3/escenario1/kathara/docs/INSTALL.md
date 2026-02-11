# Instalación de Kathara

Guía de instalación de Kathara Framework para los laboratorios de seguridad.

## 📋 Requisitos Previos

- Docker Desktop o Docker Engine
- Python 3.7 o superior
- pip (gestor de paquetes Python)

## 🖥️ Instalación por Sistema Operativo

### Linux

```bash
# Instalar usando pip (recomendado)
pip3 install kathara

# Verificar instalación
kathara --version

# Configurar Docker (si no está configurado)
sudo usermod -aG docker $USER
# Cerrar sesión y volver a iniciar para aplicar cambios de grupo
```

**Distribuciones específicas:**

#### Ubuntu/Debian
```bash
# Actualizar repositorios
sudo apt update

# Instalar dependencias
sudo apt install -y python3-pip docker.io

# Instalar Kathara
pip3 install kathara

# Añadir usuario al grupo docker
sudo usermod -aG docker $USER
```

#### Fedora/RHEL/CentOS
```bash
# Instalar dependencias
sudo dnf install -y python3-pip docker

# Instalar Kathara
pip3 install kathara

# Añadir usuario al grupo docker
sudo usermod -aG docker $USER
```

### macOS

```bash
# Instalar Homebrew (si no lo tienes)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar Docker Desktop
brew install --cask docker

# Instalar Kathara
pip3 install kathara

# Verificar instalación
kathara --version
```

**Nota para macOS:** Docker Desktop debe estar ejecutándose antes de usar Kathara.

### Windows

#### Opción 1: WSL2 (Recomendada)

1. **Instalar WSL2:**
   ```powershell
   # En PowerShell como administrador
   wsl --install
   ```

2. **Instalar Docker Desktop:**
   - Descargar de [docker.com](https://www.docker.com/products/docker-desktop)
   - Habilitar integración con WSL2 en configuración

3. **Instalar Kathara en WSL2:**
   ```bash
   # Dentro de WSL2 (Ubuntu)
   sudo apt update
   sudo apt install -y python3-pip
   pip3 install kathara
   ```

#### Opción 2: Windows Nativo

```powershell
# Instalar Python 3 desde python.org
# Instalar Docker Desktop

# Instalar Kathara
pip install kathara

# Verificar instalación
kathara --version
```

## 🐳 Configuración de Docker

### Verificar Docker está corriendo

```bash
# Linux/macOS
docker info

# Windows (PowerShell)
docker info
```

### Solución de problemas comunes

#### Error: "permission denied while trying to connect to Docker daemon"

```bash
# Linux: Añadir usuario al grupo docker
sudo usermod -aG docker $USER
# Cerrar sesión y volver a iniciar

# Verificar
newgrp docker
docker ps
```

#### Error: "Cannot connect to the Docker daemon"

```bash
# Linux: Iniciar servicio Docker
sudo systemctl start docker
sudo systemctl enable docker  # Para iniciar automáticamente

# macOS/Windows: Asegurar que Docker Desktop está ejecutándose
```

## ✅ Verificación de la Instalación

```bash
# Verificar versión de Kathara
kathara --version

# Verificar configuración
kathara check

# Listar imágenes disponibles
kathara list
```

## 🔄 Actualización

```bash
# Actualizar Kathara a la última versión
pip3 install --upgrade kathara

# Verificar nueva versión
kathara --version
```

## 📚 Recursos Adicionales

- **Documentación oficial:** [https://www.kathara.org/](https://www.kathara.org/)
- **GitHub:** [https://github.com/KatharaFramework/Kathara](https://github.com/KatharaFramework/Kathara)
- **Wiki:** [https://github.com/KatharaFramework/Kathara/wiki](https://github.com/KatharaFramework/Kathara/wiki)

## 🆘 Soporte

Si encuentras problemas durante la instalación:

1. Revisar [issues en GitHub](https://github.com/KatharaFramework/Kathara/issues)
2. Consultar la [documentación oficial](https://github.com/KatharaFramework/Kathara/wiki)
3. Verificar que Docker está correctamente instalado y funcionando

## 📝 Notas Importantes

- **Linux:** Requiere privilegios de Docker (grupo `docker`)
- **macOS:** Docker Desktop debe estar ejecutándose
- **Windows:** WSL2 recomendado sobre nativo
- **Firewall:** Puede ser necesario configurar excepciones para Docker

---

**Versión recomendada:** Kathara 2.0 o superior
