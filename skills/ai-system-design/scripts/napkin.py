#!/usr/bin/env python3
"""Napkin math for an LLM feature: monthly token bill, cost per user, margin.

Prices are REQUIRED arguments on purpose: model prices change, so look them up
(provider pricing page or openrouter.ai/models) instead of trusting memory.

Example (the transcript's support bot):
  python3 napkin.py --dau 5000 --msgs 20 --in-tokens 3000 --out-tokens 300 \
      --in-price 3 --out-price 15 --prompt-cache 0.6 --response-cache 0.2 \
      --price-per-user 6 --fx 84

B2B (price per client company):
  python3 napkin.py --dau 300 --msgs 6 --in-tokens 3000 --out-tokens 300 \\
      --in-price 3 --out-price 15 --tenants 10 --price-per-tenant 150

All prices are USD; --fx only adds a local-currency column.
"""
import argparse


def bill(dau, msgs, in_tok, out_tok, in_price, out_price,
         prompt_cache=0.0, cache_read_mult=0.1, response_cache=0.0, days=30):
    """Return dict of monthly volumes and USD cost.

    prompt_cache   = share of input tokens served from the provider's prompt cache
                     (stable system prompt / docs prefix). Billed at cache_read_mult.
    response_cache = share of messages answered from YOUR cache (Redis), no LLM call.
    """
    messages = dau * msgs * days
    llm_calls = messages * (1 - response_cache)
    in_total = llm_calls * in_tok
    out_total = llm_calls * out_tok
    in_cost = (in_total * (1 - prompt_cache) * in_price
               + in_total * prompt_cache * in_price * cache_read_mult) / 1e6
    out_cost = out_total * out_price / 1e6
    return {
        "messages": messages, "llm_calls": llm_calls,
        "in_tokens": in_total, "out_tokens": out_total,
        "in_usd": in_cost, "out_usd": out_cost, "total_usd": in_cost + out_cost,
    }


def fmt(n):
    for unit, div in (("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if abs(n) >= div:
            return f"{n / div:,.2f}{unit}"
    return f"{n:,.0f}"


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--dau", type=float, required=True, help="daily active users")
    p.add_argument("--msgs", type=float, required=True, help="LLM messages per user per day")
    p.add_argument("--in-tokens", type=float, required=True, help="input tokens per call (system + retrieved + history + user)")
    p.add_argument("--out-tokens", type=float, required=True, help="output tokens per call")
    p.add_argument("--in-price", type=float, required=True, help="USD per 1M input tokens (look it up)")
    p.add_argument("--out-price", type=float, required=True, help="USD per 1M output tokens (look it up)")
    p.add_argument("--prompt-cache", type=float, default=0.0, help="0-1 share of input tokens hitting provider prompt cache")
    p.add_argument("--cache-read-mult", type=float, default=0.1, help="cached-input price as fraction of normal (check provider)")
    p.add_argument("--response-cache", type=float, default=0.0, help="0-1 share of messages answered from your own cache")
    p.add_argument("--price-per-user", type=float, default=None, help="USD one end user pays per month (B2C)")
    p.add_argument("--tenants", type=float, default=None, help="number of paying client companies (B2B)")
    p.add_argument("--price-per-tenant", type=float, default=None, help="USD one client company pays per month (B2B, needs --tenants)")
    p.add_argument("--fx", type=float, default=None, help="local currency per USD (e.g. INR rate) - verify today's rate")
    a = p.parse_args()

    base = bill(a.dau, a.msgs, a.in_tokens, a.out_tokens, a.in_price, a.out_price)
    opt = bill(a.dau, a.msgs, a.in_tokens, a.out_tokens, a.in_price, a.out_price,
               a.prompt_cache, a.cache_read_mult, a.response_cache)

    def money(usd):
        s = f"${usd:,.2f}"
        return s + (f"  (~{usd * a.fx:,.0f} local)" if a.fx else "")

    print(f"Messages / month     : {fmt(base['messages'])}")
    print(f"Input tokens / month : {fmt(base['in_tokens'])}")
    print(f"Output tokens / month: {fmt(base['out_tokens'])}")
    print()
    print(f"{'':22}{'no caching':>28}{'with caching':>32}")
    for k, label in (("in_usd", "Input cost"), ("out_usd", "Output cost"), ("total_usd", "TOTAL / month")):
        print(f"{label:22}{money(base[k]):>28}{money(opt[k]):>32}")
    per_user = opt["total_usd"] / a.dau
    print(f"\nLLM cost per DAU / month (with caching): {money(per_user)}")
    revenue = None
    if a.price_per_tenant is not None:
        if not a.tenants:
            p.error("--price-per-tenant needs --tenants")
        revenue = a.price_per_tenant * a.tenants
        print(f"LLM cost per tenant / month: {money(opt['total_usd'] / a.tenants)}")
    elif a.price_per_user is not None:
        revenue = a.price_per_user * a.dau
    if revenue is not None:
        margin = 1 - opt["total_usd"] / revenue if revenue else float("-inf")
        print(f"Monthly revenue: {money(revenue)}  ->  gross margin after LLM: {margin:.0%}")
        if margin < 0.7:
            print("WARNING: LLM cost alone eats >30% of revenue. Revisit model, tokens, caching, or price.")
    print(f"Break-even for 70% margin: revenue of {money(opt['total_usd'] / 0.3)} / month")
    print(f"\nSuggested hard spend cap (2x expected): {money(opt['total_usd'] * 2)} / month")


if __name__ == "__main__":
    main()
