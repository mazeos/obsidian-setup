#!/bin/bash
# ============================================================
# install.sh — Setup automático Claude Code + Obsidian
# https://github.com/mazeos/obsidian-setup
#
# Uso:
#   curl -sSL https://raw.githubusercontent.com/mazeos/obsidian-setup/main/install.sh | bash
# ============================================================

set -e

REPO="https://github.com/mazeos/obsidian-setup.git"
CLAUDE_DIR="$HOME/.claude"
TEMP_DIR=$(mktemp -d)

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
step() { echo -e "\n${BLUE}${BOLD}▶ $1${NC}"; }
ask()  { echo -e "\n${YELLOW}$1${NC}"; }

cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

echo ""
echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}  Claude Code + Obsidian — Setup Automático     ${NC}"
echo -e "${BOLD}================================================${NC}"
echo ""

# ============================================================
# PASO 1 — Auditoría de dependencias
# ============================================================
step "Verificando dependencias..."

ERRORES=0

check_dep() {
  local name="$1"
  local cmd="$2"
  local install_hint="$3"
  if command -v $cmd &>/dev/null; then
    ok "$name: $(${cmd} --version 2>&1 | head -1)"
  else
    err "$name no encontrado. $install_hint"
    ERRORES=$((ERRORES+1))
  fi
}

check_dep "Claude Code" "claude"  "Instalar: npm install -g @anthropic-ai/claude-code"
check_dep "Python 3"   "python3" "Instalar: brew install python3"
check_dep "Node.js"    "node"    "Instalar: brew install node"
check_dep "Git"        "git"     "Instalar: brew install git"

if [ $ERRORES -gt 0 ]; then
  echo ""
  err "Faltan $ERRORES dependencias. Instálalas y vuelve a correr este script."
  exit 1
fi

# Verificar que Claude Code está autenticado
if ! claude mcp list &>/dev/null 2>&1; then
  warn "Claude Code no está autenticado. Corriendo: claude login"
  claude login
fi

# ============================================================
# PASO 2 — Recolectar configuración del usuario
# ============================================================
step "Configuración del vault..."

# -- Ruta del vault --
VAULT_DEFAULT="$HOME/Documents/Fate Vault"
if [ -d "$VAULT_DEFAULT" ]; then
  ok "Vault encontrado en: $VAULT_DEFAULT"
  VAULT_PATH="$VAULT_DEFAULT"
else
  ask "¿Cuál es la ruta completa a tu vault de Obsidian?"
  echo -e "  (Ej: /Users/$(whoami)/Documents/Mi Vault)"
  read -r VAULT_PATH
  if [ ! -d "$VAULT_PATH" ]; then
    err "La ruta '$VAULT_PATH' no existe. Verifica que Obsidian Sync haya terminado."
    exit 1
  fi
  ok "Vault encontrado en: $VAULT_PATH"
fi

# Verificar que tenga la estructura esperada
if [ ! -f "$VAULT_PATH/_Sistema/REGLAS.md" ]; then
  warn "No se encontró _Sistema/REGLAS.md. El vault puede estar incompleto."
  echo "  Continúa solo si el vault ya está sincronizado."
fi

# -- Nombre del vault en Obsidian --
ask "¿Cómo se llama el vault en Obsidian?"
echo -e "  (El nombre que aparece arriba a la izquierda en Obsidian. Ej: Fate Vault)"
read -r VAULT_NAME

# -- Nombre del usuario --
ask "¿Cuál es tu nombre? (Aparece en los logs de conversación)"
echo -e "  (Ej: Alejandro)"
read -r NOMBRE_USUARIO

# -- API Key del plugin Local REST API --
ask "¿Cuál es el API Key del plugin 'Local REST API' de Obsidian?"
echo -e "  (Obsidian → Settings → Community Plugins → Local REST API → copiar el API Key)"
read -r OBSIDIAN_API_KEY

if [ -z "$OBSIDIAN_API_KEY" ]; then
  err "El API Key no puede estar vacío."
  echo "  Instala el plugin 'Local REST API' en Obsidian primero."
  exit 1
fi

# ============================================================
# PASO 3 — Detectar rutas automáticamente
# ============================================================
step "Detectando rutas de Claude Code..."

USERNAME=$(whoami)
PROJECT_ID="-Users-${USERNAME}"
MEMORY_DIR="$HOME/.claude/projects/${PROJECT_ID}/memory"
OBSIDIAN_MEMORIA="${VAULT_PATH}/00 Agentes/F.A.T.E/Memoria"
CONVERSACIONES_DIR="${VAULT_PATH}/01 Growth Engine/Infraestructura IA/Claude Code/Conversaciones"
CREDENCIALES_FILE="${VAULT_PATH}/05 Credenciales/Servicios.md"

ok "Project ID detectado: $PROJECT_ID"
ok "Memoria Claude: $MEMORY_DIR"
ok "Memoria Obsidian: $OBSIDIAN_MEMORIA"

# Crear directorio de memoria si no existe
mkdir -p "$MEMORY_DIR"

# ============================================================
# PASO 4 — Clonar repositorio
# ============================================================
step "Clonando repositorio..."

git clone --quiet "$REPO" "$TEMP_DIR/repo"
ok "Repositorio clonado"

# ============================================================
# PASO 5 — Instalar hooks
# ============================================================
step "Instalando hooks..."

mkdir -p "$CLAUDE_DIR/hooks"
cp "$TEMP_DIR/repo/hooks/"*.py "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/"*.py
ok "Hooks copiados a $CLAUDE_DIR/hooks/"

# Función para reemplazar valores en archivos Python
replace_in_file() {
  local file="$1"
  local old="$2"
  local new="$3"
  python3 -c "
import sys
content = open(sys.argv[1], encoding='utf-8').read()
content = content.replace(sys.argv[2], sys.argv[3])
open(sys.argv[1], 'w', encoding='utf-8').write(content)
" "$file" "$old" "$new"
}

# Adaptar obsidian_start_hook.py
F="$CLAUDE_DIR/hooks/obsidian_start_hook.py"
replace_in_file "$F" "/ruta/a/tu/vault" "$VAULT_PATH"
ok "obsidian_start_hook.py configurado"

# Adaptar obsidian_memory_sync.py
F="$CLAUDE_DIR/hooks/obsidian_memory_sync.py"
replace_in_file "$F" "/Users/{tu-usuario}/.claude/projects/{project-id}/memory" "$MEMORY_DIR"
replace_in_file "$F" "/ruta/a/tu/vault/00 Agentes/{Tu-Agente}/Memoria" "$OBSIDIAN_MEMORIA"
ok "obsidian_memory_sync.py configurado"

# Adaptar obsidian_session_end_hook.py
F="$CLAUDE_DIR/hooks/obsidian_session_end_hook.py"
replace_in_file "$F" "/ruta/a/tu/vault" "$VAULT_PATH"
replace_in_file "$F" "/Users/{tu-usuario}/.claude/projects/{project-id}/memory" "$MEMORY_DIR"
replace_in_file "$F" "f\"{VAULT}/00 Agentes/{Tu-Agente}/Memoria\"" "\"${OBSIDIAN_MEMORIA}\""
ok "obsidian_session_end_hook.py configurado"

# Adaptar conversation_capture.py
F="$CLAUDE_DIR/hooks/conversation_capture.py"
replace_in_file "$F" "/ruta/a/tu/vault" "$VAULT_PATH"
replace_in_file "$F" "Usuario" "$NOMBRE_USUARIO"
ok "conversation_capture.py configurado"

# ============================================================
# PASO 6 — Instalar skill
# ============================================================
step "Instalando skill fate-vault-guardian..."

mkdir -p "$CLAUDE_DIR/skills/fate-vault-guardian"
cp "$TEMP_DIR/repo/fate-vault-guardian/SKILL.md" "$CLAUDE_DIR/skills/fate-vault-guardian/"

F="$CLAUDE_DIR/skills/fate-vault-guardian/SKILL.md"
replace_in_file "$F" "/tu/ruta/al/vault/" "$VAULT_PATH/"
replace_in_file "$F" "nombre-de-tu-vault" "$VAULT_NAME"
ok "Skill instalado y configurado"

# ============================================================
# PASO 7 — Configurar settings.json
# ============================================================
step "Configurando settings.json..."

SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOKS_JSON=$(cat << ENDJSON
{
  "SessionStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "/usr/bin/python3 $CLAUDE_DIR/hooks/obsidian_start_hook.py",
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
          "command": "/usr/bin/python3 $CLAUDE_DIR/hooks/obsidian_memory_sync.py",
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
          "command": "/usr/bin/python3 $CLAUDE_DIR/hooks/conversation_capture.py",
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
          "command": "/usr/bin/python3 $CLAUDE_DIR/hooks/obsidian_session_end_hook.py",
          "timeout": 30,
          "statusMessage": "Guardando en vault..."
        }
      ]
    }
  ]
}
ENDJSON
)

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "{\"hooks\": $HOOKS_JSON}" | python3 -m json.tool > "$SETTINGS_FILE"
  ok "settings.json creado"
elif ! python3 -c "import json,sys; d=json.load(open('$SETTINGS_FILE')); sys.exit(0 if 'hooks' not in d else 1)" 2>/dev/null; then
  warn "settings.json ya existe con hooks configurados."
  warn "Agrega los hooks manualmente desde: $TEMP_DIR/repo/settings-template.json"
else
  python3 << PYEOF
import json

with open('$SETTINGS_FILE', 'r', encoding='utf-8') as f:
    config = json.load(f)

hooks = json.loads('''$HOOKS_JSON''')
config['hooks'] = hooks

with open('$SETTINGS_FILE', 'w', encoding='utf-8') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
PYEOF
  ok "Hooks agregados a settings.json existente"
fi

# ============================================================
# PASO 8 — Configurar MCP de Obsidian
# ============================================================
step "Configurando MCP de Obsidian..."

CLAUDE_JSON="$HOME/.claude.json"

if [ ! -f "$CLAUDE_JSON" ]; then
  echo '{"mcpServers": {}}' > "$CLAUDE_JSON"
fi

python3 << PYEOF
import json

with open('$CLAUDE_JSON', 'r', encoding='utf-8') as f:
    config = json.load(f)

if 'mcpServers' not in config:
    config['mcpServers'] = {}

if 'obsidian' not in config['mcpServers']:
    config['mcpServers']['obsidian'] = {
        "command": "npx",
        "args": ["-y", "mcp-obsidian"],
        "env": {
            "OBSIDIAN_API_KEY": "$OBSIDIAN_API_KEY",
            "OBSIDIAN_HOST": "127.0.0.1",
            "OBSIDIAN_PORT": "27123"
        }
    }
    with open('$CLAUDE_JSON', 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print("  \033[0;32m✓\033[0m MCP de Obsidian agregado a ~/.claude.json")
else:
    print("  \033[1;33m⚠\033[0m  MCP de Obsidian ya estaba configurado, no se modificó")
PYEOF

# ============================================================
# PASO 9 — Crear CLAUDE.md global
# ============================================================
step "Creando CLAUDE.md global..."

CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

if [ ! -f "$CLAUDE_MD" ]; then
cat > "$CLAUDE_MD" << ENDMD
# Instrucciones Globales

## Vault de Obsidian
El vault está en \`$VAULT_PATH\`.
Es la fuente de verdad del negocio. Leer \`_Sistema/REGLAS.md\` antes de cualquier operación.

## Guardian del vault
Cada vez que se crea, edita, mueve o elimina un archivo .md en el vault,
leer y aplicar el skill \`fate-vault-guardian\`.

## Comportamiento general
- Respuestas cortas y directas, sin relleno
- Verificar el estado actual antes de hacer suposiciones
- Ante una tarea ambigua, hacer UNA pregunta concreta
ENDMD
  ok "CLAUDE.md creado"
else
  warn "CLAUDE.md ya existe, no se modificó. Revisa que incluya la referencia al vault y al guardian."
fi

# ============================================================
# PASO 10 — Verificación final
# ============================================================
step "Verificando instalación..."

VERIFICACION_OK=true

check_file() {
  if [ -f "$1" ]; then
    ok "$2"
  else
    err "$2 — NO encontrado en $1"
    VERIFICACION_OK=false
  fi
}

check_file "$CLAUDE_DIR/hooks/obsidian_start_hook.py"    "Hook SessionStart"
check_file "$CLAUDE_DIR/hooks/obsidian_memory_sync.py"   "Hook PostToolUse"
check_file "$CLAUDE_DIR/hooks/conversation_capture.py"   "Hook Stop"
check_file "$CLAUDE_DIR/hooks/obsidian_session_end_hook.py" "Hook SessionEnd"
check_file "$CLAUDE_DIR/skills/fate-vault-guardian/SKILL.md" "Skill fate-vault-guardian"
check_file "$CLAUDE_DIR/settings.json"                   "settings.json"
check_file "$CLAUDE_MD"                                   "CLAUDE.md"

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo -e "${BOLD}================================================${NC}"

if [ "$VERIFICACION_OK" = true ]; then
  echo -e "${GREEN}${BOLD}  Setup completado exitosamente${NC}"
  echo -e "${BOLD}================================================${NC}"
  echo ""
  echo -e "  Vault:    $VAULT_PATH"
  echo -e "  Memoria:  $MEMORY_DIR"
  echo -e "  Hooks:    $CLAUDE_DIR/hooks/"
  echo -e "  Skill:    $CLAUDE_DIR/skills/fate-vault-guardian/"
  echo ""
  echo -e "${BOLD}  Próximo paso:${NC}"
  echo -e "  1. Abre Obsidian y verifica que el plugin 'Local REST API' esté activo"
  echo -e "  2. Abre Claude Code con:  ${BOLD}cd ~ && claude${NC}"
  echo -e "  3. Debe aparecer: 'Cargando contexto desde vault...'"
  echo ""
else
  echo -e "${RED}${BOLD}  Setup completado con errores${NC}"
  echo -e "${BOLD}================================================${NC}"
  echo ""
  echo -e "  Revisa los errores anteriores y vuelve a correr el script."
  echo ""
fi
