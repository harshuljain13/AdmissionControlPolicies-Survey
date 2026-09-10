# Continuum

**Full title**: Continuum: Efficient and Robust Multi-Turn LLM Agent Scheduling with KV Cache Time-to-Live
**Authors**: Hanchen Li, Runyuan He, Qiuyang Mang, Qizheng Zhang, Huanzhi Mao, Xiaokun Chen, Hangrui Zhou, Huanchen Zhang, Alvin Cheung, Joseph Gonzalez, Ion Stoica (Berkeley / Tsinghua)
**Venue**: arXiv preprint (cs.OS), v7 as of Sep 2026; accepted as **poster at ICLR 2026 Workshop on Lifelong Agents** (Apr 26, 2026). Full-conference systems venue not yet confirmed; formatted in PVLDB template (Vol. 20) suggesting VLDB submission in flight.
**Links**: arXiv:2511.02230 ; OpenReview sVzK0LC9pn
**Code**: `https://github.com/Hanchenli/vllm-continuum` (vLLM fork, ~1000 LoC Python); traces + testbed promised open-source upon publication
**Fetched**: 2026-09-10

## Abstract
KV cache management for LLM inference on agentic workloads. Traditional engines evict cached KV when new requests arrive — inefficient for multi-turn agents that pause during tool execution. Continuum introduces a **time-to-live (TTL)** mechanism for KV retention: selectively retain cache based on estimated reload cost + queueing delay + tool-call duration distribution; auto-evict when TTL expires. Up to **8.18× JCT** improvement on real SWE-agent workloads.

## Taxonomy placement
- Unit of admission: **agent-session** (adjacent — this is KV retention policy, not admission gating)
- Setting: **online serving** (agent workloads)
- SLO-awareness: JCT-oriented, not deadline
- Signal used: KV cache reload cost + queueing delay estimate + empirical tool-call duration CDF

## Contribution (deep-read summary)
1. **Per-session KV TTL**, chosen by maximizing `P(τ, f) · Benefit(r) − Cost(τ, r)`, where `P(τ, f)` is the empirical CDF probability that the pending tool call returns within τ seconds (built from historical tool-call latencies).
2. **Two-part cost model**: `CacheMissCost` (prefill/reload overhead + blocked-request count) plus `OutofOrderCost = (T/M) · MemUsage(r) · η` — the **queueing/memory-occupation** term prior work (InferCept) ignored. `η` captures workload "memoryfulness" (correlation between served and remaining requests).
3. **Cold-start policy**: fixed TTL from an exponential prior until K=100 historical tool-call samples accumulate per tool.
4. Empirical characterization of multi-turn agent traces (SWE-Bench: 10.9 turns avg; BFCL v4: 6.3 turns avg) motivating the "pauses matter" thesis.
5. Implementation as ~1000-line patch on vLLM; also compared distributed against SGLang cache-aware routing and Nvidia Dynamo 1P1D disaggregation.

## Baselines
- **vLLM 0.10.2** (vanilla end-of-turn eviction)
- **vLLM + LMCache 0.3.7** (CPU DRAM offloading)
- **Autellix** and **Autellix + LMCache** (Program-Level Attained Service scheduling)
- **InferCept** (preserve/swap/evict on reload cost only — closest prior art; Continuum's key delta is adding the queueing term)
- **SGLang 0.5.5.post3** (native cache-aware routing, distributed)
- **Nvidia Dynamo 0.7.0.post1** (1P1D prefill/decode disaggregation, distributed)

Note: no admission-control baseline in the comparison set — Continuum lives entirely in the KV/cache-policy layer.

## Evaluation setup
- **Llama-3.1-8B**: 1×A100 and 1×B200
- **Llama-3.1-70B**: 4×B200
- **Gemma-3-12B**: 1×A100
- **GLM-4.5-fp8 355B**: 8×H100 (RL setting)
- **GPT-5**: trace collection only
- **Engine**: vLLM (Continuum patch); SGLang and Dynamo for distributed comparisons
- **Workloads**: SWE-Bench via mini-swe-agent (top-5 leaderboard); BFCL v4 Web Search (scaled 0.4× for context); OpenHands on Multi-SWE-bench Go; 500 SWE-Bench-Verified tasks on "Company A" (Tensormesh) H100 testbed
- **Metrics**: avg JCT / response time, P95 latency, throughput, task pass rate (docker-timeout avoidance)

## Claimed headline numbers
- **1.12×–3.66× JCT reduction** and **1.10×–3.22× throughput gain** across the three standard hardware+model setups.
- **Up to 8.18× JCT reduction** on Tensormesh's internal SWE-agent testbed (the headline "8×" number is this specific deployment, not the aggregate).
- SWE-Bench on Llama-8B: ~2× response-time reduction vs vLLM.
- BFCL: consistent improvement across configs (no single hero number).
- OpenHands Llama-8B on H100: best P95 in the comparison set.
- Real deployment: higher task pass rate because faster completion avoids docker timeouts.

## Fidelity / reproducibility
- Code: **public vLLM fork** at `github.com/Hanchenli/vllm-continuum`, ~1000 LoC — small enough to audit and re-run.
- Traces + agent-serving testbed pledged for release on publication.
- Berkeley/Stoica group has a strong release track record (vLLM, SGLang, Autellix), so trust here is high.

## Relevance to survey
Agent-level cluster (Section 5.2). Complement to CONCUR: **Continuum optimizes KV state after admission (TTL-based retention); CONCUR gates admission before KV pressure arises**. Layered relationship — the two are composable rather than competitive.

## Open questions surfaced
- **Non-linear agent workflows**: authors explicitly note their design assumes sequential ReAct; speculative branches, async multi-agent coordination, and context folding are unaddressed.
- **Static tool-set assumption**: TTL model needs post-hoc statistics per tool; unclear how to bootstrap in dynamic tool ecosystems (MCP-style).
- **No admission-control comparison**: gap Continuum leaves open — nothing in their eval tests whether a proactive gate would subsume or complement TTL under overload.
- **η (memoryfulness) estimation**: treated as a workload constant; how it drifts under mixed-tenant serving is not studied.
- **PVLDB template but ICLR-workshop-only acceptance** so far — implies conference-track submission still under review, so final numbers may shift.
