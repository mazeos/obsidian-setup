# Claude Code Skills — Maze Funnels

Sistema completo para conectar Claude Code con un vault de Obsidian. Incluye el skill de validacion del vault y los hooks de sincronizacion automatica.

## Que incluye

| Componente | Que hace |
|---|---|
| `fate-vault-guardian/` | Skill: reglas de estructura, routing y nomenclatura del vault |
| `hooks/obsidian_start_hook.py` | Carga contexto del vault al iniciar cada sesion |
| `hooks/obsidian_memory_sync.py` | Sincroniza memoria de Claude a Obsidian en tiempo real |
| `hooks/conversation_capture.py` | Archiva cada conversacion en el vault automaticamente |
| `hooks/obsidian_session_end_hook.py` | Sync final de memoria y MCPs al cerrar sesion |
| `settings-template.json` | Template de configuracion para `~/.claude/settings.json` |

## Como funciona

```
[Inicio de sesion]   obsidian_start_hook   → Claude lee el vault y "sabe" todo
[Claude escribe]     obsidian_memory_sync  → memoria se copia a Obsidian al instante
[Claude responde]    conversation_capture  → conversacion archivada en el vault
[Fin de sesion]      session_end_hook      → sync final + listado de MCPs actualizado
```

## Instalacion rapida

### 1. Clonar

```bash
git clone https://github.com/mazeos/claude-skills.git
```

### 2. Copiar hooks

```bash
cp claude-skills/hooks/*.py ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.py
```

### 3. Instalar el skill

```bash
mkdir -p ~/.claude/skills/fate-vault-guardian
cp claude-skills/fate-vault-guardian/SKILL.md ~/.claude/skills/fate-vault-guardian/
```

### 4. Adaptar las rutas

En cada `.py` dentro de `hooks/` hay una seccion `# CONFIG`. Editar:
- `VAULT` → ruta a tu vault de Obsidian
- `MEMORY_SOURCE_DIR` → ruta a tu directorio de memoria de Claude Code
- `NOMBRE_USUARIO` → tu nombre

En `fate-vault-guardian/SKILL.md` editar:
- `VAULT_PATH` → ruta a tu vault
- `VAULT_MCP_NAME` → nombre del vault en el MCP de Obsidian

### 5. Configurar hooks en Claude Code

Copiar el contenido de `settings-template.json` a `~/.claude/settings.json` (o mergearlo si ya tienes configuracion), reemplazando `{tu-usuario}` con tu usuario de Mac.

### 6. Activar el skill en CLAUDE.md

Agregar a `~/.claude/CLAUDE.md`:

```markdown
Cada vez que se crea, edita, mueve o elimina un archivo .md en el vault,
leer y aplicar el skill `fate-vault-guardian`.
```

### 7. Crear tu REGLAS.md

El skill referencia `_Sistema/REGLAS.md` dentro del vault. Crea ese archivo con las reglas de tu propia estructura.

## Estructura de vault recomendada

```
_Sistema/           → Reglas, mapa y templates
00 Agentes/         → Definiciones de agentes IA
01 Growth Engine/   → Operacion interna por departamento
02 Clientes/        → Seguimiento por plan
03 SOPs/            → Procedimientos por departamento
04 Content Hacking/ → Inteligencia de contenido por pilar
05 Credenciales/    → APIs, tokens, servicios
```

## Autor

[Maze Funnels](https://mazefunnels.io) — Agencia de marketing y mentoring para emprendedores digitales.
