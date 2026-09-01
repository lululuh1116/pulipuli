# PuliPuli v2 — Phase 6A Foundation

This directory is an isolated React foundation. The repository root `index.html` remains the Legacy Production entry point and is not used by this app.

## Stack

- React + TypeScript + Vite
- React Router
- TanStack Query
- React Hook Form + Zod
- Tailwind CSS + CSS variable design tokens
- Vitest + React Testing Library

## Local development

Requirements: Node.js 20.19+ and pnpm.

```bash
cd v2
pnpm install
pnpm dev
```

Verification:

```bash
pnpm build
pnpm test
```

No secrets or cloud services are required. Phase 6A uses only the mock workspaces `pulipuli` and `yunlin-brand`.

## Workspace contract

Every workspace page lives below `/app/:workspaceId/*`. Server-state keys must keep the workspace ID directly after the domain name, for example:

```ts
['customers', workspaceId]
['appointments', workspaceId, filters]
['transactions', workspaceId, filters]
```

Never create a cross-workspace customer, appointment, or transaction cache.

## Routes

- `/auth/login`
- `/invite/:token`
- `/app`
- `/app/all-workspaces`
- `/app/:workspaceId/today`
- `/app/:workspaceId/appointments`
- `/app/:workspaceId/customers`
- `/app/:workspaceId/transactions`
- `/app/:workspaceId/analytics`
- `/app/:workspaceId/settings`

## Reserved feature boundaries

Current code implements only `auth`, `workspace`, and `today`. Later phases may add `appointments`, `customers`, `transactions`, `analytics`, `availability`, `ig-schedule`, `settings`, and `theme` under `src/features/` when those features gain real behavior. Empty placeholder files are intentionally omitted.

Do not connect Supabase Cloud, OAuth, production customer data, Legacy Gist data, or Cloudflare from this foundation.
