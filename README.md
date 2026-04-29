# Claude Code Skills — Maze Funnels

Skills para Claude Code pensados para agencias y negocios digitales que usan Obsidian como cerebro operativo.

## Skills disponibles

### `fate-vault-guardian`

Guardian de orden para vaults de Obsidian con estructura de agencia. Aplica reglas de estructura, routing, nomenclatura y frontmatter cada vez que Claude Code crea, edita, mueve o elimina archivos `.md` en el vault.

**Para quienes:** equipos que usan Obsidian como knowledge base de agencia y quieren que Claude Code respete la estructura sin importar quién escriba.

---

## Instalacion

### 1. Clonar el repo

```bash
git clone https://github.com/mazeos/claude-skills.git
```

### 2. Copiar el skill a tu carpeta de Claude Code

```bash
cp -r claude-skills/fate-vault-guardian ~/.claude/skills/
```

### 3. Adaptar las rutas

Edita `~/.claude/skills/fate-vault-guardian/SKILL.md` y cambia:

```
VAULT_PATH: /tu/ruta/al/vault/
VAULT_MCP_NAME: nombre-de-tu-vault
```

### 4. Crear tu REGLAS.md

El skill referencia `_Sistema/REGLAS.md` dentro de tu vault. Crea ese archivo con las reglas especificas de tu vault. Puedes basarte en la estructura del skill como guia.

### 5. Activar en CLAUDE.md

Agrega esto a tu `~/.claude/CLAUDE.md` o al `CLAUDE.md` dentro del vault:

```markdown
## Guardian del vault

Cada vez que se crea, edita, mueve o elimina un archivo .md en el vault,
leer y aplicar el skill `fate-vault-guardian`.
```

---

## Estructura de vault recomendada

```
_Sistema/          → Reglas, mapa y templates
00 Agentes/        → Definiciones de agentes IA
01 Growth Engine/  → Operacion interna por departamento
02 Clientes/       → Seguimiento por plan
03 SOPs/           → Procedimientos por departamento
04 Content Hacking/→ Inteligencia de contenido por pilar
05 Credenciales/   → APIs, tokens, servicios
```

---

## Autor

[Maze Funnels](https://mazefunnels.io) — Agencia de marketing y mentoring para emprendedores digitales.
