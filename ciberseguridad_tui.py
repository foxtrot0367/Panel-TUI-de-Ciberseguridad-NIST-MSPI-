#!/usr/bin/env python3
"""
Módulo Textual (TUI) para la Gestión y Administración de Ciberseguridad (NIST / MSPI)
Uso: python ciberseguridad_tui.py
"""

import asyncio
import os
import platform
import sys
from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical, ScrollableContainer
from textual.widgets import Header, Footer, Button, Static, RichLog, TabbedContent, TabPane

# Mapeo de scripts con sus archivos y descripciones NIST/MSPI
SCRIPTS_CONFIG = {
    "waf": {
        "name": "1. Despliegue Caddy WAF",
        "script": "deploy_caddy_waf.sh",
        "nist": "PROTEGER (Protect)",
        "desc": "Instala Caddy, aplica reglas de filtrado WAF, limita métodos HTTP y fuerza HSTS/CSP."
    },
    "audit": {
        "name": "2. Auditoría de Red",
        "script": "red_inspection_audit.sh",
        "nist": "IDENTIFICAR / DETECTAR",
        "desc": "Mapea interfaces IP, puertos TCP/UDP en escucha, reglas iptables y muestrea tráfico."
    },
    "fail2ban": {
        "name": "3. Setup Fail2ban",
        "script": "setup_fail2ban.sh",
        "nist": "DETECTAR / RESPONDER",
        "desc": "Aplica bloqueo dinámico de IPs tras detectar errores recurrentes en logs de Caddy."
    },
    "backup": {
        "name": "4. Respaldo de Sistema",
        "script": "backup_system.sh",
        "nist": "RECUPERAR (Recover)",
        "desc": "Comprime /etc/caddy, /etc/fail2ban, /var/log/caddy y genera firma SHA256."
    },
    "logs": {
        "name": "5. Gestión de Logs",
        "script": "log_storage_management.sh",
        "nist": "GOBERNAR / RECUPERAR",
        "desc": "Rotación, compresión, firmado SHA256 de evidencias y purga automática (>30 días)."
    },
    "diag": {
        "name": "6. Autodiagnóstico",
        "script": "autodiagnostico.sh",
        "nist": "GOBERNAR (Govern)",
        "desc": "Comprueba disponibilidad de la Base de Datos (puerto 5432) y respuesta HTTP del WAF."
    }
}


class ScriptCard(Static):
    """Componente para mostrar cada tarjeta de script con su botón de ejecución."""

    def __init__(self, script_key: str, config: dict, **kwargs):
        super().__init__(**kwargs)
        self.script_key = script_key
        self.config = config

    def compose(self) -> ComposeResult:
        yield Static(f"[bold yellow]{self.config['name']}[/bold yellow]", classes="card-title")
        yield Static(f"[bold cyan]NIST:[/bold cyan] {self.config['nist']}", classes="card-nist")
        yield Static(self.config['desc'], classes="card-desc")
        yield Button("Ejecutar Script", id=f"btn_{self.script_key}", variant="primary")


class CybersecurityTUI(App):
    """Aplicación Textual TUI para Administración de Ciberseguridad NIST/MSPI."""

    CSS = """
    Screen {
        background: $surface-darken-3;
    }

    #sidebar {
        width: 38%;
        height: 100%;
        border-right: heavy $accent;
        padding: 1;
        background: $surface-darken-2;
    }

    #main-panel {
        width: 62%;
        height: 100%;
        padding: 1;
    }

    ScriptCard {
        background: $surface;
        border: solid $accent-lighten-2;
        margin-bottom: 1;
        padding: 1;
        height: auto;
    }

    .card-title {
        text-style: bold;
    }

    .card-nist {
        margin-bottom: 1;
    }

    .card-desc {
        color: $text-muted;
        margin-bottom: 1;
    }

    RichLog {
        background: #0d1117;
        color: #00ff66;
        border: solid $accent;
        height: 100%;
    }

    #status-bar {
        height: 3;
        content-align: center middle;
        background: $primary-darken-2;
        color: $text;
        text-style: bold;
        border: solid $primary;
        margin-bottom: 1;
    }
    """

    TITLE = "Panel TUI de Ciberseguridad NIST/MSPI"
    SUB_TITLE = "Gestión Operativa de Scripts y Controles Tácticos"

    BINDINGS = [
        ("q", "quit", "Salir"),
        ("c", "clear_log", "Limpiar Consola"),
        ("d", "run_all_diag", "Ejecutar Diagnóstico")
    ]

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal():
            with Vertical(id="sidebar"):
                yield Static("[bold green]📜 MÓDULOS DE CONTROL OPERATIVO[/bold green]\n", id="sidebar-header")
                with ScrollableContainer():
                    for key, cfg in SCRIPTS_CONFIG.items():
                        yield ScriptCard(key, cfg)
            
            with Vertical(id="main-panel"):
                yield Static("Estado: Listo para recibir instrucciones.", id="status-bar")
                with TabbedContent():
                    with TabPane("Consola de Salida / Logs"):
                        yield RichLog(id="console_log", highlight=True, markup=True)
                    with TabPane("Matriz de Marco NIST CSF"):
                        yield Static(self._build_nist_matrix())
        yield Footer()

    def _build_nist_matrix(self) -> str:
        return """
[bold yellow]MATRIZ DE COBERTURA NIST CSF / MSPI[/bold yellow]

[bold cyan]1. GOBERNAR (Govern):[/bold cyan]
  • Autodiagnóstico de estado operacional (PostgreSQL & HTTP Status).
  • Gestión de retención de políticas y logs de auditoría.

[bold cyan]2. IDENTIFICAR (Identify):[/bold cyan]
  • Auditoría de interfaz de red, puertos en escucha (`ss`/`netstat`) y firewall (`iptables`).

[bold cyan]3. PROTEGER (Protect):[/bold cyan]
  • Servidor Caddy WAF con mitigación de User-Agents maliciosos, Query Injection y cabeceras HSTS/CSP.

[bold cyan]4. DETECTAR (Detect):[/bold cyan]
  • Captura de tráfico con `tcpdump`.
  • Filtrado de respuestas 400/403/405 en logs de acceso de Caddy.

[bold cyan]5. RESPONDER (Respond):[/bold cyan]
  • Integración de Fail2ban con reglas `iptables-multiport` para baneo automático de IPs atacantes.

[bold cyan]6. RECUPERAR (Recover):[/bold cyan]
  • Creación de respaldos comprimidos de configuración con generación y validación de firma SHA256.
        """

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        button_id = event.button.id
        if button_id.startswith("btn_"):
            script_key = button_id.replace("btn_", "")
            if script_key in SCRIPTS_CONFIG:
                await self.execute_script_task(script_key)

    async def execute_script_task(self, script_key: str):
        config = SCRIPTS_CONFIG[script_key]
        script_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), config["script"])
        log = self.query_one("#console_log", RichLog)
        status = self.query_one("#status-bar", Static)

        status.update(f"[bold yellow]⏳ Ejecutando: {config['name']}...[/bold yellow]")
        log.write(f"\n[bold magenta]====================================================[/bold magenta]")
        log.write(f"[bold cyan][+] INICIANDO PROCESO:[/bold cyan] {config['name']}")
        log.write(f"[bold cyan][+] MARCO NIST/MSPI:[/bold cyan] {config['nist']}")
        log.write(f"[bold cyan][+] SCRIPT:[/bold cyan] {config['script']}")
        log.write(f"[bold magenta]====================================================[/bold magenta]\n")

        is_windows = platform.system() == "Windows"

        if is_windows:
            cmd = ["cmd.exe", "/c", f"echo [WINDOWS ENV] Simulando ejecución de {config['script']} & type \"{script_path}\""]
        else:
            cmd = ["bash", script_path]

        try:
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )

            while True:
                line = await process.stdout.readline()
                if not line:
                    break
                log.write(line.decode('utf-8', errors='replace').rstrip())

            stderr_data = await process.stderr.read()
            if stderr_data:
                log.write(f"[bold red][STDERR][/bold red]\n{stderr_data.decode('utf-8', errors='replace')}")

            await process.wait()

            if process.returncode == 0:
                log.write(f"\n[bold green][✓] {config['name']} procesado correctamente.[/bold green]")
                status.update(f"[bold green]✔ Finalizado: {config['name']}[/bold green]")
            else:
                log.write(f"\n[bold red][✗] Código de retorno: {process.returncode}[/bold red]")
                status.update(f"[bold red]❌ Error en ejecución ({process.returncode})[/bold red]")

        except Exception as e:
            log.write(f"[bold red][EXCEPCIÓN] Error en subproceso: {str(e)}[/bold red]")
            status.update("[bold red]❌ Excepción ocurrida[/bold red]")

    def action_clear_log(self) -> None:
        """Acción para limpiar la pantalla de logs (Tecla 'c')."""
        log = self.query_one("#console_log", RichLog)
        log.clear()
        self.query_one("#status-bar", Static).update("Consola de logs limpiada.")

    async def action_run_all_diag(self) -> None:
        """Acción rápida para ejecutar el autodiagnóstico (Tecla 'd')."""
        await self.execute_script_task("diag")


if __name__ == "__main__":
    app = CybersecurityTUI()
    app.run()