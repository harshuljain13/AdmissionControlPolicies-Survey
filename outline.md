# Survey Outline — Admission Control for LLM Inference Serving

Target: 20 pages body + refs. Format: ACM CSUR two-column or one-column depending on venue.

## Structure

### 1. Abstract (~200 words)
One paragraph. Frames: (a) admission control is a distinct sub-problem in LLM serving with 8+ arXiv preprints and 5+ top-venue papers in 24 months, (b) no dedicated survey exists, (c) the field is fragmented across request-level vs agent-level, online vs offline, SLO-aware vs throughput-only formulations, (d) this survey provides a taxonomy, per-cluster deep dive, and open-problems roadmap.

### 2. Introduction (~2 pages)
- Opening: real production incident from Production Scenarios page (Anthropic Jan 21 2026 capacity miss OR OpenAI DALL·E queue collapse). Sharp opening scene, not academic preamble.
- Why admission control matters: capacity signals vs request counts; 429/503/529 error contracts; the cost of admitting work that will miss its SLO.
- Why LLM changes the game: KV cache as scarce resource with unpredictable growth; agentic workloads with unbounded per-agent state; prefill vs decode contention.
- The gap this survey fills: three broad serving surveys exist (Heisler 2025, Zhen 2025, Li 2024) but none treats admission as the organizing axis; no admission-control-specific systematic review; the space is moving fast enough that a focused review is timely.
- Contributions: (a) taxonomy across 4 axes, (b) synthesis of ~40 works, (c) reproducibility audit of published policies, (d) 5+ open problems endorsed by peer reviewers of recent papers.

### 3. Background (~2 pages)
- LLM inference basics: prefill vs decode, iteration-level scheduling, KV cache as scarce GPU memory. One clean mermaid or block diagram.
- The Admit-Queue-Route three-box model (from cohort docs and Abi Aryan's MEWTWO material). Explicit that admission is a distinct decision from batching and routing.
- SLO metrics: TTFT, TBT, goodput. Why goodput ≠ throughput. Agent-completion rate for agentic workloads.
- Little's Law and queueing basics for LLM serving. Cite Sun et al. SIGMETRICS tutorial for the queueing lens.
- Error contract: 429 vs 503 vs 529. How admission control ties to what the caller sees.

### 4. Taxonomy (~2 pages)
Four axes for classifying admission-control policies:

| Axis | Values |
|---|---|
| Unit of admission | Request / Agent-session / Tenant |
| Setting | Online serving / Offline batch |
| SLO-awareness | Deadline-aware (TTFT/TBT) / Throughput-oriented / Fairness-oriented |
| Signal used | KV pressure / Queue depth / Estimated output length / Historical latency / Deadline slack |

Single figure: 2D scatter with all reviewed policies plotted on (Unit × SLO-awareness) or a color-coded axis matrix.

### 5. Policy clusters — deep dive (~8 pages, ~1.5 pages per cluster)

**5.1 Request-level SLO-aware**
- QLM (Patke et al., SoCC '24)
- Chronos (Frontiers CS 2026) — WCRT-based
- SOLA (MLSys 2025) — state-aware
- FastServe (NSDI 2026) — skip-join MLFQ + preemption
- SLOs-Serve (arXiv:2504.08784)

**5.2 Agent-level**
- CONCUR / PACE (ICML 2026) — AIMD-style congestion control on agents
- ThunderAgent — central scheduler that pauses/restores programs
- Continuum (arXiv:2511.02230) — KV cache TTL for multi-turn agent scheduling

**5.3 Fairness-aware**
- VTC / Fairness in Serving LLMs (Sheng et al., OSDI '24)
- FairBatching (arXiv:2510.14392)
- Equinox (arXiv:2508.16646)

**5.4 Queueing theory / algorithmic**
- Sun et al. SIGMETRICS 2025 tutorial — queueing framing
- Shen et al. (ICML 2026) — two-layer joint config + admission
- Fluid-WAIT (arXiv:2504.11320) — fluid model thresholds
- Flow-controlled scheduling (arXiv:2604.11001)
- Service-Induced Congestion (arXiv:2606.15555) — stability analysis
- Aqua (arXiv:2407.21255) — preemption as alternative to admission
- Clairvoyant (arXiv:2606.07248) — predictive SJF

**5.5 KV-cache management adjacent (admission-relevant)**
- KVFlow (NeurIPS 2025) — prefix caching for multi-agent
- Cake (ICML 2025) — compute-vs-load KV decisions
- InferCept (ICML 2024) — tool-call KV intercept
- Pie (SOSP 2025) — programmable serving

**5.6 Scheduling papers with admission components (not primary)**
- Sarathi-Serve (OSDI '24), Llumnix (OSDI '24), ProServe (arXiv:2512.12928), PASCAL (HPCA 2026)

### 6. Comparison methodology audit (~2 pages)
What each cluster measures, what setups they use, what they compare against. Table form:

| Paper | Model | Engine | Workload | Baselines it compares against |
|---|---|---|---|---|

The key finding: almost no cross-cluster comparison. CONCUR (agent-level) doesn't compare to QLM (request-level). QLM doesn't compare to Chronos. Etc. Reproducibility subset: only Chronos has released code (simulator).

### 7. Production evidence (~2 pages)
Real incidents from Production Scenarios page:
- Cloudflare rate-limiting (2017/2022) — request count vs resource count
- Azure 2016 talk — wrong capacity signal
- OpenAI DALL·E queue collapse, Nov 8 2023, April 10, Dec 11 2024, Nov 25 2024
- Anthropic Jan 21 2026 (capacity miss), Nov 25 2025 (529), Aug 29 (wrong pool)

For each incident: what capacity signal was trusted, was it leading/lagging/stale, what admission decision would have helped. Ties production reality to the theoretical papers.

### 8. Open problems (~2 pages)
Endorsed by peer reviewers of recent papers — cite where possible:

1. **Request-level vs agent-level admission head-to-head** — CONCUR Reviewer Afcg's public question. Unresolved.
2. **Online serving admission for agentic workloads** — CONCUR/PACE explicit non-goal per meta-review.
3. **Fairness and starvation under admission control** — flagged by CONCUR Reviewers DhUu and Afcg.
4. **Reasoning-trace-aware admission** — o1/R1-style long-CoT traffic; nobody addresses.
5. **Reproducibility crisis** — 8+ preprints, 1 with code (Chronos, simulator only). Field cannot compare policies.
6. **Multi-tenant admission with per-tenant SLOs** — cited as limitation across multiple papers.
7. **Coupling with autoscaling and routing** — admission decision interacts with replica choice; nobody models this end-to-end.

### 9. Conclusion (~1 page)
Recap: distinct sub-problem, taxonomy across 4 axes, 30+ works synthesized, 7 open problems. Call for community coordination on reproducibility and cross-comparison (this is where the follow-on AdmitBench benchmark lives).

### 10. References
~80-120 citations.

## Word budget

- Body: ~10,000-12,000 words (20 pages 2-column ACM)
- References: separate
- Figures: 4-6

## Figures planned

1. Timeline of admission-control papers 2023-2026 (X-axis: date, Y-axis: paper, colored by cluster)
2. Taxonomy scatter (Unit × SLO-awareness)
3. Admit-Queue-Route three-box model
4. Production incident → admission decision mapping (per Production Scenarios page)
5. Cross-comparison matrix (X: paper A, Y: paper B, cell: "did A compare against B?") — mostly empty, visually shows the gap
