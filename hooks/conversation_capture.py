#!/usr/bin/env python3
"""Claude Code Stop Hook — Captura conversaciones al vault de Obsidian

Se ejecuta despues de cada respuesta de Claude (evento Stop).
Escribe/sobreescribe el .md de la sesion actual en:
  vault / 01 Growth Engine / Infraestructura IA / Claude Code / Conversaciones / {fecha} /

CONFIGURAR: editar las variables de la seccion CONFIG antes de usar.
"""

import sys
import json
import os
import re
from pathlib import Path
from datetime import datetime, timezone

# ============================================================
# CONFIG — adaptar a tu entorno
# ============================================================
VAULT = "/ruta/a/tu/vault"
CONVERSACIONES_DIR = f"{VAULT}/01 Growth Engine/Infraestructura IA/Claude Code/Conversaciones"
CLAUDE_PROJECTS = os.path.expanduser("~/.claude/projects")
NOMBRE_USUARIO = "Usuario"   # ← tu nombre, aparece en los logs
# ============================================================


def leer_stdin():
    try:
        raw = sys.stdin.read()
        if raw.strip():
            return json.loads(raw)
        return {}
    except Exception:
        return {}


def encontrar_jsonl(data, session_id):
    tp = data.get("transcript_path")
    if tp:
        p = Path(tp)
        if p.exists():
            return p

    if not session_id:
        return None

    for project_dir in Path(CLAUDE_PROJECTS).iterdir():
        if not project_dir.is_dir():
            continue
        jsonl = project_dir / f"{session_id}.jsonl"
        if jsonl.exists():
            return jsonl

    return None


def extraer_texto(content):
    if isinstance(content, str):
        text = re.sub(r'<[^>]+>[\s\S]*?</[^>]+>', '', content)
        text = re.sub(r'<[^>]+/>', '', text)
        return text.strip()
    elif isinstance(content, list):
        partes = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                partes.append(item.get("text", "").strip())
        return "\n".join(p for p in partes if p)
    return ""


def es_mensaje_real_usuario(linea):
    if linea.get("isMeta"):
        return False
    content = linea.get("message", {}).get("content", "")
    texto = extraer_texto(content)
    if not texto:
        return False
    if re.match(r'^\s*<', texto):
        return False
    return True


def parsear_sesion(jsonl_path):
    lineas_raw = []
    with open(jsonl_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                lineas_raw.append(json.loads(line))
            except Exception:
                continue

    turns = []
    herramientas_globales = set()
    i = 0

    while i < len(lineas_raw):
        linea = lineas_raw[i]

        if linea.get("type") == "user" and es_mensaje_real_usuario(linea):
            texto_user = extraer_texto(linea.get("message", {}).get("content", ""))
            ts_user = linea.get("timestamp", "")

            texto_claude = ""
            tools_turn = []
            j = i + 1

            while j < len(lineas_raw):
                siguiente = lineas_raw[j]
                tipo_sig = siguiente.get("type")

                if tipo_sig == "assistant":
                    content = siguiente.get("message", {}).get("content", [])
                    t = extraer_texto(content)
                    if t and not texto_claude:
                        texto_claude = t
                    if isinstance(content, list):
                        for item in content:
                            if isinstance(item, dict) and item.get("type") == "tool_use":
                                nombre_tool = item.get("name", "")
                                if nombre_tool:
                                    tools_turn.append(nombre_tool)
                                    herramientas_globales.add(nombre_tool)
                    j += 1
                elif tipo_sig == "user" and es_mensaje_real_usuario(siguiente):
                    break
                else:
                    j += 1

            turns.append({
                "timestamp": ts_user,
                "user": texto_user,
                "claude": texto_claude,
                "tools": tools_turn,
            })
            i = j

        else:
            i += 1

    return turns, sorted(herramientas_globales)


def limpiar_nombre_archivo(texto, max_palabras=5):
    texto = re.sub(r'[<>:"/\\|?*\n\r\t]', ' ', texto)
    palabras = texto.split()[:max_palabras]
    nombre = " ".join(palabras)
    return nombre[:60].strip() if nombre else "Sin titulo"


def ts_a_datetime(ts_str):
    try:
        dt_utc = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        return dt_utc.astimezone()
    except Exception:
        return datetime.now().astimezone()


def construir_markdown(session_id, cwd, turns, herramientas, dt_inicio):
    proyecto = Path(cwd).name if cwd else "desconocido"
    fecha = dt_inicio.strftime("%Y-%m-%d")
    hora = dt_inicio.strftime("%H:%M")

    frontmatter = f"""---
titulo: "Conversacion {hora} — {proyecto}"
tipo: conversacion
departamento: infra-ia
actualizado: {fecha}
autor: fate
session_id: {session_id}
proyecto: {cwd}
turns: {len(turns)}
herramientas_usadas: [{", ".join(herramientas)}]
---"""

    secciones = []
    for num, turn in enumerate(turns, 1):
        dt = ts_a_datetime(turn["timestamp"])
        hora_turn = dt.strftime("%H:%M:%S")

        bloque = f"## Turn {num} — {hora_turn}\n\n**{NOMBRE_USUARIO}:** {turn['user']}"

        if turn["claude"]:
            bloque += f"\n\n**Claude:** {turn['claude']}"

        if turn["tools"]:
            bloque += f"\n\n_Herramientas: {', '.join(turn['tools'])}_"

        secciones.append(bloque)

    cuerpo = "\n\n---\n\n".join(secciones) if secciones else "_Sin turns registrados_"
    return frontmatter + "\n\n" + cuerpo


def main():
    data = leer_stdin()

    session_id = (
        data.get("session_id")
        or os.environ.get("CLAUDE_SESSION_ID", "")
    )
    cwd = (
        data.get("cwd")
        or os.environ.get("PWD", "")
    )

    if not session_id:
        print(json.dumps({}))
        return

    jsonl_path = encontrar_jsonl(data, session_id)
    if not jsonl_path:
        print(json.dumps({}))
        return

    try:
        turns, herramientas = parsear_sesion(jsonl_path)
    except Exception:
        print(json.dumps({}))
        return

    if not turns:
        print(json.dumps({}))
        return

    dt_inicio = ts_a_datetime(turns[0]["timestamp"])
    primer_texto = turns[0]["user"]
    nombre_corto = limpiar_nombre_archivo(primer_texto, max_palabras=5)

    hora_str = dt_inicio.strftime("%H-%M")
    session_short = session_id[:6] if session_id else "??????"
    nombre_archivo = f"{hora_str} - {session_short} - {nombre_corto}.md"

    fecha_str = dt_inicio.strftime("%Y-%m-%d")
    carpeta_dia = Path(CONVERSACIONES_DIR) / fecha_str
    carpeta_dia.mkdir(parents=True, exist_ok=True)

    markdown = construir_markdown(session_id, cwd, turns, herramientas, dt_inicio)
    archivo_destino = carpeta_dia / nombre_archivo
    archivo_destino.write_text(markdown, encoding="utf-8")

    print(json.dumps({}))


if __name__ == "__main__":
    main()
