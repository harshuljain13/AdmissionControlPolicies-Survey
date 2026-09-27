# Niyama

**Full title**: Niyama: Breaking the Silos of LLM Inference Serving
**Authors**: Kanishk Goel, Jayashree Mohan, Nipun Kwatra, Ravi Shreyas Anupindi, Ramachandran Ramjee
**Venue**: arXiv:2503.22562 (2025)
**Verified**: 2026-09-21 (full PDF)

## Taxonomy placement
- Unit: **request**, within QoS classes  ·  Setting: **online**
- SLO-awareness: **deadline**, per QoS class
- Not in `tab:master`: it relegates rather than refuses, so it has no ingress gate to place

## Why the survey includes it
§5 states: "We include it because relegation and admission answer the same question with
different verbs, and because its overload behaviour is directly comparable to that of a
deferring admission policy."

## Verified claims
Abstract, verbatim: "Niyama employs a hybrid prioritization policy that balances fairness
and efficiency, and employs selective request relegation that enables graceful service
degradation during overload conditions."

That matches the survey's description clause for clause. Also verified: dynamic chunking
for throughput under QoS constraints; co-scheduling of mixed workloads on shared
infrastructure (`co-schedul` appears 9 times, `QoS` 103 times, `eager relegation` 12
times); 32% serving-capacity increase over siloed deployments, and an order-of-magnitude
reduction in SLO violations under extreme load.

## The distinction that matters to the taxonomy
Relegation degrades the service level of lower QoS classes; admission refuses entry. Both
answer "what gives under overload", which is why Niyama is corpus-adjacent, but only the
latter is an ingress decision.
