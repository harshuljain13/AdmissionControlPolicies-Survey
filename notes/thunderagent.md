# ThunderAgent: A Simple, Fast and Program-Aware Agentic Inference System

- **Full title**: ThunderAgent: A Simple, Fast and Program-Aware Agentic Inference System
- **Authors**: Hao Kang, Ziyang Li, Xinyu Yang, Weili Xu, Yinfang Chen, Junxiong Wang, Beidi Chen, Tushar Krishna, Chenfeng Xu, Simran Arora (Georgia Tech, CMU, UIUC, Together AI)
- **Venue**: ICML 2026 (Spotlight, top ~2.2%); also integrated into NVIDIA Dynamo 2.0 and SkyRL
- **Links**: arXiv [2602.13692](https://arxiv.org/abs/2602.13692) (v1 Feb 14 2026, v3 Jun 30 2026); [Together AI blog](https://www.together.ai/blog/thunderagent); [ICML poster](https://icml.cc/virtual/2026/poster/62040)
- **Code**: https://github.com/ThunderAgent-org/ThunderAgent
- **Fetched**: 2026-09-10

## Abstract

Large language models are now used to power complex multi-turn agentic workflows. Existing systems run agentic inference by loosely assembling isolated components: an LLM inference engine (e.g., vLLM) and a tool orchestrator (e.g., Kubernetes). Although agentic workflows involve multiple LLM and tool requests, these systems schedule and allocate resources separately on a per-request basis, without end-to-end knowledge of the workflow. This leads to sub-optimal management of KV cache and tool execution environments. ThunderAgent abstracts agentic workflows as LLM Programs, providing a unified view of heterogeneous resources — KV caches, system states, and external tool assets (disk memory, network ports) — and introduces a program-aware scheduler plus tool resource manager that maximize KV cache hit rates, mitigate memory imbalances, and enable asynchronous environment preparation.

## Taxonomy placement

Cluster 5.2 — **agent-level admission / scheduling**. ThunderAgent is a central, workflow-aware scheduler that treats an entire agent trajectory (LLM turns + tool calls) as the schedulable unit. Admission control is expressed implicitly: the scheduler decides which programs are *resident* (KV cache in HBM, tool env warm) vs *paused* (evicted from HBM, tool env torn down / async-prepared), based on program-level state rather than per-request queues. This is agent-granularity pause/restore, distinct from token-level or request-level admission.

## Contribution

- **LLM Program abstraction**: elevates the scheduling unit from a single request to an entire agentic workflow, giving the scheduler end-to-end visibility over KV cache, system state, and tool assets across turns.
- **Program-aware central scheduler**: decides which programs remain resident vs get paused/restored, explicitly targeting the "KV thrashing across tool calls" pathology (up to 7.1x recompute latency inflation reported when a workflow's KV is evicted during a tool call).
- **Cross-node memory balancing**: breaks the "pin workflow to one device" assumption, migrating program state to balance HBM pressure across nodes — a mechanism CONCUR does not address.
- **Tool resource manager with async env preparation**: pre-warms disk/network/tool sandbox state before the LLM finishes its turn, hiding tool-cold-start latency. Manages tool assets (disk memory, ports) as first-class scheduled resources.
- **System integration**: shipped as a first-class scheduling unit in NVIDIA Dynamo 2.0 and used in SkyRL for agentic RL rollout (3x SWE-Agent rollout speedup on 40x H100).

## Baselines

- vLLM + Kubernetes-style orchestration (the "loosely assembled isolated components" strawman explicitly called out).
- State-of-the-art agent serving stacks (for the 4.2x disk-savings claim); specific named baselines beyond vLLM are not enumerated in the abstract/blog — full baseline table lives in the paper body (N/A from public materials read).

## Evaluation setup

- **Workloads**: coding agents, routing agents, and scientific-discovery agents (three domains). Also RL rollout for SWE-Agent.
- **Hardware**: multi-node GPU clusters; SkyRL example uses 40x H100. Single-node and multi-node scaling both reported.
- **Metrics**: serving throughput, RL rollout throughput, disk memory footprint, KV cache hit rate, per-turn latency.
- Specific model families and dataset sizes: N/A from the materials fetched (present in paper body).

## Claimed numbers

- **1.48–3.58x** serving throughput vs conventional orchestration.
- **1.8–3.9x** RL rollout throughput.
- **Up to 4.2x** disk memory savings.
- **>2x** single-node throughput; near-linear multi-node scaling.
- KV thrashing avoided: baseline showed up to **7.1x** latency inflation from recompute on tool return.
- **3x** SWE-Agent rollout speedup in SkyRL on 40x H100.

## Fidelity

Fidelity-preserving by construction: pause/restore operates on KV cache and tool environment state, not on the model's output distribution. No accuracy/quality delta is claimed or expected (unlike admission schemes that shed tokens or downgrade models). Verifying that the paper reports task-quality parity on the agent benchmarks (as opposed to only throughput) is an open item — N/A from public abstract/blog.

## Relevance to survey (cluster 5.2)

Sits alongside **CONCUR** and **Continuum** in the agent-level admission cluster. All three attack the same root cause — naive per-request scheduling causes memory thrashing when workflows span multiple LLM turns interleaved with tool calls — but pick different control surfaces:

- **CONCUR**: AIMD-style feedback loop on the *concurrency window* (how many programs may run at once), reactive and decentralized-friendly.
- **ThunderAgent**: *central* scheduler with explicit *pause/restore* of program state, proactive and globally optimal but requires a single planner with full visibility.
- **Continuum**: (see own note) — orthogonal axis on continuation vs restart cost.

ThunderAgent is the strongest "central planner" incumbent in this cluster and the natural comparison point Reviewer DhUu is pointing at. The mechanism-level distinction (window control vs state migration) should be made explicit in 5.2's taxonomy table.

## Open questions surfaced

- **Pause/restore cost model**: what is the amortized break-even point where paying to migrate program KV across nodes beats simply recomputing on tool return? ThunderAgent claims 7.1x recompute penalty motivates migration, but the crossover as a function of context length and tool duration is not characterized publicly.
- **Central scheduler scalability**: does the program-aware scheduler remain a single point of coordination? At what fleet size does its global visibility become a bottleneck vs CONCUR's local AIMD?
- **Adversarial / long-tail workloads**: all reported workloads (coding, routing, sci-discovery) have relatively bounded tool latency. How does pause/restore behave when a tool call blocks for minutes (e.g., long-running simulations)?
- **NEW open problem for the survey**: *tool-asset admission control.* ThunderAgent is the first system in this cluster to treat disk/port/sandbox as first-class scheduled resources — none of CONCUR, Continuum, or the request-level baselines admit on tool-side capacity. This opens a whole sub-axis (LLM-side vs tool-side admission) that the survey's cluster 5.2 currently collapses.
- **Interaction with speculative decoding / prefix cache sharing**: program-level migration may fight prefix-cache locality; unclear if the scheduler is prefix-cache-aware.
