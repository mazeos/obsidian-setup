# Setup Completo — Claude Code + Obsidian

Guía para replicar desde cero la integración entre Claude Code y un vault de Obsidian con sincronización automática de memoria, contexto persistente entre sesiones y archivo de conversaciones.

---

## Paso 0 — Auditoría previa

Antes de instalar nada, verificar qué tienes y qué falta.

### Checklist Mac

Abrir Terminal y correr cada comando:

```bash
# 1. Claude Code
claude --version
# Si falla → ir a Sección 1-A

# 2. Python 3
python3 --version
# Necesitas 3.8 o superior. Si falla → ir a Sección 1-B

# 3. Node.js y npm (para el MCP de Obsidian)
node --version
npm --version
# Si falla → ir a Sección 1-C

# 4. Git
git --version
# Si falla → ir a Sección 1-D

# 5. Obsidian instalado
ls /Applications/Obsidian.app
# Si falla → ir a Sección 1-E

# 6. Vault sincronizado (ajustar ruta si es distinta)
ls ~/Documents/Fate\ Vault/_Sistema/REGLAS.md
# Si falla → el vault no está sincronizado en este Mac

# 7. Claude Code CLI autenticado
claude mcp list
# Si pide login → correr: claude login
```

### Checklist Windows

Abrir PowerShell y correr:

```powershell
# 1. Claude Code
claude --version
# Si falla → ir a Sección 1-A

# 2. Python
python --version
# Necesitas 3.8 o superior. Si falla → ir a Sección 1-B

# 3. Node.js y npm
node --version
npm --version
# Si falla → ir a Sección 1-C

# 4. Git
git --version
# Si falla → ir a Sección 1-D

# 5. Obsidian instalado
Test-Path "$env:LOCALAPPDATA\Obsidian\Obsidian.exe"
# O buscar Obsidian en el menú de inicio

# 6. Vault sincronizado (ajustar ruta si es distinta)
Test-Path "$env:USERPROFILE\Documents\Fate Vault\_Sistema\REGLAS.md"
# Si es False → el vault no está sincronizado en este equipo

# 7. Claude Code autenticado
claude mcp list
# Si pide login → correr: claude login
```

---

## Sección 1 — Instalación de dependencias

### 1-A Claude Code

**Mac:**
```bash
npm install -g @anthropic-ai/claude-code
# O con Homebrew:
brew install claude-code
```

**Windows:**
```powershell
npm install -g @anthropic-ai/claude-code
```

Luego autenticarse:
```bash
claude login
```

---

### 1-B Python 3

**Mac:**
Python 3 viene preinstalado en macOS 12+. Si no está disponible:
```bash
brew install python3
```

**Windows:**
Descargar el instalador desde https://python.org/downloads
- Marcar la casilla **"Add Python to PATH"** durante la instalación
- Verificar con: `python --version`

---

### 1-C Node.js

**Mac:**
```bash
brew install node
```

**Windows:**
Descargar desde https://nodejs.org (versión LTS recomendada)

---

### 1-D Git

**Mac:**
```bash
brew install git
# O simplemente correr 'git' — Mac ofrece instalar Xcode Command Line Tools
```

**Windows:**
Descargar desde https://git-scm.com/download/win

---

### 1-E Obsidian

Descargar desde https://obsidian.md

Luego activar **Obsidian Sync** en Settings → Sync y esperar a que el vault termine de sincronizar antes de continuar.

---

## Paso 2 — Plugin Local REST API en Obsidian

Este plugin expone el vault vía API local para que el MCP de Claude Code pueda leer y escribir en él.

1. Abrir Obsidian → **Settings → Community Plugins**
2. Desactivar "Safe mode" si está activo
3. Buscar **"Local REST API"** → Instalar → Activar
4. Ir a la configuración del plugin → copiar el **API Key** generado
5. Anotar también el puerto (por defecto: `27123`)

> El plugin debe estar activo (Obsidian abierto) para que el MCP funcione.

---

## Paso 3 — Configurar el MCP de Obsidian en Claude Code

El MCP permite que Claude Code lea y escriba en el vault usando comandos de lenguaje natural.

### Mac

Editar `~/.claude.json` y agregar dentro del objeto `mcpServers`:

```json
"obsidian": {
  "command": "npx",
  "args": ["-y", "mcp-obsidian"],
  "env": {
    "OBSIDIAN_API_KEY": "PEGAR_API_KEY_AQUI",
    "OBSIDIAN_HOST": "127.0.0.1",
    "OBSIDIAN_PORT": "27123"
  }
}
```

### Windows

```json
"obsidian": {
  "command": "npx",
  "args": ["-y", "mcp-obsidian"],
  "env": {
    "OBSIDIAN_API_KEY": "PEGAR_API_KEY_AQUI",
    "OBSIDIAN_HOST": "127.0.0.1",
    "OBSIDIAN_PORT": "27123"
  }
}
```

Verificar que conecta (con Obsidian abierto):
```bash
claude mcp list
```
Debe aparecer `obsidian` con estado `Connected`.

---

## Paso 4 — Instalar hooks y skill

### Mac

```bash
# Clonar el repo
git clone https://github.com/mazeos/obsidian-setup.git
cd obsidian-setup

# Crear carpetas necesarias
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/skills/fate-vault-guardian

# Copiar hooks
cp hooks/*.py ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.py

# Copiar skill
cp fate-vault-guardian/SKILL.md ~/.claude/skills/fate-vault-guardian/
```

### Windows (PowerShell)

```powershell
# Clonar el repo
git clone https://github.com/mazeos/obsidian-setup.git
cd obsidian-setup

# Crear carpetas necesarias
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\hooks"
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills\fate-vault-guardian"

# Copiar hooks
Copy-Item hooks\*.py "$env:USERPROFILE\.claude\hooks\"

# Copiar skill
Copy-Item fate-vault-guardian\SKILL.md "$env:USERPROFILE\.claude\skills\fate-vault-guardian\"
```

---

## Paso 5 — Adaptar rutas en los hooks

Cada archivo `.py` tiene una sección `# CONFIG` al inicio. Editar las 4 variables en cada uno.

### Encontrar tus rutas

**Mac:**
```bash
# Ruta del vault
echo ~/Documents/Fate\ Vault

# Ruta de memoria de Claude Code
# El ID de proyecto depende de desde dónde abres Claude Code.
# Si lo abres desde tu home (~), el ID es: -Users-{tu-usuario}
ls ~/.claude/projects/
# Busca la carpeta que dice -Users-{tu-usuario}
# La ruta completa sería:
echo ~/.claude/projects/-Users-$(whoami)/memory
```

**Windows (PowerShell):**
```powershell
# Ruta del vault
"$env:USERPROFILE\Documents\Fate Vault"

# Ruta de memoria de Claude Code
# Listar proyectos para encontrar el ID correcto
Get-ChildItem "$env:USERPROFILE\.claude\projects\"
# Buscar la carpeta que corresponde a tu directorio de trabajo
# Generalmente: -C-Users-{tu-usuario}
```

### Tabla de variables a editar

| Variable | Mac | Windows |
|---|---|---|
| `VAULT` | `/Users/{usuario}/Documents/Fate Vault` | `C:\Users\{usuario}\Documents\Fate Vault` |
| `MEMORY_SOURCE_DIR` | `/Users/{usuario}/.claude/projects/-Users-{usuario}/memory` | `C:\Users\{usuario}\.claude\projects\-C-Users-{usuario}\memory` |
| `MEMORIA_OBSIDIAN` | `{VAULT}/00 Agentes/F.A.T.E/Memoria` | `{VAULT}\00 Agentes\F.A.T.E\Memoria` |
| `NOMBRE_USUARIO` | Tu nombre | Tu nombre |

### Editar en Mac

```bash
# Editar cada archivo (usar nano, vim o cualquier editor)
nano ~/.claude/hooks/obsidian_start_hook.py
nano ~/.claude/hooks/obsidian_memory_sync.py
nano ~/.claude/hooks/obsidian_session_end_hook.py
nano ~/.claude/hooks/conversation_capture.py
```

### Editar en Windows

```powershell
# Abrir con Notepad (o VS Code si está instalado)
notepad "$env:USERPROFILE\.claude\hooks\obsidian_start_hook.py"
notepad "$env:USERPROFILE\.claude\hooks\obsidian_memory_sync.py"
notepad "$env:USERPROFILE\.claude\hooks\obsidian_session_end_hook.py"
notepad "$env:USERPROFILE\.claude\hooks\conversation_capture.py"
```

---

## Paso 6 — Configurar settings.json

### Mac

```bash
cp obsidian-setup/settings-template.json ~/.claude/settings.json
```

Editar el archivo y reemplazar `{tu-usuario}` con tu usuario de Mac.

Si ya tienes un `settings.json` con otra configuración, agregar solo el bloque `"hooks"` manualmente.

### Windows

Crear o editar `C:\Users\{usuario}\.claude\settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python C:\\Users\\{usuario}\\.claude\\hooks\\obsidian_start_hook.py",
            "timeout": 30,
            "statusMessage": "Cargando contexto desde vault..."
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "python C:\\Users\\{usuario}\\.claude\\hooks\\obsidian_memory_sync.py",
            "timeout": 10,
            "async": true
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python C:\\Users\\{usuario}\\.claude\\hooks\\conversation_capture.py",
            "timeout": 15,
            "async": true
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python C:\\Users\\{usuario}\\.claude\\hooks\\obsidian_session_end_hook.py",
            "timeout": 30,
            "statusMessage": "Guardando en vault..."
          }
        ]
      }
    ]
  }
}
```

> En Windows usar `python` en lugar de `/usr/bin/python3`.

---

## Paso 7 — Configurar CLAUDE.md global

Crear `~/.claude/CLAUDE.md` (Mac) o `C:\Users\{usuario}\.claude\CLAUDE.md` (Windows):

```markdown
## Vault de Obsidian
El vault está en `/ruta/a/tu/Fate Vault/` (ajustar).
Es la fuente de verdad del negocio. Leer _Sistema/REGLAS.md antes de cualquier operación.

## Guardian del vault
Cada vez que se crea, edita, mueve o elimina un archivo .md en el vault,
leer y aplicar el skill `fate-vault-guardian`.

## Comportamiento general
- Respuestas cortas y directas
- Verificar el estado actual antes de hacer suposiciones
- Ante una tarea ambigua, hacer UNA pregunta concreta
```

---

## Paso 8 — Adaptar el skill

Editar `~/.claude/skills/fate-vault-guardian/SKILL.md` y cambiar:

```
VAULT_PATH: /ruta/a/tu/vault/
VAULT_MCP_NAME: nombre-del-vault-en-el-mcp
```

El nombre del vault en el MCP es el que configuraste en la sección de Obsidian del plugin Local REST API. Por defecto usa el nombre del vault tal como aparece en Obsidian.

---

## Paso 9 — Verificación final

Abrir Claude Code desde el directorio home:

**Mac:** `cd ~ && claude`
**Windows:** `cd $env:USERPROFILE && claude`

Al iniciar debe aparecer el mensaje:
```
Cargando contexto desde vault...
```

Para confirmar que el MCP funciona, escribir en Claude Code:
```
¿Puedes leer _Sistema/REGLAS.md del vault?
```

Si responde con el contenido de las reglas, todo está funcionando.

---

## Resolución de problemas

### "Cargando contexto..." no aparece
- Verificar que `settings.json` tiene el bloque `hooks` correcto
- Verificar que el path al script en `settings.json` es correcto
- Probar el script manualmente: `python3 ~/.claude/hooks/obsidian_start_hook.py`

### MCP de Obsidian no conecta
- Confirmar que Obsidian está abierto
- Confirmar que el plugin Local REST API está activo
- Verificar el API Key y el puerto en `~/.claude.json`

### Memoria no se sincroniza a Obsidian
- Verificar que `MEMORY_SOURCE_DIR` apunta a la carpeta correcta
- Listar `~/.claude/projects/` para confirmar el ID de proyecto
- El sync solo ocurre con archivos `.md` dentro del directorio de memoria

### En Windows: error al ejecutar los hooks
- Verificar que Python está en el PATH: `python --version`
- Si Python no se encuentra, usar la ruta completa: `where python` y usar esa ruta en `settings.json`

### El project ID no existe todavía
La carpeta de memory se crea la primera vez que Claude Code guarda algo. Si no existe, abrir Claude Code, escribir algo, y luego verificar que la carpeta fue creada.
