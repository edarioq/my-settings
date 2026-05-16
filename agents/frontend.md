# Project Standards & Best Practices

This document outlines the coding standards, naming conventions, and architectural rules for this Expo + React Native project.

## Table of Contents
- [Project Context](#project-context)
- [Development Philosophy](#development-philosophy)
- [Architecture & Import Rules](#architecture--import-rules)
- [SOLID Principles](#solid-principles)
- [File Size Limits](#file-size-limits)
- [Naming Conventions](#naming-conventions)
- [Code Structure](#code-structure)
- [Design System](#design-system)
- [Data Fetching & Server State](#data-fetching--server-state)
- [Validation](#validation)
- [Navigation](#navigation)
- [Git Practices](#git-practices)
- [CI/CD](#cicd)

---

## Project Context

**[Project Name]** - React Native app for [brief description].

### Stack
- **Framework:** Expo (SDK managed workflow)
- **Language:** TypeScript (strict)
- **Styling:** Tailwind or Uniwind (Tailwind for React Native) + HeroUI or other
- **Data Fetching:** TanStack Query + Axios
- **Validation:** Zod
- **Linting & Formatting:** Biome
- **Package Manager:** pnpm only - never npm or yarn
- **CI/CD:** Fastlane + EAS

### Domain Terminology
Define your canonical terms here. Consistency across the entire codebase is non-negotiable.

| Use this          | Never use this              |
|-------------------|-----------------------------|
| `user`            | `account`, `member`         |
| `session`         | `login`, `auth_record`      |
| `notification`    | `alert`, `message`          |

---

## Development Philosophy

### The core rule: improve without breaking
Don't break what you don't own. If a task touches Screen A, Screen B must still work exactly as before. Changes are scoped to the task at hand. If you find a bug elsewhere, note it with `// TODO(debt):` and address it in a dedicated PR.

### How we approach existing code
- When we touch a component or feature, we improve what we find - but only what we touch.
- We do not refactor opportunistically across unrelated features.
- Debt is noted with `// TODO(debt):` and addressed in a dedicated PR.

### How we approach new code
- New features follow every standard in this document from the first line.
- No shortcuts, no "we'll clean it up later."

### What "production-ready" means here
- Explicit return types on every function and hook.
- Every component is typed - no prop `any`.
- No hardcoded values - colors, spacing, borders, shadows, and radii all come from the design system.
- No magic strings - use constants or enums for all fixed value sets.
- Fail fast with clear, user-facing error states.
- **Every file stays under 300 lines.**
- **Every component respects a single responsibility.**

---

## Architecture & Import Rules

This is the most important section. Violating the import rules creates circular dependencies and breaks the architecture.

```
app/
  ↓ imports from
features/
  ↓ imports from
components/
  (imports nothing from the app)

server/       <- imported by app/ and features/ only
hooks/        <- generic utility hooks, imported by anyone, no domain knowledge
lib/          <- configured infrastructure, imported by anyone (axios, query client, auth context)
utils/        <- pure stateless functions, imported by anyone (formatters, parsers, lists)
```

### Rules - strictly enforced

- **`app/`** → can import from `features/`, `components/`, `server/`, `hooks/`, `lib/`, `utils/`
- **`features/`** → can import from `components/`, `server/`, `hooks/`, `lib/`, `utils/` - cannot import from `app/`
- **`components/`** → can import from `hooks/`, `lib/`, `utils/` - cannot import from `app/`, `features/`, `server/`
- **`server/`** → can import from `lib/`, `utils/` only - cannot import from `app/`, `features/`, `components/`, `hooks/`
- **`hooks/`** → generic utility hooks only (`useDebounce`, `useKeyboard`, `useAppState`) - can import from `lib/`, `utils/` only - domain-specific hooks belong in `server/{domain}/`
- **`lib/`** → configured infrastructure only (axios instance, query client, auth context) - imports nothing internal
- **`utils/`** → pure stateless functions only (formatters, parsers, list helpers) - imports nothing internal - if a util references a domain type, it does not belong here

### Public API via index.ts
Every directory that is imported externally **must** expose its public API through an `index.ts` barrel file.

```typescript
// features/notifications/index.ts
export { NotificationList } from './notification-list';
export { NotificationBadge } from './notification-badge';
```

Never import directly from a file inside another directory:
```typescript
// Bad
import { NotificationList } from '@/features/notifications/notification-list';

// Good
import { NotificationList } from '@/features/notifications';
```

---

## SOLID Principles

These apply to components, hooks, and services alike - not just backend classes.

---

### S - Single Responsibility

**One component = one reason to change.**

A screen component that fetches data, validates a form, handles submission, AND renders the full layout has four reasons to change. Extract accordingly.

**How to apply:**
- Screens orchestrate - they wire data and layout, they do not contain logic.
- Features handle domain logic for a single domain concept.
- Components render - they do not fetch data or contain business logic.
- Hooks encapsulate one unit of stateful logic.

**Signals you are violating SRP:**
- The component name contains "And" (`LoginAndRegisterScreen`)
- The `useEffect` block is more than 10 lines
- The component renders AND manages a multi-step form state
- The file is approaching 300 lines

**Split pattern:**
```typescript
// Before - god screen
LoginScreen: fetch config, validate form, submit credentials, render inputs, render errors, handle navigation

// After - focused responsibilities
useLoginForm()      <- all form state and submission logic
LoginInputs         <- renders the input fields
LoginErrorBanner    <- renders the error state
LoginScreen         <- orchestrates the above, handles navigation
```

---

### O - Open/Closed

**Open for extension, closed for modification.**

Adding a new notification type should not require editing `NotificationBadge`. Add a new variant, not a new `if` block.

```typescript
// Bad
function NotificationBadge({ type }: Props) {
  if (type === 'INFO') return <Badge color="blue" />;
  if (type === 'WARNING') return <Badge color="amber" />;
  // adding ERROR requires editing this component
}

// Good
const TYPE_CONFIG: Record<NotificationType, BadgeConfig> = {
  INFO:    { color: 'blue',  label: 'Info' },
  WARNING: { color: 'amber', label: 'Warning' },
  ERROR:   { color: 'red',   label: 'Error' },
};

function NotificationBadge({ type }: Props) {
  const config = TYPE_CONFIG[type];
  return <Badge color={config.color} label={config.label} />;
}
```

---

### I - Interface Segregation

Keep props interfaces small and focused.

```typescript
// Bad - forces all consumers to handle all props
interface CardProps {
  title: string;
  subtitle?: string;
  imageUri?: string;
  onPress?: () => void;
  onLongPress?: () => void;
  isLoading?: boolean;
  isDisabled?: boolean;
  badgeCount?: number;
}

// Good - split by concern
interface CardBaseProps        { title: string; subtitle?: string; }
interface CardMediaProps       { imageUri: string; }
interface CardInteractionProps { onPress: () => void; onLongPress?: () => void; }
```

---

### D - Dependency Inversion

Components and hooks depend on abstractions, not concrete implementations.

```typescript
// Bad - tightly coupled to Axios
function useNotificationList() {
  const [data, setData] = useState([]);
  useEffect(() => {
    axios.get('/notifications').then(res => setData(res.data));
  }, []);
}

// Good - depends on the server/ abstraction
function useNotificationList() {
  return useQuery(notificationKeys.list(), notificationsApi.list);
}
```

---

## File Size Limits

### Hard limit: 300 lines per file

A file over 300 lines is evidence of an SRP violation.

**What to do when approaching the limit:**

| Situation | Action |
|---|---|
| Screen with complex form | Extract `useFormName` hook for all form state and submission |
| Screen with many sub-sections | Extract each section into a sub-component in `features/` |
| Feature with many components | Split into multiple focused files, re-export from `index.ts` |
| Hook doing too much | Split into focused hooks, compose them in a top-level hook |
| Large constants/config block | Extract to a dedicated `{domain}.constants.ts` file |

---

## Naming Conventions

### File Naming

**Pattern:** `{domain}-{purpose}.{type}.tsx|ts`

```
features/auth/
  ├── index.ts
  ├── auth-login-form.tsx
  ├── auth-session-banner.tsx
  └── auth-avatar.tsx

server/notifications/
  ├── notifications.api.ts
  ├── notifications.hooks.ts
  ├── notifications.keys.ts
  ├── notifications.types.ts
  └── index.ts
```

### Component Naming

**Pattern:** `{Domain}{Purpose}` - PascalCase

```typescript
export function AuthLoginForm() {}
export function AuthSessionBanner() {}
export function NotificationListItem() {}
export function UserProfileCard() {}
```

### Hook Naming

**Pattern:** `use{Domain}{Purpose}` - camelCase

```typescript
export function useAuthLogin() {}
export function useNotificationList() {}
export function useUserProfile() {}
```

### Screen Naming (inside `app/`)

Expo Router uses file-based routing. File names are lowercase with hyphens. The exported component is PascalCase.

```
app/
  ├── (tabs)/
  │   ├── index.tsx              → HomeScreen
  │   └── notifications.tsx      → NotificationsScreen
  ├── auth/
  │   ├── login.tsx              → LoginScreen
  │   └── register.tsx           → RegisterScreen
  └── profile/
      └── [id].tsx               → ProfileDetailScreen
```

### Constants & Enums

```typescript
// constants - SCREAMING_SNAKE_CASE
export const SESSION_REFRESH_INTERVAL_MS = 5 * 60 * 1000;

// enums - PascalCase name, SCREAMING_SNAKE_CASE values
export enum NotificationStatus {
  UNREAD   = 'UNREAD',
  READ     = 'READ',
  ARCHIVED = 'ARCHIVED',
  DELETED  = 'DELETED',
}
```

---

## Code Structure

### Full directory layout

```
src/
  ├── app/                        <- Expo Router screens and layouts
  │   ├── (tabs)/
  │   ├── _layout.tsx
  │   └── ...
  ├── components/                 <- Primitive, domain-agnostic components
  │   ├── ui/
  │   │   ├── button.tsx
  │   │   ├── input.tsx
  │   │   └── index.ts
  │   └── index.ts
  ├── features/                   <- Domain feature sets
  │   ├── auth/
  │   │   ├── index.ts
  │   │   ├── auth-login-form.tsx
  │   │   └── auth-session-banner.tsx
  │   └── notifications/
  │       ├── index.ts
  │       └── notification-list-item.tsx
  ├── server/                     <- API layer + TanStack Query
  │   ├── auth/
  │   │   ├── auth.api.ts
  │   │   ├── auth.hooks.ts
  │   │   ├── auth.keys.ts
  │   │   ├── auth.types.ts
  │   │   └── index.ts
  │   └── notifications/
  │       ├── notifications.api.ts
  │       ├── notifications.hooks.ts
  │       ├── notifications.keys.ts
  │       ├── notifications.types.ts
  │       └── index.ts
  ├── hooks/                      <- Generic, domain-agnostic utility hooks
  │   ├── use-debounce.ts
  │   └── use-app-state.ts
  ├── lib/                        <- Configured infrastructure
  │   ├── axios.ts                <- Axios instance + interceptors
  │   ├── query-client.ts         <- TanStack Query client config
  │   └── auth-context.tsx        <- Auth state + session context
  └── utils/                      <- Pure stateless helper functions
      ├── format-date.ts
      ├── format-currency.ts
      └── parse-error.ts
```

> **`lib/` is for things you configure. `utils/` is for things you call.**

### Server layer structure

Each domain in `server/` follows the same 4-file pattern:

```typescript
// notifications.keys.ts - query key factory
export const notificationKeys = {
  all:    ()           => ['notifications']                      as const,
  lists:  ()           => [...notificationKeys.all(), 'list']    as const,
  list:   (q?: string) => [...notificationKeys.lists(), q]       as const,
  detail: (id: string) => [...notificationKeys.all(), id]        as const,
};

// notifications.types.ts - Zod schemas + inferred types (colocated)
export const NotificationSchema = z.object({
  id:     z.string().uuid(),
  title:  z.string(),
  status: z.nativeEnum(NotificationStatus),
});
export type Notification = z.infer<typeof NotificationSchema>;

// notifications.api.ts - Axios calls only, no hooks
export const notificationsApi = {
  list:   (): Promise<Notification[]>         => api.get('/notifications').then(r => r.data),
  getOne: (id: string): Promise<Notification> => api.get(`/notifications/${id}`).then(r => r.data),
};

// notifications.hooks.ts - TanStack Query hooks for this domain
export function useNotificationList() {
  return useQuery({
    queryKey: notificationKeys.list(),
    queryFn:  notificationsApi.list,
  });
}

export function useNotificationDetail(id: string) {
  return useQuery({
    queryKey: notificationKeys.detail(id),
    queryFn:  () => notificationsApi.getOne(id),
  });
}
```

---

## Design System

**No hardcoded values. Ever.**

Colors, spacing, border radii, shadows, and font sizes are exclusively sourced from:
1. `global.css` - Tailwind/Uniwind design tokens
2. `/components` - Component variants

```typescript
// Bad
<View style={{ backgroundColor: '#FF3B30', padding: 16, borderRadius: 8 }} />

// Good
<View className="bg-danger p-4 rounded-lg" />
```

```typescript
// Bad
<Text style={{ fontSize: 24, fontWeight: 'bold', color: '#1C1C1E' }}>
  Hello
</Text>

// Good
<Text className="text-2xl font-bold text-foreground">
  Hello
</Text>
```

### Component variants over inline overrides

When a component needs a visual variant, extend it through the design system - do not patch it inline.

```typescript
// Bad
<Button style={{ backgroundColor: '#FF3B30' }}>Danger</Button>

// Good
<Button variant="danger">Danger</Button>
```

### StyleSheet is the last resort

Only use `StyleSheet.create` for platform-specific logic that Tailwind cannot express (e.g. `transform`, `shadow` on iOS with specific elevation needs). Document why with a comment.

---

## Data Fetching & Server State

### TanStack Query is the only client state for server data

Never use `useState` + `useEffect` to fetch data. No exceptions.

```typescript
// Bad
const [notifications, setNotifications] = useState([]);
useEffect(() => {
  notificationsApi.list().then(setNotifications);
}, []);

// Good
const { data: notifications, isLoading, error } = useNotificationList();
```

### Mutations follow a consistent pattern

```typescript
export function useNotificationMarkRead() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: notificationsApi.markRead,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: notificationKeys.lists() });
    },
  });
}
```

### Error handling

Never silently swallow errors. Every query and mutation must have an observable error state surfaced to the user.

```typescript
const { data, isLoading, error } = useNotificationList();

if (error) return <ErrorState message={error.message} />;
if (isLoading) return <LoadingState />;
```

---

## Validation

### Zod schemas are colocated with their types

Define the schema once, infer the type from it. Never define the type separately.

```typescript
// auth.types.ts
export const AuthLoginSchema = z.object({
  email:    z.string().email(),
  password: z.string().min(8),
});
export type AuthLoginDto = z.infer<typeof AuthLoginSchema>;
```

### Forms validate with Zod

Use a form library that integrates with Zod (e.g. `react-hook-form` + `@hookform/resolvers/zod`) rather than manual validation logic.

---

## Navigation

- All navigation lives in `app/` - Expo Router file-based routing only.
- Features and components are navigation-agnostic. They fire callbacks; screens handle navigation.
- Never import `router` from `expo-router` inside `features/` or `components/`.

```typescript
// Bad - feature driving navigation
function AuthLoginForm() {
  const router = useRouter();
  const onSuccess = () => router.push('/(tabs)');
}

// Good - screen owns navigation, passes callback down
function LoginScreen() {
  const router = useRouter();
  return <AuthLoginForm onSuccess={() => router.push('/(tabs)')} />;
}
```

---

## TypeScript Best Practices

- Strict mode on. No exceptions.
- Explicit return types on every exported function and hook.
- Never use `any`. Use `unknown`, a typed interface, or a generic.
- Never use non-null assertion (`!`) without a comment explaining why it is safe.
- Props interfaces are named `{ComponentName}Props`.

### Interfaces vs Types

**Always use interfaces for component props.** Interfaces are preferred because they can be extended. The TypeScript team recommends `interface extends` over type intersections (`&`) for better compiler performance and clearer error messages.

Use `type` only when you need features that interfaces do not support: union types, mapped types, conditional types, or type aliases for primitives.

```typescript
// Always - interface for props
interface NotificationListItemProps {
  onPress:  (notification: Notification) => void;
  onDismiss?: (id: string) => void;
}

// Extending - interface makes this clean
interface NotificationListItemWithActionsProps extends NotificationListItemProps {
  actions: NotificationAction[];
}

// Exception - type for unions or advanced patterns
type NotificationStatus = 'UNREAD' | 'READ' | 'ARCHIVED' | 'DELETED';
type UserWithAvatar = UserEntity & { avatar: MediaAssetEntity };
```

```typescript
export function NotificationListItem({ onPress, onDismiss }: NotificationListItemProps): JSX.Element {}
```

---

## Git Practices

**Always commit:** `eas.json`, `app.json`, `global.css`, `.env.example`

**Never commit:** `.env`, `node_modules/`, `.expo/`, `ios/`, `android/` (managed workflow)

### Commit Messages
```
feat(auth): add AuthLoginForm with email and password validation
fix(notifications): correct badge color for ERROR status
refactor(auth): extract useLoginForm hook from LoginScreen
style(components): align Button variants with design system tokens
```

---

## CI/CD

- EAS handles builds - never build locally for distribution.
- Fastlane handles submission to App Store and Play Store.
- `runtimeVersion` is hardcoded in `eas.json` - never use `fingerprint` in production channels to avoid OTA mismatch.
- OTA updates (expo-updates) are for `preview` and `production` channels only - never `development`.

---

## Pre-commit Checklist

- [ ] No file exceeds 300 lines
- [ ] No hardcoded colors, spacing, or radii - design system only
- [ ] No `useState` + `useEffect` for server data - TanStack Query only
- [ ] No navigation logic inside `features/` or `components/`
- [ ] No direct file imports across directory boundaries - use `index.ts`
- [ ] All exported functions and hooks have explicit return types
- [ ] No `any` types
- [ ] No `process.env` access outside `lib/`
- [ ] Zod schemas colocated with their types
- [ ] `pnpm` used exclusively - no `npm` or `yarn` commands
- [ ] No domain types imported inside `utils/` - pure functions only

## Pre-push Verification - MANDATORY

```bash
# TypeScript must compile cleanly
pnpm tsc --noEmit

# Biome lint must pass with zero errors
pnpm biome check .

# All unit tests must pass
pnpm test
```

---

## Summary

**Three non-negotiable constraints:**

1. **300 lines maximum per file.** Approaching the limit means a hook or sub-component needs to be extracted.
2. **Import rules are hard boundaries.** `components/` never imports from `features/`. `features/` never imports from `app/`. `lib/` imports nothing internal.
3. **Design system is the only source of truth for visual values.** No hardcoded colors, spacing, or radii anywhere in the codebase.
