# ============================================================
# install.ps1 — Setup automático Claude Code + Obsidian (Windows)
# https://github.com/mazeos/obsidian-setup
#
# Uso (PowerShell como Administrador):
#   irm https://raw.githubusercontent.com/mazeos/obsidian-setup/main/install.ps1 | iex
# ============================================================

$ErrorActionPreference = "Stop"
$REPO = "https://github.com/mazeos/obsidian-setup.git"
$CLAUDE_DIR = "$env:USERPROFILE\.claude"
$TEMP_DIR = [System.IO.Path]::GetTempPath() + "obsidian-setup-" + [System.Guid]::NewGuid().ToString("N")

function Write-Ok   { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Err  { param($msg) Write-Host "  [X] $msg" -ForegroundColor Red }
function Write-Step { param($msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ask  { param($msg) Write-Host "`n$msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "================================================" -ForegroundColor White
Write-Host "  Claude Code + Obsidian -- Setup Automatico    " -ForegroundColor White
Write-Host "================================================" -ForegroundColor White
Write-Host ""

# ============================================================
# PASO 1 — Auditoría de dependencias
# ============================================================
Write-Step "Verificando dependencias..."

$errores = 0

function Check-Dep {
  param($name, $cmd, $hint)
  try {
    $ver = & $cmd --version 2>&1 | Select-Object -First 1
    Write-Ok "$name`: $ver"
  } catch {
    Write-Err "$name no encontrado. $hint"
    $script:errores++
  }
}

Check-Dep "Claude Code" "claude" "Instalar: npm install -g @anthropic-ai/claude-code"
Check-Dep "Python"      "python" "Instalar: https://python.org/downloads (marcar 'Add to PATH')"
Check-Dep "Node.js"     "node"   "Instalar: https://nodejs.org"
Check-Dep "Git"         "git"    "Instalar: https://git-scm.com/download/win"

if ($errores -gt 0) {
  Write-Host ""
  Write-Err "Faltan $errores dependencias. Instaladas y vuelve a correr este script."
  exit 1
}

# Detectar comando Python correcto
$PYTHON_CMD = "python"
try { & python --version 2>&1 | Out-Null } catch {
  try { & python3 --version 2>&1 | Out-Null; $PYTHON_CMD = "python3" } catch {
    Write-Err "Python no encontrado en PATH."
    exit 1
  }
}

# ============================================================
# PASO 2 — Recolectar configuración
# ============================================================
Write-Step "Configuracion del vault..."

# Ruta del vault
$VAULT_DEFAULT = "$env:USERPROFILE\Documents\Fate Vault"
if (Test-Path $VAULT_DEFAULT) {
  Write-Ok "Vault encontrado en: $VAULT_DEFAULT"
  $VAULT_PATH = $VAULT_DEFAULT
} else {
  Write-Ask "No se encontro el vault en la ubicacion por defecto."
  $VAULT_PATH = Read-Host "  Ruta completa a tu vault de Obsidian (Ej: C:\Users\$env:USERNAME\Documents\Mi Vault)"
  if (-not (Test-Path $VAULT_PATH)) {
    Write-Err "La ruta '$VAULT_PATH' no existe. Verifica que Obsidian Sync haya terminado."
    exit 1
  }
  Write-Ok "Vault encontrado en: $VAULT_PATH"
}

# Verificar estructura
if (-not (Test-Path "$VAULT_PATH\_Sistema\REGLAS.md")) {
  Write-Warn "No se encontro _Sistema\REGLAS.md. El vault puede estar incompleto."
}

Write-Ask "Como se llama el vault en Obsidian?"
Write-Host "  (El nombre que aparece arriba a la izquierda en Obsidian)" -ForegroundColor Gray
$VAULT_NAME = Read-Host "  Nombre del vault"

Write-Ask "Cual es tu nombre? (Aparece en los logs de conversacion)"
$NOMBRE_USUARIO = Read-Host "  Tu nombre"

Write-Ask "Cual es el API Key del plugin 'Local REST API' de Obsidian?"
Write-Host "  (Obsidian -> Settings -> Community Plugins -> Local REST API)" -ForegroundColor Gray
$OBSIDIAN_API_KEY = Read-Host "  API Key"

if ([string]::IsNullOrEmpty($OBSIDIAN_API_KEY)) {
  Write-Err "El API Key no puede estar vacio."
  Write-Host "  Instala el plugin 'Local REST API' en Obsidian primero." -ForegroundColor Gray
  exit 1
}

# ============================================================
# PASO 3 — Detectar rutas automáticamente
# ============================================================
Write-Step "Detectando rutas de Claude Code..."

$USERNAME = $env:USERNAME
$PROJECT_ID = "-C-Users-$USERNAME"
$MEMORY_DIR = "$CLAUDE_DIR\projects\$PROJECT_ID\memory"
$OBSIDIAN_MEMORIA = "$VAULT_PATH\00 Agentes\F.A.T.E\Memoria"
$VAULT_PATH_FWD = $VAULT_PATH -replace "\\", "/"
$MEMORY_DIR_FWD = $MEMORY_DIR -replace "\\", "/"
$OBSIDIAN_MEMORIA_FWD = $OBSIDIAN_MEMORIA -replace "\\", "/"

Write-Ok "Project ID detectado: $PROJECT_ID"
Write-Ok "Memoria Claude: $MEMORY_DIR"
Write-Ok "Memoria Obsidian: $OBSIDIAN_MEMORIA"

New-Item -ItemType Directory -Force -Path $MEMORY_DIR | Out-Null

# ============================================================
# PASO 4 — Clonar repositorio
# ============================================================
Write-Step "Clonando repositorio..."

git clone --quiet $REPO $TEMP_DIR 2>&1 | Out-Null
Write-Ok "Repositorio clonado"

# ============================================================
# PASO 5 — Instalar hooks
# ============================================================
Write-Step "Instalando hooks..."

New-Item -ItemType Directory -Force -Path "$CLAUDE_DIR\hooks" | Out-Null
Copy-Item "$TEMP_DIR\hooks\*.py" "$CLAUDE_DIR\hooks\" -Force
Write-Ok "Hooks copiados a $CLAUDE_DIR\hooks\"

function Replace-InFile {
  param($file, $old, $new)
  & $PYTHON_CMD -c @"
import sys
content = open(sys.argv[1], encoding='utf-8').read()
content = content.replace(sys.argv[2], sys.argv[3])
open(sys.argv[1], 'w', encoding='utf-8').write(content)
"@ $file $old $new
}

# obsidian_start_hook.py
$F = "$CLAUDE_DIR\hooks\obsidian_start_hook.py"
Replace-InFile $F "/ruta/a/tu/vault" $VAULT_PATH_FWD
Write-Ok "obsidian_start_hook.py configurado"

# obsidian_memory_sync.py
$F = "$CLAUDE_DIR\hooks\obsidian_memory_sync.py"
Replace-InFile $F "/Users/{tu-usuario}/.claude/projects/{project-id}/memory" $MEMORY_DIR_FWD
Replace-InFile $F "/ruta/a/tu/vault/00 Agentes/{Tu-Agente}/Memoria" $OBSIDIAN_MEMORIA_FWD
Write-Ok "obsidian_memory_sync.py configurado"

# obsidian_session_end_hook.py
$F = "$CLAUDE_DIR\hooks\obsidian_session_end_hook.py"
Replace-InFile $F "/ruta/a/tu/vault" $VAULT_PATH_FWD
Replace-InFile $F "/Users/{tu-usuario}/.claude/projects/{project-id}/memory" $MEMORY_DIR_FWD
Write-Ok "obsidian_session_end_hook.py configurado"

# conversation_capture.py
$F = "$CLAUDE_DIR\hooks\conversation_capture.py"
Replace-InFile $F "/ruta/a/tu/vault" $VAULT_PATH_FWD
Replace-InFile $F "Usuario" $NOMBRE_USUARIO
Write-Ok "conversation_capture.py configurado"

# ============================================================
# PASO 6 — Instalar skill
# ============================================================
Write-Step "Instalando skill fate-vault-guardian..."

New-Item -ItemType Directory -Force -Path "$CLAUDE_DIR\skills\fate-vault-guardian" | Out-Null
Copy-Item "$TEMP_DIR\fate-vault-guardian\SKILL.md" "$CLAUDE_DIR\skills\fate-vault-guardian\" -Force

$F = "$CLAUDE_DIR\skills\fate-vault-guardian\SKILL.md"
Replace-InFile $F "/tu/ruta/al/vault/" "$VAULT_PATH_FWD/"
Replace-InFile $F "nombre-de-tu-vault" $VAULT_NAME
Write-Ok "Skill instalado y configurado"

# ============================================================
# PASO 7 — Configurar settings.json
# ============================================================
Write-Step "Configurando settings.json..."

$PYTHON_PATH = (Get-Command $PYTHON_CMD).Source -replace "\\", "\\\\"
$HOOKS_DIR = "$CLAUDE_DIR\hooks" -replace "\\", "\\\\"
$SETTINGS_FILE = "$CLAUDE_DIR\settings.json"

$HOOKS_JSON = @"
{
  "SessionStart": [{"hooks": [{"type": "command", "command": "$PYTHON_CMD $CLAUDE_DIR\\hooks\\obsidian_start_hook.py", "timeout": 30, "statusMessage": "Cargando contexto desde vault..."}]}],
  "PostToolUse": [{"matcher": "Write|Edit", "hooks": [{"type": "command", "command": "$PYTHON_CMD $CLAUDE_DIR\\hooks\\obsidian_memory_sync.py", "timeout": 10, "async": true}]}],
  "Stop": [{"hooks": [{"type": "command", "command": "$PYTHON_CMD $CLAUDE_DIR\\hooks\\conversation_capture.py", "timeout": 15, "async": true}]}],
  "SessionEnd": [{"hooks": [{"type": "command", "command": "$PYTHON_CMD $CLAUDE_DIR\\hooks\\obsidian_session_end_hook.py", "timeout": 30, "statusMessage": "Guardando en vault..."}]}]
}
"@

& $PYTHON_CMD -c @"
import json, sys

settings_file = r'$SETTINGS_FILE'
hooks_json = r'''$HOOKS_JSON'''

try:
    with open(settings_file, 'r', encoding='utf-8') as f:
        config = json.load(f)
except FileNotFoundError:
    config = {}

if 'hooks' not in config:
    config['hooks'] = json.loads(hooks_json)
    with open(settings_file, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print('  [OK] settings.json configurado')
else:
    print('  [!]  settings.json ya tiene hooks. Revisar manualmente.')
"@

# ============================================================
# PASO 8 — Configurar MCP de Obsidian
# ============================================================
Write-Step "Configurando MCP de Obsidian..."

$CLAUDE_JSON = "$env:USERPROFILE\.claude.json"

& $PYTHON_CMD -c @"
import json, sys

claude_json = r'$CLAUDE_JSON'
api_key = '$OBSIDIAN_API_KEY'

try:
    with open(claude_json, 'r', encoding='utf-8') as f:
        config = json.load(f)
except FileNotFoundError:
    config = {'mcpServers': {}}

if 'mcpServers' not in config:
    config['mcpServers'] = {}

if 'obsidian' not in config['mcpServers']:
    config['mcpServers']['obsidian'] = {
        'command': 'npx',
        'args': ['-y', 'mcp-obsidian'],
        'env': {
            'OBSIDIAN_API_KEY': api_key,
            'OBSIDIAN_HOST': '127.0.0.1',
            'OBSIDIAN_PORT': '27123'
        }
    }
    with open(claude_json, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print('  [OK] MCP de Obsidian agregado a .claude.json')
else:
    print('  [!]  MCP de Obsidian ya estaba configurado')
"@

# ============================================================
# PASO 9 — Crear CLAUDE.md
# ============================================================
Write-Step "Creando CLAUDE.md global..."

$CLAUDE_MD = "$CLAUDE_DIR\CLAUDE.md"

if (-not (Test-Path $CLAUDE_MD)) {
  @"
# Instrucciones Globales

## Vault de Obsidian
El vault esta en ``$VAULT_PATH``.
Es la fuente de verdad del negocio. Leer ``_Sistema/REGLAS.md`` antes de cualquier operacion.

## Guardian del vault
Cada vez que se crea, edita, mueve o elimina un archivo .md en el vault,
leer y aplicar el skill ``fate-vault-guardian``.

## Comportamiento general
- Respuestas cortas y directas, sin relleno
- Verificar el estado actual antes de hacer suposiciones
- Ante una tarea ambigua, hacer UNA pregunta concreta
"@ | Out-File -FilePath $CLAUDE_MD -Encoding utf8
  Write-Ok "CLAUDE.md creado"
} else {
  Write-Warn "CLAUDE.md ya existe, no se modifico."
}

# ============================================================
# PASO 10 — Verificación y limpieza
# ============================================================
Write-Step "Verificando instalacion..."

Remove-Item -Recurse -Force $TEMP_DIR -ErrorAction SilentlyContinue

$ok = $true

function Check-File {
  param($path, $label)
  if (Test-Path $path) { Write-Ok $label }
  else { Write-Err "$label -- NO encontrado"; $script:ok = $false }
}

Check-File "$CLAUDE_DIR\hooks\obsidian_start_hook.py"      "Hook SessionStart"
Check-File "$CLAUDE_DIR\hooks\obsidian_memory_sync.py"     "Hook PostToolUse"
Check-File "$CLAUDE_DIR\hooks\conversation_capture.py"     "Hook Stop"
Check-File "$CLAUDE_DIR\hooks\obsidian_session_end_hook.py" "Hook SessionEnd"
Check-File "$CLAUDE_DIR\skills\fate-vault-guardian\SKILL.md" "Skill fate-vault-guardian"
Check-File "$CLAUDE_DIR\settings.json"                     "settings.json"
Check-File "$CLAUDE_MD"                                     "CLAUDE.md"

# ============================================================
# RESUMEN FINAL
# ============================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor White

if ($ok) {
  Write-Host "  Setup completado exitosamente" -ForegroundColor Green
  Write-Host "================================================" -ForegroundColor White
  Write-Host ""
  Write-Host "  Vault:   $VAULT_PATH"
  Write-Host "  Memoria: $MEMORY_DIR"
  Write-Host "  Hooks:   $CLAUDE_DIR\hooks\"
  Write-Host "  Skill:   $CLAUDE_DIR\skills\fate-vault-guardian\"
  Write-Host ""
  Write-Host "  Proximo paso:" -ForegroundColor White
  Write-Host "  1. Abre Obsidian y verifica que 'Local REST API' este activo"
  Write-Host "  2. Abre Claude Code con:  cd `$HOME && claude"
  Write-Host "  3. Debe aparecer: 'Cargando contexto desde vault...'"
  Write-Host ""
} else {
  Write-Host "  Setup completado con errores" -ForegroundColor Red
  Write-Host "================================================" -ForegroundColor White
  Write-Host ""
  Write-Host "  Revisa los errores y vuelve a correr el script."
  Write-Host ""
}
