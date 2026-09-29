A continuación tienes el archivo **`README.md`** completo y profesional, estructurado para documentar la instalación, configuración y ejecución de la aplicación TUI en **Windows** y **Linux (Ubuntu/WSL)**.

---
# 🛡️ Módulo Textual de Gestión y Administración de Ciberseguridad (NIST CSF / MSPI)

Sistema de interfaz táctica en terminal (**TUI - Terminal User Interface**) desarrollado en **Python** con la librería **Textual**. Permite administrar, auditar y ejecutar operaciones de ciberseguridad alineadas con las funciones del marco **NIST CSF** y el modelo **MSPI**.
--
## 📋 Mapeo de Módulos y Marcos de Seguridad
| Script / Módulo | Función NIST CSF | Descripción Operativa |
| --- | --- | --- |
| `deploy_caddy_waf.sh` | **PROTEGER (Protect)** | Despliega servidor Caddy WAF con reglas de filtrado de User-Agents maliciosos, Query Injection y cabeceras HSTS/CSP. |
| `red_inspection_audit.sh` | **IDENTIFICAR / DETECTAR** | Audita interfaces de red, puertos TCP/UDP en escucha, reglas de `iptables` y captura tráfico con `tcpdump`. |
| `setup_fail2ban.sh` | **DETECTAR / RESPONDER** | Configura Fail2ban con reglas en `iptables` para el bloqueo dinámico de IPs atacantes tras detectar errores en Caddy WAF. |
| `backup_system.sh` | **RECUPERAR (Recover)** | Genera respaldos comprimidos de configuraciones (`/etc/caddy`, `/etc/fail2ban`) y valida firmas hash **SHA-256**. |
| `log_storage_management.sh` | **GOBERNAR / RECUPERAR** | Rotación, compresión, firmado de logs de auditoría para SIEM y purga de archivos antiguos (>30 días). |
| `autodiagnostico.sh` | **GOBERNAR (Govern)** | Evalúa la salud operativa del sistema comprobando la conexión a la Base de Datos (PostgreSQL:5432) y la respuesta del WAF. |
---
## 🛠️ Requisitos Previos

* **Python:** Versión `3.10` o superior (compatible con Python `3.14`).
* **Librerías Python:** `textual` y `rich`.
* **Entorno de Ejecución Real:** Linux (Ubuntu 20.04/22.04/24.04 o Debian) o **WSL2** en Windows.
* **Entorno de Prueba/Demostración:** Windows nativo (PowerShell) con simulación de subprocesos.
---
## 🚀 Guía de Instalación y Ejecución

### Opción A: Ejecución en Windows (Modo Demostración / Simulación TUI)

Si estás probando la interfaz gráfica directamente en Windows mediante PowerShell:

1. **Clonar o ingresar al directorio del proyecto:**
```powershell
cd C:\Users\USUARIO\Desktop\ciberseguridad_tui

```


2. **Instalar las dependencias de Python:**
```powershell
python -m pip install textual rich

```

3. **Ejecutar la aplicación TUI:**
```powershell
python ciberseguridad_tui.py

```


*(En Windows, la TUI detectará el sistema operativo y mostrará la simulación del script sin fallar por falta de comandos Bash).*
---
### Opción B: Ejecución en Linux / Windows Subsystem for Linux (WSL2) *(Entorno Producción/Real)*

Dado que los scripts de seguridad interactúan con el kernel de Linux (`iptables`, `systemctl`, `caddy`, `fail2ban`), para la ejecución real se requiere un entorno Bash con privilegios de superusuario.

1. **Abrir la terminal de Linux o WSL:**
```bash
# En Windows PowerShell, puedes acceder a WSL escribiendo:
wsl

```


2. **Navegar a la carpeta del proyecto:**
```bash
cd /mnt/c/Users/USUARIO/Desktop/ciberseguridad_tui

```


3. **Instalar dependencias de Python en Linux:**
```bash
sudo apt update && sudo apt install -y python3 python3-pip
pip3 install textual rich

```


4. **Otorgar permisos de ejecución a los scripts de Bash:**
```bash
chmod +x *.sh
```

5. **Iniciar el panel con privilegios elevados (`sudo`):**
```bash
sudo python3 ciberseguridad_tui.py

```
---

## ⌨️ Controles y Teclas de Acceso Rápido

* **Ratón:** Haz clic directamente sobre el botón **"Ejecutar Script"** en cualquiera de las tarjetas laterales.
* **`D`**: Dispara automáticamente el **Autodiagnóstico de Sistema y BD** (`autodiagnostico.sh`).
* **`C`**: Limpia los logs acumulados en la consola en pantalla.
* **`Q`**: Cierra y sale de la aplicación TUI.
---

## 📁 Estructura del Proyecto

```text
ciberseguridad_tui/
├── ciberseguridad_tui.py       # Aplicación principal Textual (TUI)
├── deploy_caddy_waf.sh         # Script 1: Despliegue de WAF y cabeceras
├── red_inspection_audit.sh     # Script 2: Auditoría de red e inspección
├── setup_fail2ban.sh           # Script 3: Configuración de Fail2ban
├── backup_system.sh            # Script 4: Copias de seguridad y firmas SHA256
├── log_storage_management.sh   # Script 5: Gestión de retención de logs
├── autodiagnostico.sh          # Script 6: Comprobación de salud de BD y WAF
└── README.md                   # Documentación del proyecto

```
