# Claude Code + Obsidian Setup

Integración completa entre Claude Code y un vault de Obsidian. Contexto persistente entre sesiones, sincronización automática de memoria y archivo de todas las conversaciones.

## Instalación en un comando

### Mac
```bash
curl -sSL https://raw.githubusercontent.com/mazeos/obsidian-setup/main/install.sh | bash
```

### Windows (PowerShell como Administrador)
```powershell
irm https://raw.githubusercontent.com/mazeos/obsidian-setup/main/install.ps1 | iex
```

El script hace todo automáticamente. Solo te pregunta 4 cosas:
1. Ruta del vault (la detecta solo si está en la ubicación por defecto)
2. Nombre del vault en Obsidian
3. Tu nombre
4. API Key del plugin Local REST API

---

## Qué instala

| Componente | Qué hace |
|---|---|
| Hook `SessionStart` | Lee el vault al iniciar — Claude ya sabe todo desde el primer mensaje |
| Hook `PostToolUse` | Copia la memoria a Obsidian en tiempo real cada vez que Claude escribe |
| Hook `Stop` | Archiva cada conversación en el vault organizada por fecha |
| Hook `SessionEnd` | Sincronización final de memoria + listado de MCPs al cerrar |
| Skill `fate-vault-guardian` | Valida que Claude respete la estructura, routing y nomenclatura del vault |
| MCP de Obsidian | Permite que Claude lea y escriba en el vault por nombre |

---

## Requisitos previos

- Obsidian instalado con el vault sincronizado vía **Obsidian Sync**
- Plugin **Local REST API** instalado en Obsidian (Community Plugins)
- Claude Code instalado (`npm install -g @anthropic-ai/claude-code`)
- Python 3.8+
- Node.js
- Git

Si no tienes alguno de estos, el script lo detecta y te dice cómo instalarlo antes de continuar.

---

## Setup manual / guía detallada

Ver [SETUP.md](./SETUP.md) para instrucciones paso a paso con explicación de cada componente.

---

## Autor

[Maze Funnels](https://mazefunnels.io)
