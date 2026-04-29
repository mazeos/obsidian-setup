#!/usr/bin/env python3
"""Claude Code SessionEnd Hook — Sincronizacion final con vault de Obsidian

Corre al cerrar cada sesion de Claude Code.
Responsabilidades:
1. Sincronizar archivos de memoria → vault/00 Agentes/{Agente}/Memoria/
2. Sincronizar MCPs activos → vault/05 Credenciales/Servicios.md

CONFIGURAR: editar las variables de la seccion CONFIG antes de usar.
"""

import sys
import json
import os
from datetime import datetime
from pathlib import Path

# ============================================================
# CONFIG — adaptar a tu entorno
# ============================================================
VAULT              = "/ruta/a/tu/vault"
MEMORIA_OBSIDIAN   = f"{VAULT}/00 Agentes/{{Tu-Agente}}/Memoria"
CREDENCIALES_FILE  = f"{VAULT}/05 Credenciales/Servicios.md"
MEMORY_SOURCE_DIR  = "/Users/{tu-usuario}/.claude/projects/{project-id}/memory"
# ============================================================


def leer_stdin():
    try:
        raw = sys.stdin.read()
        if raw.strip():
            return json.loads(raw)
    except Exception:
        pass
    return {}


def fecha_corta():
    return datetime.now().strftime("%Y-%m-%d %H:%M")


def sincronizar_memoria():
    source = Path(MEMORY_SOURCE_DIR)
    if not source.exists():
        return 0

    Path(MEMORIA_OBSIDIAN).mkdir(parents=True, exist_ok=True)

    copiados = 0
    for archivo in source.glob("*.md"):
        destino = Path(MEMORIA_OBSIDIAN) / archivo.name
        contenido_source = archivo.read_text(encoding="utf-8")

        if destino.exists():
            if destino.read_text(encoding="utf-8") == contenido_source:
                continue

        destino.write_text(contenido_source, encoding="utf-8")
        copiados += 1

    return copiados


def sincronizar_mcps():
    import subprocess
    import re

    try:
        result = subprocess.run(
            ["claude", "mcp", "list"],
            capture_output=True, text=True, timeout=30
        )
        output = result.stdout or ""
    except Exception:
        output = ""

    if not output.strip():
        return False

    filas = []
    for linea in output.splitlines():
        linea = linea.strip()
        if not linea or linea.startswith("Checking"):
            continue

        estado = "✓" if "Connected" in linea else ("⚠️" if "Needs auth" in linea else "✗")

        match = re.match(r'^(.+?):\s+(.+?)\s+-\s+', linea)
        if match:
            nombre = match.group(1).strip()
            ubicacion = match.group(2).strip()
            tipo = "remoto (SSE)" if ubicacion.startswith("http") else "local"
            filas.append(f"| `{nombre}` | {tipo} | `{ubicacion}` | {estado} |")

    if not filas:
        return False

    tabla = "\n".join(filas)
    nueva_seccion = f"""## MCPs Configurados (auto-sync)

> Ultima sincronizacion: {fecha_corta()}

| Nombre | Tipo | Ubicacion / URL | Estado |
|--------|------|-----------------|--------|
{tabla}"""

    cred_path = Path(CREDENCIALES_FILE)
    if not cred_path.exists():
        return False

    contenido = cred_path.read_text(encoding="utf-8")
    MARCA = "## MCPs Configurados (auto-sync)"

    if MARCA in contenido:
        inicio = contenido.index(MARCA)
        resto = contenido[inicio + len(MARCA):]
        siguiente = resto.find("\n## ")
        if siguiente != -1:
            fin = inicio + len(MARCA) + siguiente
            contenido = contenido[:inicio] + nueva_seccion + contenido[fin + 1:]
        else:
            contenido = contenido[:inicio] + nueva_seccion
    else:
        contenido = contenido.rstrip() + "\n\n" + nueva_seccion

    cred_path.write_text(contenido, encoding="utf-8")
    return True


def main():
    datos = leer_stdin()
    resultados = []

    try:
        copiados = sincronizar_memoria()
        if copiados > 0:
            resultados.append(f"{copiados} archivos de memoria sincronizados")
    except Exception as e:
        resultados.append(f"Error sync memoria: {e}")

    try:
        if sincronizar_mcps():
            resultados.append("MCPs actualizados en Servicios.md")
    except Exception as e:
        resultados.append(f"Error sync MCPs: {e}")

    resumen = " | ".join(resultados) if resultados else "Sin cambios"

    print(json.dumps({
        "systemMessage": f"Vault sincronizado — {resumen}"
    }))


if __name__ == "__main__":
    main()
