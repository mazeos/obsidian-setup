#!/usr/bin/env python3
"""Claude Code PostToolUse Hook — Sync inmediato de memoria a Obsidian

Se ejecuta cada vez que Claude escribe o edita un archivo de memoria.
Si el archivo pertenece al directorio de memoria de Claude Code,
lo copia automaticamente al vault de Obsidian.

CONFIGURAR: editar las variables de la seccion CONFIG antes de usar.
"""

import sys
import json
from pathlib import Path

# ============================================================
# CONFIG — adaptar a tu entorno
# ============================================================
MEMORY_DIR   = "/Users/{tu-usuario}/.claude/projects/{project-id}/memory"
OBSIDIAN_DIR = "/ruta/a/tu/vault/00 Agentes/{Tu-Agente}/Memoria"
# ============================================================


def main():
    try:
        data = json.loads(sys.stdin.read())
    except Exception:
        return

    file_path = (
        data.get("tool_input", {}).get("file_path")
        or data.get("tool_input", {}).get("path")
        or ""
    )

    if not file_path:
        return

    src = Path(file_path)

    if not src.suffix == ".md":
        return

    try:
        src.relative_to(MEMORY_DIR)
    except ValueError:
        return

    if not src.exists():
        return

    dest = Path(OBSIDIAN_DIR) / src.name
    Path(OBSIDIAN_DIR).mkdir(parents=True, exist_ok=True)
    dest.write_text(src.read_text(encoding="utf-8"), encoding="utf-8")


if __name__ == "__main__":
    main()
