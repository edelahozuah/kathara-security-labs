# Guía de Uso por Perfil / Usage Guide by Profile

Esta guía distingue entre dos casos de uso principales: **docentes con plataforma centralizada** y **estudiantes con despliegue local**.

---

## 🇪🇸 Español

### Matriz de Decisión Rápida

| Característica | Docente (Centralizado) | Estudiante (Local) |
|----------------|------------------------|-------------------|
| ¿Servidor compartido? | ✅ SÍ | ❌ NO |
| ¿Acceso remoto? | ✅ SÍ | ❌ NO |
| ¿Usar VPN (WireGuard)? | ✅ **SÍ** | ❌ **NO** |
| ¿VNC por VPN? | ✅ SÍ | ❌ NO (localhost) |
| ¿Modo bridged? | Opcional | Recomendado |
| Complejidad | Media | Baja |

---

## Perfil 1: Docente - Plataforma Centralizada

### 📋 Escenario Típico

- **Infraestructura**: Servidor del laboratorio/departamento ejecuta Kathara
- **Usuarios**: Múltiples estudiantes acceden simultáneamente
- **Aislamiento**: Cada estudiante tiene su propio entorno aislado
- **Acceso**: Desde redes externas (casa, biblioteca, campus)

### 🔒 ¿Por qué USAR VPN?

La VPN (WireGuard) es **necesaria y recomendada** porque:

1. **Seguridad**: Tuneliza conexiones desde redes externas no confiables
2. **Aislamiento**: Separa redes entre diferentes estudiantes
3. **Acceso remoto**: Permite conexión desde fuera de la universidad
4. **VNC seguro**: El escritorio remino viaja cifrado por el túnel VPN
5. **Control**: El docente gestiona quién tiene acceso (configs WireGuard individuales)

### 🏗️ Arquitectura de Despliegue

```
                    Red externa (Internet)
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    [Estudiante       [Estudiante        [Estudiante
     en casa]         en biblioteca]     en campus]
         │                 │                 │
         └─────────────────┼─────────────────┘
                           │
                    ┌──────┴──────┐
                    │   VPN WG    │
                    │  (túnel)    │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │   Servidor UAH          │
              │   (Kathara Host)        │
              │                         │
              │  ┌─────┐ ┌─────┐       │
              │  │Est.1│ │Est.2│ ...   │
              │  │VMs  │ │VMs  │       │
              │  └─────┘ └─────┘       │
              └─────────────────────────┘
```

### ⚙️ Configuración Específica

**lab.conf - Modo Docente:**
```bash
# VPN habilitado para acceso remoto
vpn[bridged]="true"
vpn[port]="51820:51820/udp"

# Cada estudiante necesita su propio puerto/config
# Ej: estudiante1 → 51820, estudiante2 → 51821, etc.
```

**WireGuard:**
- Generar configuración individual por estudiante (`student1.conf`, `student2.conf`, etc.)
- Distribuir configs de forma segura (email, campus virtual, etc.)
- Cada estudiante usa su propia IP dentro del túnel (10.99.0.2, 10.99.0.3, etc.)

**VNC:**
- Acceso: `192.168.0.2:5901` (dentro de la VPN)
- No exponer VNC directamente a Internet

### 🚀 Instrucciones de Despliegue

```bash
# 1. En el servidor UAH
cd practica3/escenario1/kathara

# 2. Iniciar con VPN habilitada
./start-lab.sh

# 3. Para cada estudiante, generar config VPN
# (El script genera automáticamente student1.conf, etc.)

# 4. Distribuir archivos ./shared/vpn/student*.conf
```

### ⚠️ Consideraciones de Seguridad

- **Firewall**: Solo abrir puerto UDP 51820 (WireGuard) al exterior
- **No exponer**: VNC (5901), HTTP u otros puertos directamente
- **Configs VPN**: Generar con claves únicas por estudiante
- **Rotación**: Cambiar claves WireGuard cada semestre
- **Logs**: Monitorizar conexiones VPN (`wg show`)

---

## Perfil 2: Estudiante - Equipo Local

### 📋 Escenario Típico

- **Infraestructura**: Laptop/PC personal del estudiante
- **Usuarios**: Uso individual, no compartido
- **Propósito**: Desarrollo, pruebas, estudio autónomo
- **Red**: Conexión local o salida a Internet propia

### ❌ ¿Por qué NO usar VPN?

La VPN es **innecesaria y no recomendada** porque:

1. **Todo es local**: Los contenedores ejecutan en tu propia máquina
2. **Sin red externa**: No hay conexión remota que proteger
3. **Acceso directo**: VNC funciona en `localhost:5901`
4. **Menos complejidad**: Un paso menos en la configuración
5. **Menos recursos**: No se ejecuta el contenedor vpn ni wireguard-go

### 🏗️ Arquitectura Local

```
┌─────────────────────────────────────┐
│     PC/Laptop del Estudiante        │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Docker / Kathara       │   │
│  │                             │   │
│  │  ┌─────────┐ ┌─────────┐   │   │
│  │  │ victima │ │atacante │   │   │
│  │  │192.168. │ │192.168. │   │   │
│  │  │  0.2   │ │  0.3   │   │   │
│  │  └────┬────┘ └────┬────┘   │   │
│  │       └─────┬─────┘        │   │
│  │             │              │   │
│  │        [Red LAN]           │   │
│  │       192.168.0.0/24       │   │
│  └─────────────────────────────┘   │
│              │                      │
│         [VNC Viewer]                │
│         localhost:5901              │
└─────────────────────────────────────┘
```

### ⚙️ Configuración Específica

**lab.conf - Modo Estudiante (sin VPN):**
```bash
# Comentar o eliminar sección vpn
# vpn[0]="LAN"
# vpn[image]="kathara-vpn"
# ...

# Modo bridged para salida a Internet
natgw[bridged]="true"
```

**VNC:**
- Acceso directo: `127.0.0.1:5901` o `localhost:5901`
- No necesita túnel VPN

**DNS:**
- Funciona directamente (192.168.0.53 accesible localmente)

### 🚀 Instrucciones de Uso Local

```bash
# 1. Construir imágenes (si no existen)
docker build -t kathara-desktop -f Dockerfile.desktop .
docker build -t kathara-kali -f Dockerfile.kali .
docker build -t kathara-dns -f Dockerfile.dns .
# (kathara-vpn no es necesaria en modo local)

# 2. Iniciar en modo CLI-only (sin VPN)
./start-lab.sh --cli-only

# 3. Acceder a VNC directamente
# Abrir VNC Viewer → localhost:5901
# (o 127.0.0.1:5901)

# 4. Para modo completo (con VPN, si se desea probar):
# ./start-lab.sh  # Pero la VPN solo será útil si accedes desde otra máquina
```

### 💡 Consejos para Uso Local

1. **Recursos**: Asegúrate de tener suficiente RAM (4GB mínimo recomendado)
2. **Docker**: Configurar recursos adecuados en Docker Desktop
3. **Firewall**: Permitir tráfico local entre contenedores
4. **VNC**: Guardar la contraseña (por defecto: "password")
5. **Persistencia**: Usar `./shared/` para guardar archivos entre sesiones

---

## 🇬🇧 English

### Quick Decision Matrix

| Feature | Teacher (Centralized) | Student (Local) |
|---------|----------------------|-----------------|
| Shared server? | ✅ YES | ❌ NO |
| Remote access? | ✅ YES | ❌ NO |
| Use VPN (WireGuard)? | ✅ **YES** | ❌ **NO** |
| VNC via VPN? | ✅ YES | ❌ NO (localhost) |
| Bridged mode? | Optional | Recommended |
| Complexity | Medium | Low |

---

## Profile 1: Teacher - Centralized Platform

### 📋 Typical Scenario

- **Infrastructure**: Lab/department server running Kathara
- **Users**: Multiple students accessing simultaneously
- **Isolation**: Each student has their own isolated environment
- **Access**: From external networks (home, library, campus)

### 🔒 Why USE VPN?

VPN (WireGuard) is **necessary and recommended** because:

1. **Security**: Tunnels connections from untrusted external networks
2. **Isolation**: Separates networks between different students
3. **Remote access**: Allows connection from outside the university
4. **Secure VNC**: Remote desktop travels encrypted through VPN tunnel
5. **Control**: Teacher manages who has access (individual WireGuard configs)

### 🚀 Deployment Instructions

```bash
# 1. On UAH server
cd practica3/escenario1/kathara

# 2. Start with VPN enabled
./start-lab.sh

# 3. Distribute ./shared/vpn/student*.conf files
```

---

## Profile 2: Student - Local Deployment

### 📋 Typical Scenario

- **Infrastructure**: Student's personal laptop/PC
- **Users**: Individual use, not shared
- **Purpose**: Development, testing, self-study
- **Network**: Local connection or own Internet access

### ❌ Why NOT use VPN?

VPN is **unnecessary and not recommended** because:

1. **Everything is local**: Containers run on your own machine
2. **No external network**: No remote connection to protect
3. **Direct access**: VNC works on `localhost:5901`
4. **Less complexity**: One less configuration step
5. **Fewer resources**: No vpn container or wireguard-go running

### 🚀 Local Usage Instructions

```bash
# 1. Build images (if they don't exist)
docker build -t kathara-desktop -f Dockerfile.desktop .
docker build -t kathara-kali -f Dockerfile.kali .
docker build -t kathara-dns -f Dockerfile.dns .
# (kathara-vpn is not needed in local mode)

# 2. Start in CLI-only mode (no VPN)
./start-lab.sh --cli-only

# 3. Access VNC directly
# Open VNC Viewer → localhost:5901
```

---

## Troubleshooting por Perfil

### Docente Centralizado

| Problema | Solución |
|----------|----------|
| Estudiante no puede conectar VPN | Verificar firewall (puerto 51820 UDP abierto) |
| VNC lento | Reducir calidad de conexión, usar compresión |
| Conflictos de IP | Usar rangos diferentes por estudiante (10.99.0.x, 10.99.1.x) |
| WG no handshake | Verificar que estudiante importó config correcta |

### Estudiante Local

| Problema | Solución |
|----------|----------|
| VNC no conecta a localhost | Verificar que victima está corriendo (`kathara list`) |
| Sin salida a Internet | Verificar natgw[bridged]="true" en lab.conf |
| Docker sin espacio | Limpiar imágenes antiguas (`docker system prune`) |
| Lentitud | Aumentar recursos de Docker Desktop |

---

## FAQ / Preguntas Frecuentes

**¿Puedo cambiar de modo (de local a centralizado)?**
SÍ. Modifica lab.conf para añadir/quitar el nodo vpn y reconstruye.

**¿El modo afecta a las herramientas de los contenedores?**
NO. Las herramientas (tcpdump, nmap, etc.) funcionan igual en ambos modos.

**¿Puedo usar el modo docente solo para mí?**
SÍ, pero es innecesario. El modo local es más simple para uso individual.

**¿La VPN consume muchos recursos?**
No mucho (~256MB RAM), pero es un contenedor más ejecutándose.

**¿Qué pasa si olvido la contraseña VNC?**
Por defecto es "password". Se puede cambiar en Dockerfile.desktop.

---

**Nota**: Si tienes dudas sobre qué modo usar, probablemente necesites el **modo estudiante (local)**. El modo docente solo es necesario si despliegas un servidor compartido.

