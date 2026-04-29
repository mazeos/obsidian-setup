# Hooks — Claude Code + Obsidian Sync

Estos hooks conectan Claude Code con un vault de Obsidian para que el agente tenga contexto persistente entre sesiones y todas las conversaciones queden archivadas automaticamente.

## Como funciona

```
SessionStart  → obsidian_start_hook.py     → carga contexto del vault al inicio
PostToolUse   → obsidian_memory_sync.py    → sincroniza memoria en tiempo real
Stop          → conversation_capture.py    → archiva la conversacion en el vault
SessionEnd    → obsidian_session_end_hook.py → sync final de memoria + MCPs
```

## Instalacion

### 1. Copiar los hooks

```bash
cp hooks/*.py ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.py
```

### 2. Adaptar las rutas

En cada archivo `.py` hay una seccion `# CONFIG` al inicio. Editar:

- `VAULT` → ruta absoluta a tu vault de Obsidian
- `MEMORY_SOURCE_DIR` → ruta a tu directorio de memoria de Claude Code (`~/.claude/projects/{id}/memory`)
- `OBSIDIAN_DIR` / `MEMORIA_OBSIDIAN` → donde guardar la memoria dentro del vault
- `NOMBRE_USUARIO` → tu nombre (aparece en los logs de conversacion)

### 3. Configurar settings.json

Agregar los hooks a `~/.claude/settings.json`. Ver el archivo `settings-template.json` en la raiz del repo.

## Que hace cada hook

### `obsidian_start_hook.py` (SessionStart)
Lee archivos clave del vault al iniciar cada sesion y los inyecta como contexto. Claude "sabe" el estado del negocio desde el primer mensaje sin que tengas que explicar nada.

Configura que archivos quieres cargar en `ARCHIVOS_CONTEXTO`. Puedes apuntar a archivos individuales o a directorios completos (con el marcador `"__DIR__"`).

### `obsidian_memory_sync.py` (PostToolUse)
Cada vez que Claude escribe un archivo `.md` en tu directorio de memoria, lo copia automaticamente al vault de Obsidian. La memoria de Claude y Obsidian siempre estan sincronizadas.

### `conversation_capture.py` (Stop)
Despues de cada respuesta, captura la conversacion completa y la guarda como `.md` en el vault, organizada por fecha. Util para revisar sesiones pasadas y para que el `SessionStart` pueda cargar conversaciones recientes como contexto.

### `obsidian_session_end_hook.py` (SessionEnd)
Al cerrar la sesion, hace una sincronizacion final de todos los archivos de memoria y actualiza el listado de MCPs activos en el vault.

## Requisitos

- Python 3.8+
- Claude Code con soporte de hooks (settings.json)
- Vault de Obsidian con estructura compatible (ver `fate-vault-guardian/`)
