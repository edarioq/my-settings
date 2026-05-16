# Project Standards & Best Practices

This document outlines the coding standards, naming conventions, and best practices for this NestJS API project.

## Table of Contents
- [Project Context](#project-context)
- [Development Philosophy](#development-philosophy)
- [SOLID Principles](#solid-principles)
- [File Size Limits](#file-size-limits)
- [Naming Conventions](#naming-conventions)
- [Code Structure](#code-structure)
- [Configuration & Environment](#configuration--environment)
- [Module Seeders](#module-seeders)
- [API Standards](#api-standards)
- [Git Practices](#git-practices)
- [Database & TypeORM](#database--typeorm)

---

## Project Context

**[Project Name]** — Backend for [brief description].

### Stack
- **Runtime:** Node.js + TypeScript
- **Framework:** NestJS
- **ORM:** TypeORM
- **Database:** PostgreSQL
- **Package manager:** pnpm
- **Infrastructure:** Docker Compose

### Domain Terminology
Define your canonical terms here. Consistency across the entire codebase is non-negotiable.

| Use this          | Never use this              |
|-------------------|-----------------------------|
| `user`            | `account`, `member`         |
| `session`         | `login`, `auth_record`      |
| `refresh_token`   | `token`, `renewal_token`    |

### Key Business Rules
Document the invariants that the system must always enforce. Examples:

- A user **must** be authenticated before accessing protected resources.
- Session expiration TTL is **configurable from the database** — no hardcoded values, no deploys to change it.
- Token rotation is **atomic** — issuing a new refresh token and invalidating the old one happen in the same transaction.
- Every operation must carry a `requestId` for tracing and auditing.

### State Machines
Document any entity that follows a state machine. Example using a session lifecycle:

```
PENDING  → ACTIVE    (on successful credential verification)
ACTIVE   → EXPIRED   (on TTL exceeded)
ACTIVE   → REVOKED   (on explicit logout or security event)
PENDING  → CANCELLED (on verification failure)
```

---

## Development Philosophy

### The core rule: improve without breaking
Every change must be backwards-compatible. Existing behavior is never altered unless that is the explicit goal of the task.

### How we approach existing code
- When we touch a module, we improve what we find — but only what we touch.
- We do not refactor opportunistically across unrelated modules.
- Debt is noted with `// TODO(debt):` and addressed in a dedicated PR.

### How we approach new code
- New modules follow every standard in this document from the first line.
- New code is where we demonstrate the level — no shortcuts.

### What "production-ready" means here
- Explicit return types on every public method.
- Every thrown exception uses a standard NestJS exception class.
- Every DB operation that modifies state runs inside a transaction or uses atomic SQL (`UPDATE ... RETURNING`).
- No magic strings — enums for all fixed value sets.
- Fail fast with a clear, machine-readable error code.
- **Every file stays under 250 lines.**
- **Every class respects SOLID.**

---

## SOLID Principles

These are non-negotiable. Every class in this project must comply.
Violations found during a PR must be fixed before merge — no exceptions.

---

### S — Single Responsibility Principle

**One class = one reason to change.**

A service that validates credentials, sends emails, manages sessions, and queries the
database has four reasons to change. That is four classes, not one.

**How to apply:**
- A service handles one domain concept: `AuthSessionsService` manages session
  lifecycle. It does not handle notifications, media uploads, or user profiles.
- A service that does both business logic AND data transformation needs to
  be split: extract a mapper or a helper.
- Controllers only receive requests, delegate to services, and return responses.
  No business logic in controllers. Ever.

**Signals you are violating SRP:**
- The class name contains "And" (`AuthAndNotificationService`)
- The constructor injects more than 4 dependencies
- The file is approaching the 250-line limit
- Methods in the class do not share any domain concept

**Split pattern:**
```typescript
// Before — one god service
AuthService: login, logout, refreshToken, validateCredentials,
             sendVerificationEmail, buildOtpCode, revokeAllSessions,
             decrementLoginAttempts

// After — focused services
AuthSessionsService:    login, logout, refreshToken, revokeAllSessions
AuthCredentialService:  validateCredentials, decrementLoginAttempts
AuthOtpService:         generateOtp, validateOtp, scheduleExpiry
AuthTokenService:       issueAccessToken, issueRefreshToken, verifyToken
```

---

### O — Open/Closed Principle

**Open for extension, closed for modification.**

Adding a new notification channel should not require editing `NotificationsService`.
Adding a new storage provider should not require editing `MediaAssetsService`.

**How to apply:**
- Use strategy pattern for swappable behavior (notification channels, storage providers).
- Use enums + map for variant handling — add a new case without touching existing logic.
- Never add `if (type === 'new_thing')` inside an existing service method.
  Extract an interface and inject the implementation.

**Example:**
```typescript
// Bad — closed for extension, open for modification
private send(notification: NotificationEntity): void {
  if (notification.channel === 'EMAIL') { ... }
  if (notification.channel === 'SMS') { ... }
  // adding PUSH requires editing this method
}

// Good — each channel is its own class
interface NotificationChannelAdapter {
  send(payload: NotificationPayload): Promise<void>;
}

class EmailAdapter implements NotificationChannelAdapter { send(payload) { ... } }
class SmsAdapter   implements NotificationChannelAdapter { send(payload) { ... } }
class PushAdapter  implements NotificationChannelAdapter { send(payload) { ... } }
```

---

### L — Liskov Substitution Principle

**Subclasses must be substitutable for their base class.**

In this codebase this primarily applies to:
- Guards — any guard extending `AuthGuard` must honor the contract
  (attach principal to request or throw `UnauthorizedException`)
- Interceptors — must not break the request/response chain
- Adapters — must fulfill the interface contract fully

**Violation signal:** a subclass throws `NotImplementedException` or
overrides a method to do nothing.

---

### I — Interface Segregation Principle

**No class should be forced to implement methods it does not use.**

**How to apply:**
- Keep interfaces small and specific.
- A `StorageProviderAdapter` that requires both `upload()` and `stream()`
  forces local providers to implement streaming they cannot support.
  Split into `UploadCapable` and `StreamCapable`.
- DTOs are interfaces in disguise — keep them focused on one operation.
  `UserCreateDto` is not the same as `UserUpdateDto`. Never merge them.

**Split pattern:**
```typescript
// Bad — forces all implementations to handle all methods
interface MediaService {
  upload(file: Buffer): Promise<string>;
  stream(key: string): ReadableStream;
  transcode(key: string): Promise<void>;
}

// Good — split by capability
interface UploadCapable    { upload(file: Buffer): Promise<string>; }
interface StreamCapable    { stream(key: string): ReadableStream; }
interface TranscodeCapable { transcode(key: string): Promise<void>; }
```

---

### D — Dependency Inversion Principle

**Depend on abstractions, not concretions.**

**How to apply:**
- Services depend on interfaces/tokens, not concrete classes,
  wherever the implementation is swappable.
- Configuration values are injected via `ConfigService`,
  never read directly from `process.env`.
- Database access goes through injected `Repository<T>` or `DataSource`,
  never imported as a singleton.

**Example:**
```typescript
// Bad — tightly coupled to a specific implementation
constructor(private readonly s3Client: S3Client) {}

// Good — depends on an abstraction
constructor(
  @Inject(STORAGE_PROVIDER)
  private readonly storage: StorageProviderAdapter,
) {}
```

---

## File Size Limits

### Hard limit: 250 lines per file

This is not a guideline. It is a constraint enforced at review time.
A file that exceeds 250 lines is evidence of an SRP violation.

**What counts toward the 250 lines:**
All lines including decorators, imports, blank lines, and comments.

**What to do when approaching the limit:**

| Situation | Action |
|---|---|
| Service with many methods | Extract by method group into sub-services |
| Large entity with many columns | Split into entity + embedded value objects |
| Controller with many endpoints | Split into resource + sub-resource controller |
| DTO with many fields | Split into base DTO + extension DTOs |
| Large migration | Split into multiple focused migrations |

**Splitting a service — naming pattern:**
```
// Original (too large)
AuthService  →  250+ lines

// Split by responsibility
AuthSessionsService     ← session lifecycle       (login, logout, refresh, revoke)
AuthCredentialService   ← credential operations   (validate, hash, compare)
AuthOtpService          ← OTP logic               (generate, verify, expire)
AuthTokenService        ← token operations        (issue, verify, rotate)
```

All split services register in the same module.
The module file itself must also stay under 250 lines.

---

## Naming Conventions

### File Naming
All files within a domain directory must be prefixed with the parent directory name.

**Pattern:** `{domain}-{purpose}.{type}.ts`

**Examples:**
```
src/modules/auth/
  ├── auth.module.ts
  ├── controllers/
  │   └── auth.controller.ts
  ├── dto/
  │   ├── auth-login.dto.ts
  │   ├── auth-register.dto.ts
  │   └── auth-response.dto.ts
  └── services/
      ├── auth-sessions.service.ts
      ├── auth-credentials.service.ts
      ├── auth-otp.service.ts
      └── auth-tokens.service.ts
```

**Bad:**
- `login-auth.dto.ts`
- `token-validation.service.ts`
- `admin-auth.controller.ts`

**Good:**
- `auth-login.dto.ts`
- `auth-token-validation.service.ts`
- `auth-admin.controller.ts`

### Class Naming

**Pattern:** `{Domain}{Purpose}{Type}`

```typescript
export class AuthLoginDto {}
export class AuthRegisterDto {}
export class AuthResponseDto {}
export class AuthController {}
export class AuthSessionsService {}
export class AuthCredentialService {}
export class AuthOtpService {}
export class AuthTokenService {}
```

### Method Naming

**Pattern:** `{crudVerb}{Entity}` — singular or plural based on operation

```typescript
async listSessions(query: SessionsListQueryDto): Promise<SessionsListResponseDto>
async getSession(id: string): Promise<SessionsGetResponseDto>
async createSession(dto: SessionsCreateDto): Promise<SessionsCreateResponseDto>
async updateSession(id: string, dto: SessionsUpdateDto): Promise<SessionsGetResponseDto>
async deleteSession(id: string): Promise<void>

// Private helpers
private mapToDetail(session: SessionEntity): SessionsGetResponseDto
private validateToken(token: string): void
private buildSessionKey(userId: string, deviceId: string): string
```

---

## Code Structure

### Module Organization

```
src/modules/{domain}/
  ├── {domain}.module.ts
  ├── controllers/
  │   ├── {domain}.controller.ts
  │   └── {domain}-admin.controller.ts
  ├── dto/
  │   ├── index.ts
  │   ├── {domain}-create.dto.ts
  │   ├── {domain}-update.dto.ts
  │   ├── {domain}-list.dto.ts
  │   └── {domain}-response.dto.ts
  ├── entities/
  │   └── {domain}.entity.ts
  ├── interfaces/
  │   └── {domain}.interface.ts
  ├── seeders/
  │   └── {domain}.seeder.ts
  └── services/
      ├── index.ts
      ├── {domain}.service.ts              ← main orchestrator (≤250 lines)
      └── {domain}-{concern}.service.ts    ← focused sub-services (≤250 lines each)
```

### Service Layer — section headers required

```typescript
@Injectable()
export class AuthSessionsService {

  constructor(
    @InjectRepository(SessionEntity)
    private readonly sessionRepo: Repository<SessionEntity>,
    private readonly credentialService: AuthCredentialService,
    private readonly tokenService: AuthTokenService,
  ) {}

  // ============================================
  // PUBLIC METHODS — Session Lifecycle
  // ============================================

  async login(...): Promise<AuthLoginResponseDto> {}
  async logout(...): Promise<void> {}
  async refresh(...): Promise<AuthRefreshResponseDto> {}
  async revokeAll(...): Promise<void> {}

  // ============================================
  // PRIVATE HELPERS — Mapping
  // ============================================

  private mapToResponse(session: SessionEntity): AuthResponseDto {}
}
```

**Maximum 4 injected dependencies per service.**
If you need more than 4, the class is doing too much — split it.

---

## Configuration & Environment

- Centralized configuration lives in `src/config`:
  - `app.config.ts` — `APP_*` values
  - `db.config.ts` — `DATABASE_URL`
  - `logger.config.ts` — Winston transports
  - `validation.ts` — Joi schema
- Always add new env variables to `.env.example` and the Joi schema.
- Access config through `ConfigService` helpers — never `process.env` in services.

Checklist when introducing a new config value:
1. Extend `environmentValidationSchema`.
2. Update the relevant `registerAs` config file.
3. Document in `.env.example`.
4. Inject `ConfigService` where needed.

---

## Module Seeders

- Each domain module gets its own `seeders/` directory.
- Seeder class exports a `run(count?: number)` method.
- Accepts a TypeORM `DataSource` — composable in `scripts/seed.ts`.
- Seeder files must also respect the 250-line limit.

---

## API Standards

### Endpoint Structure
```
/api/v1/{resource}           # Public endpoints
/api/v1/admin/{resource}     # Admin endpoints
```

### HTTP Methods & Status Codes
- `GET`    → 200 OK
- `POST`   → 201 CREATED
- `PATCH`  → 200 OK
- `DELETE` → 204 NO CONTENT

### Error Responses
```typescript
throw new BadRequestException({ error: 'VALIDATION_ERROR', details: [...] });
throw new UnauthorizedException({ error: 'SESSION_EXPIRED' });
throw new NotFoundException(`User with ID ${id} not found`);
throw new ConflictException({ error: 'SESSION_INVALID_TRANSITION', from, to });
throw new UnprocessableEntityException({ error: 'INVALID_REFRESH_TOKEN' });
```

### Response Formats

**List:** `{ "sessions": [...], "total": 45 }`

**Get:** return resource object directly.

**Create:** `{ "id": "uuid", "status": "ACTIVE", "createdAt": "..." }`

---

## Git Practices

**Always commit:** migration files, `docker-compose.yaml`, `.env.example`

**Never commit:** `.env`, `node_modules/`, `dist/`, database files

### Commit Messages
```
feat(auth): add SessionGuard with bearer token validation
fix(auth): correct expiry check in refreshToken
refactor(notifications): extract ChannelDispatchService from NotificationsService
test(auth): add session state machine transition coverage
```

### PR Issue Linking Policy
- Do **not** use auto-close keywords in PR descriptions/commits: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`.
- Use non-closing references only: `links to #<issue>`, `relates to #<issue>`, or `issue #<issue>`.

---

## Database & TypeORM

### Entity Conventions
- `@Column({ name: "snake_case" })` for all columns
- `@PrimaryGeneratedColumn('uuid')` for IDs
- `@Index()` on all FK columns and frequently filtered fields
- Enums in `src/modules/shared/enums/enums.ts`

### Atomic Database Operations

The only allowed pattern for state-modifying operations that must be race-condition free:
```typescript
// ATOMIC: do not replace with ORM read-write pattern.
// TypeORM PostgresQueryRunner returns [rows, rowCount] tuple for UPDATE/DELETE.
// Always destructure — NEVER treat the result as a flat rows array.
const [rows] = await this.dataSource.query(
  `UPDATE sessions
   SET status = $1, updated_at = NOW()
   WHERE id = $2 AND status = $3
   RETURNING id, status`,
  [SessionStatus.REVOKED, sessionId, SessionStatus.ACTIVE],
);

if (!rows.length) {
  throw new ConflictException({ error: 'SESSION_INVALID_TRANSITION' });
}
```

### Migrations
- A committed migration is a contract. Never edit it. Create a new one.
- Use `IF NOT EXISTS` / `IF EXISTS` for safety.
- One migration per logical schema change.

---

## TypeScript Best Practices

- Explicit return types on every public method.
- Never use `any`. Use `unknown`, a typed interface, or a generic.
- Use entity intersection types for relations:

```typescript
type UserWithSessions = UserEntity & { sessions: SessionEntity[] };
```

- Use nullish coalescing and optional chaining:

```typescript
const locale = user.preferences?.locale ?? 'en';
const avatarUrl = user.media[0]?.url ?? null;
```

---

## Professional Code Standards

### What to Avoid
- Magic strings or numbers — use enums
- Deep nesting — extract to private methods
- God classes — constructor with 5+ deps = split the class
- Unnecessary comments — code must be self-documenting
- Emojis in code or comments
- `process.env` outside `src/config`
- `any` type
- Files over 250 lines

### Pre-commit Checklist
- [ ] No file exceeds 250 lines
- [ ] Each class has a single reason to change (SRP)
- [ ] No constructor has more than 4 dependencies
- [ ] No business logic in controllers
- [ ] All public methods have explicit return types
- [ ] All state-modifying DB ops use transactions or `UPDATE...RETURNING`
- [ ] All new enums are in `enums.ts`
- [ ] No `process.env` outside `src/config`
- [ ] No `any` types

### Pre-push Verification — MANDATORY

**Before every commit that touches source code, run these checks locally.
CI will reject the push if any fail. Do NOT push hoping CI will pass — verify first.**

```bash
# 1. TypeScript must compile cleanly
pnpm tsc --noEmit

# 2. All unit tests must pass
pnpm test:unit

# 3. If integration test files were added or modified, verify them locally
#    (requires docker compose -f docker-compose.test.yaml up -d)
pnpm test:int
```

**Common mistakes that break CI — check every time:**

| What to check | Why it breaks | How to verify |
|---|---|---|
| New entity added | `test-db.module.ts` `testEntities` array must include it, or TypeORM metadata resolution fails for all int-specs | Grep entity imports in `test-db.module.ts` |
| Entity relation added (`@ManyToOne`, `@OneToMany`) | The related entity must also be in `testEntities` | Check both sides of the relation |
| New dependency injected into a service | Every `int-spec.ts` that creates a `TestingModule` with that service must provide or mock the new dependency | Search `grep -rn "ServiceName" src/**/*.int-spec.ts` |
| Module removed or renamed | Remove imports, entity references, and test files that reference it | `pnpm tsc --noEmit` catches dead imports |
| `dataSource.query()` or `manager.query()` with UPDATE/DELETE | TypeORM PostgresQueryRunner returns `[rows, rowCount]` tuple, NOT a flat rows array. Always destructure: `const [rows] = await ...query(...)` | See [Atomic Database Operations](#atomic-database-operations) |
| Mock returns `undefined` by default | If the service has a fallback path that calls the mock, `undefined` causes `TypeError`. Mocks must reject or return realistic data matching the real service behavior | Review every `jest.fn()` — does the real method throw or return? |

---

## Summary

**Two non-negotiable constraints:**

1. **250 lines maximum per file.** A file over 250 lines is an SRP violation.
2. **SOLID in every class.** Verified at review time, not as an afterthought.

These constraints make the codebase:
- Readable in one screen
- Testable in isolation
- Extensible without modifying existing logic
- Easy to onboard for new developers
