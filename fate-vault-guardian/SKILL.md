---
name: fate-vault-guardian
description: "Guardian de orden para un vault de Obsidian con estructura de agencia. Se activa al crear/editar/mover archivos .md en el vault local. SOLO Mac local, NUNCA VPS/SSH/remoto."
---

# Fate Vault Guardian

Leer `_Sistema/REGLAS.md` antes de cualquier operacion.

## Configuracion (adaptar antes de usar)

Antes de activar este skill, edita las siguientes lineas con tus propios valores:

```
VAULT_PATH: /tu/ruta/al/vault/        ← ruta local de tu vault
VAULT_MCP_NAME: nombre-de-tu-vault    ← nombre del vault en el MCP de Obsidian
```

## Scope

APLICA: `{VAULT_PATH}`, MCP obsidian `{VAULT_MCP_NAME}`
NO APLICA: VPS, SSH, /root/, IPs, Docker, Portainer, n8n hosteado, Supabase hosteado

## Estructura del vault

El vault asume esta estructura raiz:

```
_Sistema/          → Reglas, mapa y templates (solo el fundador puede editar)
00 Agentes/        → Definiciones de agentes IA
01 Growth Engine/  → Operacion interna (departamentos)
02 Clientes/       → Seguimiento por plan
03 SOPs/           → Procedimientos por departamento
04 Content Hacking/→ Inteligencia de contenido por pilar
05 Credenciales/   → APIs, tokens, servicios
```

6 departamentos dentro de `01 Growth Engine/`: Marketing, Ventas, Producto, Tools, Infraestructura IA, Finanzas.

## Routing critico

- Procedimientos/SOPs → `03 SOPs/{Depto}/` (NUNCA en `01 Growth Engine/`)
- Dashboards → `01 Growth Engine/{Depto}/{Depto}.md`
- Clientes → `02 Clientes/{Plan}/{Cliente}/`
- Conocimiento → `01 Growth Engine/{Depto}/{Sub-tema}/`
- Content externo → `04 Content Hacking/{Pilar}/`
- Credenciales → `05 Credenciales/`
- Memoria agente → `00 Agentes/{Agente}/Memoria/`

## Obligatorio en cada operacion

1. Frontmatter YAML (titulo, tipo, departamento, actualizado, autor)
2. Nomenclatura correcta:
   - SOP = `SOP - {Titulo}.md`
   - Dashboard = `{Depto}.md`
   - Content = `@{creador} - {Titulo}.md`
   - Agente = `Identidad.md`
   - Template = `_tpl-{tipo}.md`
3. Validar carpeta nueva con 5 pasos antes de crear
4. Sin acentos en nombres de carpeta
5. Consultar templates en `_Sistema/Templates/` antes de crear desde cero

## Frontmatter obligatorio

```yaml
---
titulo: "Nombre descriptivo"
tipo: sop | dashboard | ficha-cliente | content-hack | agente | conocimiento | credencial | memoria
departamento: marketing | ventas | producto | tools | infra-ia | finanzas | transversal
actualizado: YYYY-MM-DD
autor: {tu-nombre} | {nombre-agente}
---
```

## 5 pasos antes de crear una carpeta nueva

1. Pertenencia → ¿Pertenece a un depto? Va dentro
2. Existencia → ¿Ya hay carpeta? Usar la existente
3. Justificacion → "Necesaria porque ___ y no cabe en ___ porque ___"
4. Nivel → Sub-depto (libre) vs seccion raiz (aprobacion del fundador)
5. Consistencia → Sin acentos, dashboard creado, espejo en SOPs si aplica

## Prohibido sin aprobacion del fundador

- Crear/eliminar/renombrar seccion raiz (00-05)
- Crear/eliminar/renombrar departamento
- Crear pilar de contenido en Content Hacking
- Modificar REGLAS.md o MAPA.md

## Documento completo de reglas

Ver `_Sistema/REGLAS.md` en tu vault. Incluye reglas de permisos por seccion, reglas de memoria de agentes, links obligatorios por tipo de archivo y protocolo de expansion de agentes.
