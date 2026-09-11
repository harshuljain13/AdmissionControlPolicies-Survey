# Pie: A Programmable Serving System for Emerging LLM Applications

- **Authors**: In Gim, Zhiyao Ma, Seung-seob Lee, Lin Zhong (Yale)
- **Venue**: SOSP 2025 (ACM SIGOPS 31st Symposium on Operating Systems Principles), Seoul, Oct 13–16, 2025
- **Links**:
  - arXiv: https://arxiv.org/abs/2510.24051 (PDF: https://arxiv.org/pdf/2510.24051)
  - ACM DL: https://dl.acm.org/doi/10.1145/3731569.3764814
  - Author copy: https://ingim.org/papers/gim2025pie.pdf
- **Code**: https://github.com/pie-project/pie
- **Fetched**: 2026-09-10

## Abstract

Emerging LLM applications involve diverse reasoning strategies and agentic workflows, straining existing serving systems built on a monolithic token generation loop. Pie is a programmable LLM serving system designed for flexibility and efficiency. It decomposes the traditional generation loop into fine-grained service handlers exposed via an API and delegates control of the generation process to user-provided programs called *inferlets*. This enables applications to implement new KV cache strategies, bespoke generation logic, and seamlessly integrate computation and I/O — entirely within the application, without modifying the serving system. Inferlets run in WebAssembly sandboxes. Pie matches SOTA on standard tasks (3–12% latency overhead) while delivering 1.3×–3.4× latency/throughput gains on agentic workflows via application-specific optimizations.

## Taxonomy placement

**Programmable substrate / control-plane framework** — not an admission-control policy itself. Pie sits one layer below policy work: it exposes the primitives (KV page allocation, handler-level generation control, per-inferlet Wasm isolation) that a *user* could use to build an admission-control policy in-application. The only built-in overload response is a coarse FCFS termination of the most recently started inferlet when KvPage capacity is exceeded. Belongs in survey cluster 5.6 (frameworks / programmable substrates that admission-control policies could target), alongside SGLang- and vLLM-style extension points.

## Contribution

- **Inferlet abstraction**: user programs (compiled to Wasm) drive the end-to-end generation loop, replacing the monolithic prefill–decode pipeline. Each inferlet runs in its own Wasm instance; hundreds concurrent supported.
- **Fine-grained handler API (42 endpoints, 18 LLM-specific)**: exposes embedding, forward pass, sampling, and KV page management as callable primitives. LLM APIs organized into *traits* for model-agnostic extensibility.
- **Explicit KV cache control (KvPage)**: applications customize allocation, eviction, and reuse policies (tree-of-thought sharing, map-reduce prefix reuse, multi-step retention) rather than inheriting system-wide heuristics.
- **Wasm-based isolation**: lightweight sandboxing lets untrusted application logic co-run with the serving engine without process-level overhead.
- **Direct I/O and computation integration**: inferlets can issue tool calls, retrieval, or arbitrary compute inline with generation — no external orchestration layer.

## Baselines

vLLM, SGLang, Text Generation Inference (HuggingFace TGI).

## Evaluation setup

- **Models**: Llama-family, Qwen2, Gemma (multiple sizes referenced).
- **Hardware**: GPU serving nodes (specific SKUs in paper appendix, not enumerated in abstract-level extraction).
- **Workloads**:
  - Standard: single-turn generation, prefix-cached prompts.
  - Agentic / structured: grammar-constrained decoding, tool-use / function-calling, tree-of-thought, map-reduce summarization, multi-step reasoning.

## Claimed numbers

- **Overhead vs SOTA on standard workloads**: 3–12% higher latency (cost of programmability).
- **Agentic workloads**: 1.3×–3.4× higher throughput / lower latency vs vLLM/SGLang, from application-specific KV reuse and inline I/O.
- **Concurrency**: several hundred inferlets per node in Wasm runtimes.
- **API surface**: 42 endpoints total, 18 LLM-execution APIs.

## Fidelity

Medium-high. Real prototype, open-source, evaluated against strong baselines (vLLM/SGLang) on both standard and agentic workloads. Programmable-substrate claim is well grounded in an actual API surface and a working Wasm host. Weakness for admission-control fidelity: the paper does *not* implement or evaluate any admission-control policy on top of Pie — the overload story is a single FCFS-terminate-newest rule, no queueing/priority/SLO experiments. So the "enables custom admission control" reading is a capability claim, not an evaluated one.

## Relevance to survey

**Cluster 5.6 (programmable substrates / control-plane frameworks)**, not a policy datapoint for §5.3–5.5. Cite as the strongest existing evidence that per-request custom scheduling and cache management are *implementable* as first-class abstractions in a modern serving stack — which is exactly the substrate an SLO-aware admission controller would need. Contrast with QLM / SLOs-Serve / FairBatching (in-engine policies) and with CONCUR (dedicated admission layer). Pie is the "you could build any of these on us" system, but ships none of them.

## Open questions surfaced

- **Does the handler API expose enough to build a real admission controller?** Inferlets can self-terminate and observe their own KvPage usage, but there is no evidence of a cross-inferlet scheduler API (global queue length, tail-latency signals, per-tenant fairness state). Building QLM-style waiting-time SLO admission on Pie would likely require new host-side APIs.
- **FCFS-terminate-newest is a very weak overload policy** — it is *anti*-fair (punishes late arrivals unconditionally) and provides no goodput guarantee. This is a genuine hole a follow-up paper could fill.
- **Wasm cost under adversarial inferlets**: what happens when an inferlet spins in a tight handler loop or over-allocates KvPage? No isolation-cost or noisy-neighbor evaluation reported.
- **NEW open problem**: *policy portability across programmable serving substrates.* If admission-control policies (QLM, CONCUR, FairBatching) get re-implemented on Pie, SGLang extensions, and vLLM plugins independently, the community loses cross-system comparability. A minimal common policy-API — hooks for admit / reject / preempt / migrate with standardized signals (queue depth, per-tenant tokens, deadline) — would let a single policy implementation run on any programmable engine and be benchmarked apples-to-apples. Pie's 42-API surface is a natural starting point for defining that contract.

## Verification of CONCUR rebuttal framing

CONCUR's characterization — "Pie provides a programmable substrate for developers to manually implement cache-management logic" — is **accurate but slightly narrow**. Pie's substrate covers more than cache management: it also exposes generation-loop handlers (embedding, forward, sampling), inline I/O, and per-inferlet isolation. However, on the specific question of admission control, CONCUR's framing is correct: Pie ships no admission policy beyond FCFS-terminate-newest, and any real admission logic would be developer-implemented inside inferlets or as a host extension. Recommend phrasing in the survey: "Pie exposes fine-grained generation and KV-management primitives that admission-control policies *could* target, but does not itself contribute an admission policy."
