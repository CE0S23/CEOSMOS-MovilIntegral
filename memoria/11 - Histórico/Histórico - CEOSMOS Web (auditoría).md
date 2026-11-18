---
tags: [ceosmos, historico]
estado: historico
actualizado: 2026-11-18
---

> [!warning] Nota histórica (anterior a la integración del 11/11/2026). Describe otros repositorios y propuestas; donde contradiga al código actual, gana el código. Ver [[09 - Decisiones técnicas]] y [[00 - Índice CEOSMOS]].

# Memoria Histórica - CEOSMOS Web

---

# 🛰️ REPORTE DE AUDITORÍA DE CÓDIGO — CEOSMOS WEB

**Fecha del análisis:** 20 de septiembre de 2026 | **Auditor:** Antigravity Senior Code Auditor

---

## 1. ARQUITECTURA Y TECNOLOGÍAS

### Estructura de Repositorio (Monorepo sin workspace manager)

```text
WEBANGULAR/
├── frontend/          → Angular 18 SPA
├── ceosmos-api/       → NestJS 11 REST API
├── backend/           → VACÍO (carpeta huérfana)
├── shared/            → VACÍO (carpeta huérfana)
└── package.json       → Solo deps de Prisma para scripting raíz
```

> **⚠️ Deuda inmediata:** `backend/` y `shared/` existen en el repo pero están completamente vacías. Son ruido estructural que puede generar confusión.

---

### Frontend — Angular 18

| Ítem | Valor |
|---|---|
| Framework | Angular **18.0.0** (Standalone Components) |
| UI Library | **PrimeNG 18** + PrimeIcons 7 + @primeuix/themes 2 |
| Routing | `provideRouter` con lazy-loading de componentes |
| Estilos | **SCSS** global (`styles.scss`) + estilos por componente |
| Estado global | **Angular Signals** (`signal`, `computed`) — sin NgRx ni Akita |
| HTTP | `HttpClient` con interceptor funcional (`authInterceptor`) |
| Auth extra | **WebAuthn / Passkeys** via `@simplewebauthn/browser ^13.3.0` |
| Despliegue | **Vercel** (`vercel.json` presente, reescritura de SPA configurada) |

**Árbol de módulos funcionales:**

```text
src/app/
├── app.routes.ts           → Router raíz con lazy-loading
├── core/
│   ├── services/           → AuthService, FeedDataService, TasksService,
│   │                          AdminService, SearchService, SiteSearchService,
│   │                          SeasonalThemeService, FilterService, SearchStateService
│   ├── guards/             → authGuard, guestGuard, adminGuard
│   ├── interceptors/       → authInterceptor (CSRF + 401 handler)
│   ├── models/             → user.model, feed-item.model, task.model
│   └── directives/         → (directorio existe, no se listaron archivos)
├── features/
│   ├── auth/               → login, register, verify-email, forgot-password, reset-password
│   ├── admin/              → admin dashboard, admin-users, admin-roles, admin-bitacora
│   ├── feed/               → flow-feed, feed-card
│   ├── layout/             → navbar, footer
│   ├── pages/              → landing, feed-page, privacidad
│   └── profile/            → profile
├── components/             → search-bar, player, visualizer, settings, external-links-menu
├── services/               → search.service.ts (duplicado - ver §4)
├── pages/                  → home, terminos (páginas legadas)
└── practicas/              → dom-demo, layout-showcase, pointer-menu, search-bar,
                               seasonal-theme, task-manager
```

**Patrón de Diseño Aplicado:**
- **Feature-based architecture** en `features/` (bien ejecutado)
- **Signal-based state management** (moderno, reactivo, sin boilerplate)
- **Functional guards** (Angular 14+ style) — ✅ correcto
- **Standalone Components** — 100% aplicado, sin `NgModule`
- `@defer (on viewport)` en el feed — ✅ lazy rendering de cards

---

### Backend — NestJS 11 (ceosmos-api)

| Ítem | Valor |
|---|---|
| Framework | **NestJS 11.0.1** |
| ORM | **Prisma 5.22.0** con adapter Neon |
| Lenguaje | TypeScript 5.7.3 |
| Auth | **JWT** (passport-jwt) + **WebAuthn** (@simplewebauthn/server 13.3) |
| Hashing | **bcrypt 6.0** |
| Correo | **Resend** + nodemailer (doble dependencia) |
| Rate Limiting | **@nestjs/throttler** — 10 req / 60 seg global |
| Seguridad | **Helmet** (HSTS, frameguard, noSniff, referrer-policy) |
| Middleware | CSRF propio (`csrfMiddleware`) |
| Despliegue | **Railway** (`railway.json` presente) |

**Módulos activos en AppModule:**
`ConfigModule · ThrottlerModule · PrismaModule · SessionsModule · MailModule · AuthModule · UsersModule · MediaModule · TasksModule · AdminModule · AuditModule · SearchModule`

---

## 2. BASE DE DATOS Y BACKEND

### Base de Datos

**PostgreSQL** en la nube vía **Neon** (serverless Postgres).
- URL: `ep-green-hall-anvbwgw9.c-6.us-east-1.aws.neon.tech` (región us-east-1)
- Adaptador: `@prisma/adapter-neon` (WebSocket pool)
- Feature flag activo: `previewFeatures = ["driverAdapters"]`

> **🚨 CRÍTICO — Credencial expuesta:** El archivo `ceosmos-api/.env` está commiteado con la `DATABASE_URL` real, el `JWT_SECRET` en texto plano y la `RESEND_API_KEY`. Aunque actualmente la clave Resend es un placeholder (`re_xxxx...`), el JWT secret y la conexión Neon son credenciales reales expuestas en el repositorio.

---

### Esquema Prisma — Modelos Implementados

| Modelo | Campos clave | Relaciones |
|---|---|---|
| `User` | id (UUID), email, username, passwordHash, emailVerified, role, active, failedLoginAttempts, lockedUntil, deletedAt | → Passkey, Session, EmailToken, Preferences, MediaItem, Task, AuditLog |
| `Passkey` | credentialId, userId, publicKey (Bytes), counter (BigInt), deviceType | → User |
| `Session` | id, userId, token, userAgent, ipAddress, expiresAt | → User |
| `EmailToken` | id, userId, code (SHA-256), type (VERIFY_EMAIL/RESET_PASSWORD), expiresAt, used | → User |
| `Preferences` | userId (unique), theme, flowTimeDefault | → User (1:1) |
| `MediaItem` | userId, type (YOUTUBE/IMAGE), externalId, url, title, thumbnail | → User |
| `Task` | userId, title, description, status (PENDIENTE/COMPLETADA), priority (BAJA/MEDIA/ALTA), dueDate, completedAt | → User |
| `AuditLog` | userId?, action (enum), timestamp, ipAddress, metadata (Json) | → User (nullable) |

**Enums activos:** `Role`, `EmailTokenType`, `MediaType`, `TaskStatus`, `TaskPriority`, `AuditAction`

---

### Rutas de API Existentes (prefijo `/api`)

#### Auth (`/api/auth`)

| Método | Ruta | Estado |
|---|---|---|
| POST | `/auth/register` | ✅ Funcional |
| POST | `/auth/verify-email` | ✅ Funcional |
| POST | `/auth/resend-verification` | ✅ Funcional |
| POST | `/auth/forgot-password` | ✅ Funcional |
| POST | `/auth/reset-password` | ✅ Funcional |
| POST | `/auth/login` | ✅ Funcional (brute-force lock) |
| POST | `/auth/logout` | ✅ Funcional (JWT guard) |
| POST | `/auth/webauthn/register/options` | ✅ Funcional |
| POST | `/auth/webauthn/register/verify` | ✅ Funcional |
| POST | `/auth/webauthn/login/options` | ✅ Funcional |
| POST | `/auth/webauthn/login/verify` | ✅ Funcional |

#### Users (`/api/users`)

| Método | Ruta | Estado |
|---|---|---|
| GET | `/users/me` | ✅ Funcional |
| GET | `/users/me/sessions` | ✅ Funcional |
| PATCH | `/users/me/profile` | ✅ Funcional |
| PATCH | `/users/me/preferences` | ✅ Funcional |
| DELETE | `/users/me` | ✅ Funcional (hard delete — ver §4) |

#### Admin (`/api/admin`)

| Método | Ruta | Estado |
|---|---|---|
| GET | `/admin/users` | ✅ Funcional |
| POST | `/admin/users` | ✅ Funcional |
| PATCH | `/admin/users/:id` | ✅ Funcional |
| PATCH | `/admin/users/:id/status` | ✅ Funcional |
| PATCH | `/admin/users/:id/password` | ✅ Funcional |
| PATCH | `/admin/users/:id/role` | ✅ Funcional |
| DELETE | `/admin/users/:id` | ✅ Soft delete |
| GET | `/admin/roles` | ✅ Funcional |
| GET | `/admin/audit-log` | ✅ Paginado |

#### Tasks (`/api/tasks`)

| Método | Ruta | Estado |
|---|---|---|
| GET | `/tasks` | ✅ Con filtros status/priority |
| POST | `/tasks` | ✅ Funcional |
| PATCH | `/tasks/:id` | ✅ Funcional |
| DELETE | `/tasks/:id` | ✅ Funcional |

#### Media (`/api/media`) y Search (`/api/search`)

Módulos presentes en `AppModule` y con controladores — no se auditaron en profundidad pero existen como rutas registradas.

---

## 3. ESTADO DE AVANCE

### ✅ COMPLETADO Y FUNCIONAL

| Área | Estado | Notas |
|---|---|---|
| **Sistema de autenticación completo** | ✅ | Email/password + WebAuthn/Passkeys + brute-force lock (5 intentos / 15 min) |
| **Verificación de email** | ✅ | Código SHA-256 con expiración de 15 min |
| **Flujo de reset de contraseña** | ✅ | Token seguro vía email |
| **Panel Admin - Listado de usuarios** | ✅ | Con filtrado del propio admin |
| **Panel Admin - CRUD usuarios** | ✅ | Editar, activar/desactivar, cambiar rol, eliminar (soft) |
| **Panel Admin - Bitácora de auditoría** | ✅ | Paginado, filtros por acción/usuario/fecha |
| **Panel Admin - Gestión de roles** | ✅ | Con mapa de permisos estático |
| **Guards de ruta** | ✅ | `authGuard`, `guestGuard`, `adminGuard` funcionales |
| **CSRF Protection** | ✅ | Cookie+header custom implementado |
| **Interceptor HTTP** | ✅ | Inyecta CSRF, `withCredentials`, maneja 401 global |
| **Sesiones de usuario** | ✅ | Tabla en BD, se listan en perfil |
| **Perfil de usuario** | ✅ | Ver datos, sesiones activas, registrar Passkey |
| **Flow Feed (UI)** | ✅ | Grid masonry con filtros, `@defer on viewport`, modal de detalle |
| **Feed - Búsqueda local** | ✅ | Filtrado por título/categoría en cliente |
| **Tema estacional** | ✅ | 4 paletas CSS, detección automática por mes, cambio manual |
| **Componentes de práctica** | ✅ | dom-demo, layout-showcase, pointer-menu, seasonal-theme, task-manager |
| **Página Landing** | ✅ | Componente existe (lógica mínima, solo `RouterLink`) |
| **Política de privacidad** | ✅ | Ruta registrada |
| **Despliegue** | ✅ | Vercel (frontend) + Railway (backend) configurados |

### ⚠️ PARCIAL / EN CONSTRUCCIÓN

| Área | Estado | Problema detectado |
|---|---|---|
| **Feed - Búsqueda con backend** | ⚠️ Parcial | `SearchService` en `app/services/` llama a `/api/search` pero tiene fallback a búsqueda local cuando el backend falla; hay un botón `🧪 Buscar "nature"` hardcodeado en producción |
| **`SeasonalThemeService`** | ⚠️ Incompleto | Los métodos `apply()` y `reset()` tienen cuerpos vacíos con comentario `// Moved to component` — la lógica de aplicar CSS variables fue movida al componente pero el servicio sigue exponiendo estos métodos nulos |
| **`MediaModule`** | ⚠️ Parcial | El módulo existe en el API y hay un modelo `MediaItem` en BD, pero el frontend solo tiene referencias al modelo, sin pantalla de gestión de media visible |
| **`GoogleCredential` en AuthService** | ⚠️ Muerto | El método `handleGoogleCredential()` parsea un JWT de Google manualmente (atob), pero no hay ningún botón "Iniciar con Google" en el frontend que lo llame |
| **`admin-roles` component** | ⚠️ Parcial | Existe el directorio y la ruta, muestra permisos estáticos desde `ROLES_PERMISSIONS` hardcodeado — no hay editor de permisos |

### ❌ NO IMPLEMENTADO / AUSENTE

| Área | Estado |
|---|---|
| **`backend/`** (carpeta raíz) | ❌ Vacía |
| **`shared/`** (carpeta raíz) | ❌ Vacía |
| **Notificaciones en tiempo real** | ❌ No existe WebSocket ni SSE |
| **Temporizador Pomodoro / Flow Timer** | ❌ `flowTimeDefault` existe en BD pero no hay UI |
| **Gestión de MediaItems desde el frontend** | ❌ Solo existe el modelo |
| **Tests E2E** | ❌ Solo specs unitarias de servicios (3 archivos `.spec.ts`) |
| **Dark/Light mode toggle** | ❌ Preferences tiene `theme` en BD pero no hay selector en UI |

---

## 4. DEUDA TÉCNICA Y ANTIPATRONES

### 🔴 CRÍTICOS

#### 1. `.env` commiteado con credenciales reales

**Archivo:** `ceosmos-api/.env`

El `DATABASE_URL` (Neon PostgreSQL), el `JWT_SECRET` y la URL del frontend están commiteados. Aunque `.env` está en el `.gitignore` del API, la presencia del archivo en el workspace indica que puede haberse filtrado en algún commit anterior.

```text
JWT_SECRET="[REDACTADO]"
DATABASE_URL="postgresql://neondb_owner:[REDACTADO]@..."
```

**Acción requerida:** Rotar credenciales inmediatamente. Agregar `.env` a `.gitignore` raíz. Usar variables de entorno de Railway/Vercel exclusivamente.

---

#### 2. Servicio de búsqueda duplicado con contratos distintos

Existen **tres** servicios de búsqueda con distintos contratos:

| Archivo | Retorna | Descripción |
|---|---|---|
| `core/services/search.service.ts` | `Observable<SearchResult[]>` | Búsqueda local sobre `FeedDataService` |
| `app/services/search.service.ts` | `Observable<FeedItem[]>` | Llama al backend + fallback local |
| `core/services/site-search.service.ts` | `SiteSearchResult[]` | Búsqueda de rutas del sitio |

`FlowFeedComponent` importa de `app/services/search.service` (con backend), mientras que `core/services/search.service` es un servicio paralelo que nunca se limpia. Esto es confusión de responsabilidades clara.

---

#### 3. Botón de debug en producción

**Archivo:** `frontend/src/app/features/feed/flow-feed/flow-feed.component.ts` (L33-L35)

```html
<button class="filter-btn test-btn" (click)="testSearch()">🧪 Buscar "nature"</button>
```

Un botón de prueba hardcodeado está visible en la UI del feed en producción.

---

#### 4. `console.log` masivos en producción

Se detectaron **22+ llamadas** a `console.log` con emojis de debug en archivos de producción:
- `flow-feed.component.ts` (6 ocurrencias)
- `app/services/search.service.ts` (7 ocurrencias)
- `components/search-bar/search-bar.component.ts` (4 ocurrencias)
- `register.component.ts`, `home.component.ts`, etc.

El interceptor HTTP de producción de Angular no elimina estos logs automáticamente. Fugan información de arquitectura interna.

---

### 🟡 MODERADOS

#### 5. `SeasonalThemeService` con métodos vacíos

**Archivo:** `seasonal-theme.service.ts` L106-L112

```typescript
reset(): void {
  // Moved to component
}
private apply(): void {
  // Moved to component
}
```

El servicio expone métodos públicos que no hacen nada. El componente que llama a `applySeason()` queda en estado inconsistente si depende de que `apply()` actualice el DOM.

---

#### 6. `handleGoogleCredential` es código muerto

**Archivo:** `auth.service.ts` L129-L145

Parsea un JWT de Google con `atob()` manualmente — no hay integración OAuth2 real, no hay `@angular/google-signin`, no hay botón en ningún template. Es código zombie.

---

#### 7. Hard delete en `/users/me`

**Archivo:** `ceosmos-api/src/users/users.service.ts` L94-L99

```typescript
await this.prisma.user.delete({ where: { id: userId } });
```

El endpoint de auto-borrado de cuenta hace un **hard delete** (elimina filas de la BD en cascada), mientras que el admin usa **soft delete** (`deletedAt`). Inconsistencia grave: los datos relacionados se pierden irreversiblemente.

---

#### 8. `console.log` en producción del API

**Archivo:** `ceosmos-api/src/auth/auth.service.ts`

El servicio de autenticación de NestJS usa `console.log` directamente en lugar del `Logger` de NestJS que ya tiene instanciado (`this.logger`):

```typescript
private readonly logger = new Logger(AuthService.name); // ← creado
console.log(`[AuthService] Registering user...`);       // ← ignorado
```

---

#### 9. Tipado débil con `any` en lógica crítica

Múltiples usos de `any` en código de autenticación:
- `async register(data: any)` en AuthService frontend
- `async login(data: any)` en AuthService frontend
- `(req as any).auditUserId` en auth.service.ts backend
- `role: (user as any).role` en users.service.ts

En un sistema de auth, estos `any` anulan las garantías de TypeScript precisamente donde más se necesitan.

---

#### 10. Inconsistencia en rutas de admin

Las rutas `/admin/usuarios`, `/admin/roles`, `/admin/bitacora` están definidas como rutas **planas** (hermanas del componente admin), no como hijas anidadas. El `adminGuard` se repite manualmente en cada ruta. El patrón correcto sería un `children` con `canActivateChild`:

```typescript
// Actual (repetitivo, frágil):
{ path: 'admin', canActivate: [adminGuard] },
{ path: 'admin/usuarios', canActivate: [adminGuard] },
{ path: 'admin/roles', canActivate: [adminGuard] },

// Correcto:
{ path: 'admin', canActivateChild: [adminGuard], children: [...] }
```

---

#### 11. `FilterService` mezcla localStorage con estado reactivo

**Archivo:** `filter.service.ts`

Usa `BehaviorSubject` (RxJS) para el estado pero `localStorage` para persistencia, mientras el resto del proyecto usa **Signals**. Es la única excepción al patrón y rompe la consistencia arquitectural.

---

#### 12. `fallback local` silencioso en búsqueda

**Archivo:** `app/services/search.service.ts` L118-L121

```typescript
// Si no hay coincidencias, devolver los filtrados para no mostrar vacío
if (results.length === 0) {
  return filtered; // ← Devuelve TODOS los ítems aunque no hubo match
}
```

La búsqueda sin resultados devuelve el feed completo en lugar de un estado vacío real. El usuario nunca ve "sin resultados".

---

## 5. CONTEXTO DE NEGOCIO — CEOSMOS

### UI y Feeds Visuales

- **Landing page** (`/home`): Existe como componente standalone con lógica mínima. El contenido visual es gestionado por el template HTML.
- **Flow Feed** (`/feed`): Implementado con **layout masonry en CSS Grid** (columnas múltiples). Las tarjetas (`FeedCardComponent`) son lazily renderizadas con `@defer (on viewport)` — implementación de rendimiento correcta.
- **Tipos de contenido en el feed:**
  - 12 imágenes hardcodeadas (Unsplash)
  - 6 pistas de música/video (YouTube embeds)
  - 4 frases de inspiración (quotes)
  - La mezcla se genera con una función `buildFeed()` con lógica de intercalado: 1 música cada 4 imágenes, 1 quote cada 6 imágenes.
- **Estado del feed**: 100% **datos hardcodeados en memoria** (`FeedDataService`). **No hay sincronización con el backend ni con ninguna API externa en tiempo real.** El modelo `MediaItem` existe en BD pero no está conectado al feed.
- **Filtros**: Por tipo (todo / imágenes / videos), con persistencia en `localStorage`.
- **Modal de detalle**: Abre imagen o YouTube embed. Si es imagen, busca "imágenes relacionadas" por categoría (búsqueda local).
- **Barra de búsqueda**: Conectada al servicio de búsqueda que intenta el backend y hace fallback a local.

### Tema Estacional

Sistema implementado con detección automática por mes del año y 4 paletas de variables CSS (primavera/verano/otoño/invierno). El servicio existe y cicla correctamente, pero los métodos `apply()` y `reset()` son cuerpos vacíos.

---

## RESUMEN EJECUTIVO

| Dimensión | Calificación | Notas |
|---|---|---|
| **Arquitectura** | 🟡 7/10 | Feature-based bien estructurado; `backend/`, `shared/` vacíos; duplicidad de servicios |
| **Seguridad** | 🔴 5/10 | `.env` con credenciales reales; hard delete inconsistente; JWT secret expuesto |
| **Completitud** | 🟡 6/10 | Auth completa, admin sólido; feed sin sincronización real; media sin UI |
| **Calidad de código** | 🟡 6/10 | Signals bien usados; exceso de `console.log`; `any` en auth; métodos vacíos |
| **Escalabilidad** | 🟡 6/10 | Feed hardcodeado no escala; sin cache; sin paginación en feed; rutas admin planas |
| **Tests** | 🔴 3/10 | Solo 3 archivos `.spec.ts` de servicios; sin tests de componentes ni E2E |

---

**Próximos pasos recomendados (por prioridad):**
1. 🚨 Rotar credenciales de Neon y JWT secret, agregar `.env` a `.gitignore`
2. 🧹 Eliminar `console.log` de producción (usar `Logger` de NestJS, sin logs en Angular prod)
3. 🔧 Resolver duplicidad de `SearchService` — elegir uno y eliminar el otro
4. 🔧 Eliminar el botón `🧪 Buscar "nature"` del template del feed
5. 🔗 Conectar el feed a la tabla `MediaItem` de la BD (la infraestructura ya existe)
6. 🏗️ Unificar `deleteAccount` a soft delete (igual que admin)
7. 🏗️ Refactorizar rutas de admin a `children` con `canActivateChild`
8. 🧪 Agregar tests de componentes para auth y admin