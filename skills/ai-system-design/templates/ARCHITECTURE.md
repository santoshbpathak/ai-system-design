# ARCHITECTURE.md — <project name>

> Design decisions made BEFORE building. Every section is required.
> Write `N/A — <reason>` instead of deleting a section. Update when a scale trigger fires.
> Last reviewed: <YYYY-MM-DD>

## 1. Sizing (the 4 questions)

| Question | Answer | Source / assumption |
|---|---|---|
| Users & frequency — DAU at launch, DAU in 12 months, actions per user per day | | |
| Speed — latency budget per user action; sync, async, streaming or cached? | | |
| Cost per user — LLM + infra cost per user/month vs price (per user for B2C, per client company for B2B) | | |
| Data touched — PII? other companies' data? money? regulated (IRDAI/DPDP/GDPR)? | | |

## 2. Napkin math

Command run (paste it so it can be re-run):

```
python3 ~/.claude/skills/ai-system-design/scripts/napkin.py --dau … --msgs … --in-tokens … --out-tokens … --in-price … --out-price … [--price-per-user … | --tenants … --price-per-tenant …] --prompt-cache … --response-cache … --fx …
```

| Metric | Value |
|---|---|
| Messages / month | |
| Input tokens / month | |
| Output tokens / month | |
| LLM bill / month, no caching | |
| LLM bill / month, with caching | |
| LLM cost per user (B2C) or per tenant (B2B) / month | |
| Gross margin after LLM cost | |
| Hard spend cap set at provider | |
| Prices looked up on (date + source), or UNVERIFIED placeholder | |

## 3. Pattern (lowest rung that works)

Chosen: `single call` | `RAG` | `fixed workflow` | `agent`

Why the rung below is not enough:

## 4. The nine boxes

| Box | Choice now | Not needed until (trigger number) |
|---|---|---|
| Client | | |
| API server / auth | | |
| Load balancer | | |
| Database (source of truth) | | |
| Cache | | |
| Queue + workers | | |
| Storage + CDN | | |
| Monitoring (logs, metrics, traces) | | |
| LLM + vector search | | |

## 5. Trust boundaries (Rule 2: every input is untrusted)

| Door into the prompt | Present? | Defence |
|---|---|---|
| User message | | |
| Retrieved documents / uploads | | |
| Web pages | | |
| Tool results | | |
| Model output rendered as HTML / executed as code | | |

Secrets in system prompt: **none** (confirm). Where secrets/access rules live instead:

## 6. Data guarding (Rule 3)

- Tenant / owner column on every row:
- Access enforced in the query (`WHERE tenant_id = $current`) or RLS — where exactly:
- Retrieval filtered by tenant BEFORE similarity search:
- Cache keys include tenant + user scope:
- Cross-tenant leak test (name of the test):

## 7. Failure design (Rule 4: assume it fails)

| Failure | Design |
|---|---|
| LLM slow | timeout = __ s, then: |
| LLM provider down | fallback chain: |
| Messy / wrong-shape output | JSON schema + validator: |
| Retry duplicates an action | idempotency key on: |
| Agent / loop runs away | max steps __, max cost per request __ |
| Irreversible action (payment, email, delete) | human approval step: |
| External dependency down | health check + backoff: |

## 8. Observability (Rule 5: measure everything)

- Trace per request with: auth → cache → embed → retrieve → prompt → LLM (tokens, cost, latency) → validate
- Tool: (Langfuse / LangSmith / OpenTelemetry / table in Postgres)
- Cost per user tracked where:
- Eval set location and size (min 20 real questions with expected answers):
- Evals rerun on: every prompt/model/chunking change
- Alerts: error rate __, p95 latency __, daily spend __

## 9. Stack & scaling ladder

Stage now: `launch` | `offload` | `scale out` | `split`

| Stage | Adds | Trigger number that moves us here |
|---|---|---|
| Launch | monolith + managed Postgres(+pgvector) + one LLM behind a wrapper | — |
| Offload | Redis cache, queue + workers, load balancer | |
| Scale out | stateless replicas behind LB | |
| Split | read replicas / DB split / dedicated vector DB | |

Hosting: `serverless` | `containers` | `VPS` — and the LLM-call time limit checked:

## 10. Open risks & decisions deferred
