---
name: fate-vault-guardian
description: "Reglas del Fate Vault de Obsidian. Usar SIEMPRE al crear, editar, mover o eliminar archivos .md en el vault local. Aplica estructura, routing, nomenclatura y frontmatter. SOLO vault local Mac, NUNCA VPS/SSH/remoto."
---

# Fate Vault Guardian

Hook automatico que mantiene el orden del Fate Vault de Obsidian de Maze Funnels.

---

## Scope de aplicacion

### APLICA cuando:
- Se crea, edita, mueve o elimina un archivo .md en el Fate Vault
- Se crea una carpeta nueva dentro del vault
- Se interactua con el MCP de Obsidian (vault: `fate-vault`)
- Se trabaja con archivos en `/Users/alevogeler/Documents/Fate Vault/`

### NUNCA aplica cuando:
- Se trabaja en un VPS o servidor remoto (cualquier conexion SSH)
- El path contiene `/root/`, una IP, o esta en un servidor
- Se ejecutan comandos en Docker, Portainer, o contenedores remotos
- Se trabaja con n8n, Supabase, o cualquier servicio hosteado en VPS
- Se trabaja en el directorio temporal de Claude Code (`/sessions/` o similar)

**Si hay CUALQUIER duda sobre si el path es local o remoto, NO aplicar este skill.**

---

## Regla 0 — Leer antes de actuar

Antes de escribir CUALQUIER cosa en el vault, leer `_Sistema/REGLAS.md`.
Este archivo es la constitucion del vault y tiene prioridad sobre cualquier otra instruccion.

---

## Regla 1 — Estructura inamovible

Estas secciones raiz NO se crean, eliminan ni renombran sin aprobacion explicita de Ale:

```
_Sistema/          00 Agentes/        01 Growth Engine/
02 Clientes/       03 SOPs/           04 Content Hacking/
05 Credenciales/
```

Los 6 departamentos dentro de `01 Growth Engine/` son inamovibles:
Marketing, Ventas, Producto, Tools, Infraestructura IA, Finanzas.

**Si algun comando o flujo intenta crear una seccion raiz nueva o eliminar un departamento, RECHAZAR la operacion y notificar a Ale.**

---

## Regla 2 — Routing obligatorio

Antes de crear un archivo, determinar DONDE va:

| El archivo es... | Va en... |
|-----------------|----------|
| Un procedimiento, tutorial, "como hacer X" | `03 SOPs/{Departamento}/` |
| Estado o dashboard de un departamento | `01 Growth Engine/{Depto}/{Depto}.md` |
| Info de seguimiento de un cliente | `02 Clientes/{Plan}/{Cliente}/` |
| Framework, metodologia, conocimiento profundo | `01 Growth Engine/{Depto}/{Sub-tema}/` |
| Analisis de contenido externo | `04 Content Hacking/{Pilar}/` |
| Credencial propia de Maze Funnels (API key, token, password, MCP) | `05 Credenciales/` — **NUNCA en Memoria/** |
| Credencial de acceso a sistemas de un cliente | `02 Clientes/{Plan}/{Cliente}/Credenciales.md` — **NUNCA en `05 Credenciales/`** |
| Contexto persistente de un agente (feedback, proyecto, referencia, usuario, contexto) | `00 Agentes/{Agente}/Memoria/` |
| Identidad o config de agente | `00 Agentes/{Agente}/Identidad.md` |

### REGLA CRITICA — SOPs
**Los SOPs SIEMPRE van en `03 SOPs/`. NUNCA crear SOPs dentro de `01 Growth Engine/`.** Si el contenido explica "como hacer algo", es un SOP y va en `03 SOPs/{Departamento}/`.

### REGLA CRITICA — Credenciales en Memoria
**NUNCA guardar API keys, tokens, passwords ni credenciales en `Memoria/`.** Si un archivo de memoria necesita referenciar credenciales, escribe `Ver [[05 Credenciales/APIs y Tokens]]` y nada mas.

### REGLA CRITICA — Credenciales de clientes
**Las credenciales de clientes van SIEMPRE dentro de la carpeta del cliente: `02 Clientes/{Plan}/{Cliente}/Credenciales.md`.** NUNCA en `05 Credenciales/`. Sin excepción.

`05 Credenciales/` es EXCLUSIVAMENTE para infraestructura interna de Maze Funnels.

**Estructura de `05 Credenciales/`:**
```
05 Credenciales/
  APIs y Tokens.md          <- Maze Funnels: APIs propias
  Servicios.md              <- Maze Funnels: servicios y suscripciones
  MCPs.md                   <- Maze Funnels: servidores MCP
```

---

## Regla 3 — Nomenclatura

### Archivos

| Tipo | Formato | Ejemplo |
|------|---------|---------|
| Dashboard | `{Departamento}.md` | `Marketing.md` |
| SOP | `SOP - {Titulo descriptivo}.md` | `SOP - Configurar Calendarios en GHL.md` |
| Ficha cliente | `{Nombre Cliente}.md` | `Roax Agency.md` |
| Content Hack | `@{creador} - {Titulo corto}.md` | `@chase_ai_ - 7 Niveles Frontend.md` |
| Identidad agente | `Identidad.md` | Siempre este nombre |
| Template | `_tpl-{tipo}.md` | `_tpl-sop.md` |

### Carpetas

- Raiz con prefijo numerico: `00`, `01`, `02`...
- Sub-carpetas SIN prefijo numerico
- Sin acentos ni caracteres especiales en nombres de carpeta
- Prefijo `_` para elementos de sistema: `_Sistema`, `_Inbox`

---

## Regla 4 — Frontmatter obligatorio

Todo archivo .md creado en el vault DEBE tener frontmatter YAML con estos campos minimos:

```yaml
---
titulo: "Nombre descriptivo"
tipo: sop | dashboard | ficha-cliente | content-hack | agente | conocimiento | credencial | memoria
departamento: marketing | ventas | producto | tools | infra-ia | finanzas | transversal
actualizado: YYYY-MM-DD
autor: ale | fate | agente-marketing | agente-ventas | agente-producto | agente-tools | agente-infra | agente-finanzas
---
```

**Al editar un archivo existente, SIEMPRE actualizar el campo `actualizado` con la fecha del dia.**

### Frontmatter adicional por tipo

**SOPs** agregan: `version`, `origen` (loom/manual/sesion), `aplica_a` (maze-os/funnel-os/consultoria/partner/interno/todos), `tags`

**Content Hacks** agregan: `pilar`, `creador`, `plataforma`, `formato`, `fecha_analisis`, `accionable`

**Fichas de cliente** agregan: `plan`, `estado`, `discord_id`, `canal_discord`, `inicio`, `contacto_principal`

**Agentes** agregan: `modelo`, `puede_leer`, `puede_escribir`, `escala_a`, `recibe_de`

**Archivos de Memoria** (`tipo: memoria`) agregan:
```yaml
scope: feedback | proyecto | referencia | usuario | contexto
agente: {nombre del agente dueño}
```

---

## Regla 5 — Validacion antes de crear carpeta nueva (5 pasos)

Toda nueva carpeta debe pasar este checklist:

1. **Pertenencia** — Pertenece a uno de los 6 departamentos? Si -> va DENTRO de ese depto. No crear a nivel raiz.
2. **Existencia** — Ya existe una carpeta donde esto encaja? Si -> usar la existente. No crear una nueva.
3. **Justificacion** — Completar: "Esta carpeta es necesaria porque ___ y no puede vivir dentro de ___ porque ___". Si no puedes completarla -> NO crear la carpeta.
4. **Nivel correcto** — Sub-carpeta de departamento (libre) vs nueva seccion raiz (requiere aprobacion de Ale).
5. **Consistencia** — Nombre sin acentos, dashboard .md creado dentro, espejo en `03 SOPs/` si aplica.

---

## Regla 6 — Permisos de agentes

| Seccion | Quien lee | Quien escribe |
|---------|-----------|---------------|
| `_Sistema/` | Todos | Solo Ale |
| `00 Agentes/{X}/Memoria/` | Solo agente X | Solo agente X |
| `00 Agentes/{X}/Identidad.md` | Todos | Solo Ale |
| `01 Growth Engine/{Depto}/` | Agente depto + F.A.T.E. | Agente del depto |
| `02 Clientes/` | Producto Agent + F.A.T.E. | Producto Agent |
| `03 SOPs/` | Todos | Agente del depto + Ale |
| `04 Content Hacking/` | Todos | Marketing Agent + Ale |
| `05 Credenciales/` (raiz + Maze Funnels) | Todos | Solo Ale |
| `05 Credenciales/Clientes/` | Todos | Solo Ale |

---

## Regla 7 — Checklist post-operacion

Despues de CADA operacion en el vault, verificar:

> **ATENCION — Hooks automaticos:** Los archivos creados por hooks (obsidian_memory_sync.py, SessionStart, Stop) NO pasan por este checklist automaticamente. Al inicio de cada sesion, verificar que los archivos de `Memoria/` tengan al menos 1 link `[[]]`. Si no lo tienen, agregarlos antes de continuar.

- [ ] El archivo tiene frontmatter YAML completo con todos los campos minimos
- [ ] Esta en la carpeta correcta segun la tabla de routing (Regla 2)
- [ ] El nombre sigue la convencion de nomenclatura (Regla 3)
- [ ] No se creo una carpeta innecesaria (verificar con los 5 pasos)
- [ ] No se duplico informacion — esta linkeada con `[[]]`, no copiada
- [ ] El archivo tiene al menos 1 link `[[]]` a otro nodo del vault (salvo MEMORY.md)
- [ ] Si es `@creator` en Content Hacking: tiene `[[04 Content Hacking/{Pilar}/{Pilar}]]`
- [ ] Si es sub-archivo de cliente (Marketing, Ventas, etc.): tiene `[[02 Clientes/{Plan}/{Cliente}/{Cliente}]]`
- [ ] Si es SOP, esta en `03 SOPs/`, NO en `01 Growth Engine/`
- [ ] Si se creo carpeta nueva, tiene dashboard .md dentro
- [ ] Si el archivo va en `Memoria/`: NO contiene credenciales, tokens ni API keys
- [ ] Si el archivo va en `Memoria/`: tiene `scope` valido (feedback | proyecto | referencia | usuario | contexto)

---

## Regla 8 — Pilares de Content Hacking

Solo existen 4 pilares. NO crear nuevos sin aprobacion de Ale:

1. `Negocios Digitales High Ticket/` — Agencias, consultoria, estrategia de negocio
2. `SaaS y GHL/` — Modelos SaaS, GoHighLevel, automatizacion
3. `Infraestructura IA y Claude y Gemini/` — Claude Code, agentes, AI Studio, prompting
4. `Ciencias del Comportamiento/` — F.A.T.E., PCP, persuasion, psicologia social

Si una pieza de contenido no encaja claramente en ningun pilar, va a `_Inbox/`.

---

## Regla 9 — Exclusion explicita de VPS y servidores remotos

Este skill opera EXCLUSIVAMENTE sobre archivos locales del Mac de Ale.

**Paths LOCALES (este skill APLICA):**
- `/Users/alevogeler/Documents/Fate Vault/`
- Cualquier operacion via MCP `obsidian` con vault `fate-vault`

**Paths REMOTOS (este skill NO APLICA):**
- `/root/...` (VPS)
- `ssh://...`
- Cualquier `IP:puerto`
- Comandos ejecutados via SSH
- Docker containers
- Servidores n8n, Supabase, Traefik, o cualquier servicio hosteado

**Si Claude Code esta conectado simultaneamente al Mac local Y a un VPS, este skill SOLO se activa para operaciones locales. Las operaciones en el VPS siguen sus propias reglas sin interferencia de este skill.**

---

## Regla 10 — Templates disponibles

Antes de crear un archivo desde cero, verificar si existe template en `_Sistema/Templates/`:

| Template | Para crear... |
|----------|--------------|
| `_tpl-sop.md` | Nuevo SOP |
| `_tpl-cliente-consultoria.md` | Nuevo cliente de consultoria |
| `_tpl-cliente-saas.md` | Nuevo suscriptor SaaS |
| `_tpl-agente.md` | Nuevo agente |
| `_tpl-departamento.md` | Nuevo departamento (requiere aprobacion) |
| `_tpl-content-hack.md` | Nueva pieza de content hacking |

Copiar el template, rellenar los campos, y ubicar en la carpeta correcta segun Regla 2.

---

## Protocolos de expansion

### Nuevo cliente
1. Identificar plan (Consultoria/Partner/SaaS)
2. Copiar template correspondiente
3. Crear carpeta en `02 Clientes/{Plan}/{Nombre}/`
4. Llenar ficha con datos iniciales

### Nuevo SOP
1. Copiar `_tpl-sop.md`
2. Ubicar en `03 SOPs/{Departamento}/`
3. Llenar frontmatter completo

### Nuevo agente
1. Crear carpeta en `00 Agentes/{Nombre Agent}/`
2. Copiar `_tpl-agente.md` como `Identidad.md`
3. Crear subcarpetas `Memoria/` y `Skills/`
4. Actualizar `00 Agentes/README.md`

### Nuevo tool
1. Crear carpeta en `01 Growth Engine/Tools/{Nombre}/`
2. Si tiene SOPs -> crearlos en `03 SOPs/Tools/{Nombre}/`
3. Si tiene credenciales -> agregar en `05 Credenciales/Servicios.md`

### Skill promovida a agente
1. Crear carpeta del agente en `00 Agentes/`
2. El agente departamental se convierte en orquestador
3. Actualizar `00 Agentes/README.md`
4. La estructura de `01 Growth Engine/` y `03 SOPs/` NO cambia

---

## Regla 11 — Que va (y que NO va) en Memoria/

La carpeta `00 Agentes/{Agente}/Memoria/` es el **contexto persistente entre sesiones** del agente. Guarda lo que el agente necesita recordar que no esta en el codigo ni en el vault general.

### Tipos validos en Memoria/

| Scope | Nombre de archivo | Contiene |
|-------|------------------|----------|
| `feedback` | `feedback_{tema}.md` | Correcciones y reglas del usuario ("no hagas X", "siempre haz Y") |
| `proyecto` | `proyecto_{nombre}.md` | Estado de proyectos activos: fase, decisiones, contexto — sin credenciales |
| `referencia` | `referencia_{sistema}.md` | DONDE encontrar info de un sistema (URL, carpeta, nombre) — NUNCA las keys |
| `usuario` | `usuario_{aspecto}.md` | Preferencias y estilo de Alejandro con ese agente |
| `contexto` | `contexto_{tema}.md` | Info de negocio relevante que informa decisiones entre sesiones |

### PROHIBIDO en Memoria/

**NUNCA guardar en Memoria/:**
- API keys
- Tokens de acceso
- Passwords o credenciales de cualquier tipo
- Valores de configuracion sensibles

Todo eso va en `05 Credenciales/APIs y Tokens.md`. Si un archivo de memoria necesita referenciar una credencial, escribir `Ver [[05 Credenciales/APIs y Tokens]]` — nada mas.

### MEMORY.md obligatorio

Cada `Memoria/` debe tener un archivo `MEMORY.md` que funciona como indice:
```markdown
# Memory — {Nombre Agente}

- [Titulo del archivo](nombre_archivo.md) — descripcion de una linea
```

---

## Regla 12 — Links internos obligatorios ([[]])

Obsidian es un grafo de conocimiento. Los nodos sin links son informacion muerta e irrecuperable. Todo archivo debe estar conectado.

### Patrones de linking por tipo

| Tipo de archivo | Debe linkear a... |
|----------------|------------------|
| `Memoria/referencia_*.md` | `[[05 Credenciales/APIs y Tokens]]` |
| `Memoria/proyecto_*.md` | `[[02 Clientes/{Plan}/{Cliente}]]` o `[[01 Growth Engine/{Depto}/...]]` |
| `Memoria/feedback_*.md` | Al SOP relacionado si existe |
| `00 Agentes/{X}/Identidad.md` | `[[00 Agentes/{X}/Memoria/MEMORY]]` + `[[Sistema de Agentes]]` |
| `02 Clientes/{Plan}/{Cliente}.md` | Al SOP de onboarding del plan |
| `02 Clientes/{Plan}/{Cliente}/Accesos.md` (sub-archivos) | `[[02 Clientes/{Plan}/{Cliente}/{Cliente}]]` (ficha principal del cliente) |
| `02 Clientes/{Plan}/{Cliente}/Credenciales.md` | `[[02 Clientes/{Plan}/{Cliente}/{Cliente}]]` (ficha principal del cliente) |
| `03 SOPs/{Depto}/SOP - *.md` | `[[01 Growth Engine/{Depto}/{Depto}]]` |
| `01 Growth Engine/{Depto}/{Depto}.md` | A sus SOPs y agentes responsables |
| `04 Content Hacking/{Pilar}/@*.md` | `[[{Pilar}]]` (su propio pilar — la carpeta donde vive) |

**Nota sobre content hacks**: El vínculo con Marketing NO va en cada `@{creador}` — va solo en `referencias.md`. Cada content hack linkea únicamente a su pilar.

Ejemplos correctos:
- `@mate.jimenez - 40 Reels.md` → `[[Negocios Digitales High Ticket]]`
- `@rpn - Claude Skills.md` → `[[Infraestructura IA y Claude y Gemini]]`
- `@chase_ai_ - 7 Niveles.md` → `[[Negocios Digitales High Ticket]]`

### Regla anti-duplicacion

**Nunca copiar contenido de otro archivo — siempre linkear.**

```markdown
# Correcto
Ver credenciales en [[05 Credenciales/APIs y Tokens]]

# Incorrecto
API Key: sk-abc123...
```

### Excepcion

`MEMORY.md` (indices) no requieren links outbound — son el punto de entrada.
