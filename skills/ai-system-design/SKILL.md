---
name: ai-system-design
description: Use when starting any new project, app, SaaS, chatbot, RAG, agent or LLM feature, before writing implementation code or scaffolding; when a project has no ARCHITECTURE.md; when adding a feature that touches an LLM, other users' data, money, or a new external service; or when asked about system design, scaling, cloud bill, token cost, or "will this hold up with real users".
---

# AI System Design Pre-flight

## Overview

AI made the demo free. It did nothing for the real system: strangers, a monthly bill, other people's data, bad days. **Someone still has to decide the system — do it before the first line of code, and write it down in `ARCHITECTURE.md`.**

The LLM is one of nine boxes. When AI products fail, it is usually one of the other eight.

## When to Use

- New project or empty repo, any stack
- Project exists but has no `ARCHITECTURE.md`
- New feature that adds an LLM call, multi-tenant data, payments, or a new third-party dependency
- Skip only for: throwaway scripts, single static pages, edits that don't change any of the nine boxes

If `ARCHITECTURE.md` already exists: read it first, check the change against sections 5–7, update the affected sections and the "Last reviewed" date.

## The Process (produces ARCHITECTURE.md)

1. **Ask the 4 sizing questions** in one message, each with a default in brackets:
   users & frequency · latency budget · price (per user for B2C, **per client company for B2B**) · what data it touches.
   Run steps 2–3 on the defaults in the same reply so the user sees a draft bill, not just questions. If the user says "go", "defaults" or "ship fast", proceed on the defaults and mark each one `ASSUMED` in section 1 — the pre-flight still happens.
2. **Run the napkin math.** Look up current model prices (provider pricing page or openrouter.ai). If you cannot look them up, use a placeholder and write `UNVERIFIED placeholder` next to it in section 2 and in your reply. All prices are **USD**; `--fx` only adds a local-currency column.
   - B2C: `python3 ~/.claude/skills/ai-system-design/scripts/napkin.py --dau … --msgs … --in-tokens … --out-tokens … --in-price … --out-price … --price-per-user …`
   - B2B: same, but `--tenants … --price-per-tenant …` instead of `--price-per-user`
   - Add `--prompt-cache`, `--response-cache`, `--fx` (INR rate) when known. Paste command + output into section 2.
3. **Pick the lowest rung** of the pattern ladder that works (below). Justify anything above RAG.
4. **Copy the template** `~/.claude/skills/ai-system-design/templates/ARCHITECTURE.md` to the project root and fill every section. `N/A — reason` is allowed; blank is not.
   **Day-one depth:** sections 1–6 in full. Sections 7–9 can be one line per row for the launch stage (e.g. "timeout 20s, fallback: one cheaper model") — the row must exist, the detail can grow later.
5. **Seed BUILD.md**: put the napkin numbers under *Golden numbers* and the scale triggers under *Next action / Traps* as relevant.
6. **Show the user** the sizing table, the monthly bill, and any red flag (margin < 70%, secrets in prompt, no tenant filter). Then hand off to `spec` / `writing-plans` / implementation.

## The Five Rules

| # | Rule | Means in practice |
|---|---|---|
| 1 | **Size it before you build it** | Napkin math on users, speed, cost per user, data. Most early apps need to stay cheap, not scale. |
| 2 | **Treat every input as untrusted** | 5 doors into the prompt: user message, retrieved docs, web pages, tool results, model output rendered/executed. A system prompt is a polite request — never put secrets or access rules in it. See OWASP Top 10 for LLM Apps. |
| 3 | **Guard the data** | Access control lives in the query (`WHERE tenant_id = $current`, or RLS), not the prompt. Filter by tenant **before** retrieval. Key every cache by tenant (+ user). Write a cross-tenant leak test. |
| 4 | **Assume it fails** | LLM = flaky third-party API: slow, expensive, unpredictable, sometimes down. Timeout every call, fallback model chain behind one wrapper, schema-validated JSON output, idempotency keys on retried actions, step + cost caps on loops, human approval for irreversible actions, backoff on health checks. |
| 5 | **Measure everything** | Trace every request (auth → cache → embed → retrieve → prompt → LLM tokens/cost/latency → validate). Track cost per user. Keep an eval set; rerun on every prompt/model/chunking change. Treat prompts as code. |

## Pattern Ladder (every rung up costs money, predictability, debugging time)

1. **Single call** — summarize, classify, extract
2. **RAG** — answer from your own docs (most support bots, internal search, doc assistants)
3. **Fixed workflow** — known steps in a known order (onboarding: email → name → phone → OTP → confirm)
4. **Agent** — only when the steps genuinely cannot be known in advance. Most overused pattern today.

RAG debugging: most RAG failures are retrieval failures. **Check the chunk before you blame the model** — inspect what actually reached the prompt; fix chunking before touching prompt or model.

## Start Boring — Scaling Ladder

| Stage | What | Move on only when a real number says so |
|---|---|---|
| Launch | One monolith (e.g. Next.js), managed Postgres + pgvector (Supabase / RDS), one LLM behind a provider wrapper (env-switchable, e.g. OpenRouter), tracing from day one | — |
| Offload | Redis (cache, sessions, rate limits), queue + workers (SQS etc.), load balancer | p95 latency, repeated identical queries, long jobs blocking requests |
| Scale out | Stateless replicas behind the LB | CPU/instance saturation |
| Split | Read replicas, DB split, dedicated vector DB | pgvector provably can't keep up |

Storage: relational → Postgres; vectors → pgvector; cache/session/rate-limit → Redis; files → S3/R2/GCS.
Hosting: serverless for spiky traffic and zero ops (**check function time limits vs long LLM calls**); containers for steady load, long jobs, workers; VPS when cheapest + full control (you own uptime and backups).
Database habits: index, migrations for schema changes, backups, **tested** restore.

Founders don't need microservices, Kubernetes or a separate vector DB to launch. The engineering skill is knowing which number means it's time for the next box.

## Cost Levers (in order of effort)

Response cache (keyed by tenant) → provider prompt caching (stable prefix first) → fewer input tokens (smaller chunks, trimmed history) → model routing (cheap model for easy queries) → streaming (perceived latency, not cost). Always set a hard spend cap at the provider and per-key rate limits — a leaked key can bankrupt you overnight.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Plan with no bill | Run napkin.py; no ARCHITECTURE.md section 2 = not done |
| Tenant isolation only in app code or prompt | Enforce in query/RLS + leak test |
| Response cache keyed by question only | Key = tenant + user scope + normalized question |
| No timeout / single provider | Timeout + fallback chain in the wrapper |
| Free-text LLM output parsed with regex | JSON schema + validation + retry once |
| Retry sends the email twice | Idempotency key |
| Jumping to agents | Climb the ladder; justify each rung |
| No traces until something breaks | Trace table / Langfuse on day one |
| Serverless timeout kills long LLM calls | Stream, or move to a worker |

## Red Flags — stop and fix before coding

- No numbers for DAU, tokens per call, or price per user
- Secret, password, or "only show X to Y" rule inside a system prompt
- Similarity search that runs before the tenant filter
- Any action that cannot be undone, triggered by model output with no human approval
- "We'll add logging later"
