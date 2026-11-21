# ARCHITECTURE.md — PolicyPal (worked example)

> A filled-in example so you can see what the skill produces. PolicyPal is a made-up
> product: a support chatbot that client companies load with their own policy PDFs.
> The model prices here are placeholders, not real quotes.
> Last reviewed: 2026-11-21

## 1. Sizing (the 4 questions)

| Question | Answer | Source / assumption |
|---|---|---|
| Users & frequency | 10 client companies, 300 daily users at launch, 3,000 in 12 months, 6 messages per user per day | ASSUMED, from two pilot conversations |
| Speed | First words on screen within 2 seconds (streamed), full answer within 10 | ASSUMED |
| Price | $150 per client company per month (B2B) | Founder's target price |
| Data touched | Customers' names and order details (personal data). Each client's policies are confidential to that client. No payments. | Confirmed |

## 2. Napkin math

```
python3 scripts/napkin.py --dau 300 --msgs 6 --in-tokens 3000 --out-tokens 300 --in-price 3 --out-price 15 --prompt-cache 0.5 --response-cache 0.15 --tenants 10 --price-per-tenant 150
```

| Metric | Value |
|---|---|
| Messages / month | 54,000 |
| Input tokens / month | 162M |
| Output tokens / month | 16.2M |
| LLM bill / month, no caching | $729.00 |
| LLM bill / month, with caching | $433.75 |
| LLM cost per tenant / month | $43.38 |
| Gross margin after LLM cost | 71% on $1,500 revenue |
| Hard spend cap set at provider | $870 / month |
| Prices | UNVERIFIED placeholder: $3 input, $15 output per 1M tokens |

What this told us: at $150 per client the product only just clears a 70% margin, and
only if caching works. Without caching the margin is 51%. Caching is part of launch.

## 3. Pattern (lowest rung that works)

Chosen: `RAG`

Why the rung below is not enough: a single call can't answer from a client's own
policy documents. A fixed workflow or an agent adds cost and debugging time and
answers no question that RAG can't.

## 4. The nine boxes

| Box | Choice now | Not needed until |
|---|---|---|
| Client | Next.js chat widget + admin upload page | — |
| API server / auth | Same Next.js app; login with organisations | — |
| Load balancer | None (the host handles it) | More than one server |
| Database | Managed Postgres | — |
| Cache | A table in Postgres, keyed by client | Cache lookups slower than 50 ms |
| Queue + workers | One small worker for PDF processing | — |
| Storage + CDN | Object storage for the PDFs | — |
| Monitoring | A `traces` table in Postgres | More than about 1M rows a month |
| LLM + vector search | One model behind a wrapper; pgvector in the same Postgres | Search slower than 200 ms |

## 5. Trust boundaries (Rule 2)

| Door into the prompt | Present? | Defence |
|---|---|---|
| User message | Yes | Treated as data, never as instructions; length limit |
| Retrieved documents / uploads | Yes | Wrapped and labelled as quoted material; model told to ignore instructions inside |
| Web pages | No | N/A — the bot doesn't browse |
| Tool results | No | N/A — no tools at launch |
| Model output shown as HTML or run as code | Yes (shown) | Rendered as plain text, HTML escaped |

Secrets in system prompt: **none**. Access rules live in the database queries.

## 6. Data guarding (Rule 3)

- Owner column on every row: `tenant_id` on documents, chunks, conversations, traces, cache
- Enforced in the query: Postgres row-level security on every table
- Retrieval filtered by tenant before similarity search: yes, in the same query
- Cache keys include: `tenant_id` + normalised question
- Cross-tenant leak test: `tests/tenant-isolation.test.ts` — client A asks for client B's refund policy and must get nothing

## 7. Failure design (Rule 4)

| Failure | Design |
|---|---|
| LLM slow | Timeout 20s, then try the fallback model |
| LLM provider down | One cheaper fallback model, then a "we'll email you" message |
| Wrong-shape output | JSON schema check; one retry |
| Retry duplicates an action | Idempotency key on "email transcript to support" |
| Loop runs away | N/A — no agent loop |
| Irreversible action | N/A — the bot can't issue refunds; it hands off to a person |
| Dependency down | Health check with increasing wait between retries |

## 8. Observability (Rule 5)

- Trace per request: auth → cache → embed → retrieve → prompt → LLM (tokens, cost, time) → check
- Tool: `traces` table in Postgres
- Cost per client: summed from traces each night
- Eval set: `evals/` — 20 real policy questions per pilot client, with expected answers
- Evals rerun on: every change to prompt, model or chunking
- Alerts: error rate above 2%, answers slower than 10s, daily spend above $40

## 9. Stack & scaling ladder

Stage now: `launch`

| Stage | Adds | Trigger |
|---|---|---|
| Launch | One app + managed Postgres with pgvector + one LLM behind a wrapper | — |
| Offload | Redis cache, a proper queue | Cache lookups over 50 ms, or PDF backlog over 5 minutes |
| Scale out | More copies of the app | CPU above 70% for an hour |
| Split | Read replicas, separate vector database | Search over 200 ms at 5M+ chunks |

Hosting: `containers` — serverless time limits were too tight for long streamed answers.

## 10. Open risks & decisions deferred

- Model prices are placeholders. Check them before quoting a price to clients.
- Scanned (image-only) PDFs are not supported at launch.
