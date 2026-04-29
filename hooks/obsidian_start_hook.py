#!/usr/bin/env python3
"""Claude Code SessionStart Hook — Carga contexto desde vault de Obsidian

Corre al inicio de cada sesion de Claude Code.
Inyecta como contexto el contenido clave del vault para que
Claude tenga el estado completo del negocio desde el primer mensaje.

CONFIGURAR: editar las variables de la seccion CONFIG antes de usar.
"""

import sys
import json
from pathlib import Path
from datetime import datetime, timedelta, timezone

# ============================================================
# CONFIG — adaptar a tu entorno
# ============================================================
VAULT = "/ruta/a/tu/vault"                        # ← tu ruta
CONVERSACIONES_DIR = f"{VAULT}/01 Growth Engine/Infraestructura IA/Claude Code/Conversaciones"

# Archivos a leer y exponer como contexto (en orden de prioridad)
# El marcador "__DIR__" lee todo el directorio recursivamente
ARCHIVOS_CONTEXTO = [
    (f"{VAULT}/_Sistema/REGLAS.md",                          "Reglas del Vault"),
    (f"{VAULT}/_Sistema/MAPA.md",                            "Mapa del Vault"),
    (f"{VAULT}/00 Agentes/Sistema de Agentes.md",            "Sistema de Agentes"),
    (f"{VAULT}/01 Growth Engine/Growth Engine.md",            "Growth Engine Dashboard"),
    (f"{VAULT}/05 Credenciales/Servicios.md",                "Servicios y Credenciales"),
    (f"{VAULT}/02 Clientes/Consultoria",                     "__DIR__"),
]
# ============================================================


def leer_archivo(path: str):
    try:
        return Path(path).read_text(encoding="utf-8").strip()
    except Exception:
        return None


def leer_directorio(path: str) -> str:
    """Lee todos los .md de un directorio recursivamente y los concatena."""
    partes = []
    carpeta = Path(path)
    if not carpeta.exists():
        return ""
    for archivo in sorted(carpeta.rglob("*.md")):
        if archivo.name.startswith("_"):
            continue
        contenido = leer_archivo(str(archivo))
        if contenido:
            rel = archivo.relative_to(carpeta)
            partes.append(f"### {rel.stem}\n{contenido[:500]}")
    return "\n\n".join(partes)


def cargar_conversaciones_recientes() -> str:
    """Carga las ultimas 3 conversaciones (hoy + ayer) como contexto."""
    hoy = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    ayer = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d")

    archivos = []
    for fecha in [hoy, ayer]:
        carpeta = Path(CONVERSACIONES_DIR) / fecha
        if carpeta.exists():
            for md in sorted(carpeta.glob("*.md"), reverse=True):
                archivos.append(md)

    archivos = archivos[:3]

    partes = []
    for md in reversed(archivos):
        contenido = leer_archivo(str(md))
        if not contenido:
            continue
        lineas = contenido.splitlines()[:300]
        partes.append(f"### {md.stem}\n" + "\n".join(lineas))

    if not partes:
        return ""

    return "## Conversaciones Recientes\n\n" + "\n\n---\n\n".join(partes)


def main():
    secciones = []

    for ruta, etiqueta in ARCHIVOS_CONTEXTO:
        if etiqueta == "__DIR__":
            nombre_dir = Path(ruta).name
            contenido = leer_directorio(ruta)
            if contenido:
                secciones.append(f"## {nombre_dir}\n\n{contenido}")
        else:
            contenido = leer_archivo(ruta)
            if contenido:
                secciones.append(f"## {etiqueta}\n\n{contenido}")

    conv_recientes = cargar_conversaciones_recientes()
    if conv_recientes:
        secciones.append(conv_recientes)

    if not secciones:
        print(json.dumps({}))
        return

    contexto = (
        "# Contexto cargado desde Fate Vault\n\n"
        + "\n\n---\n\n".join(secciones)
    )

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": contexto
        }
    }))


if __name__ == "__main__":
    main()
