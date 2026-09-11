# KVFlow

**Full title**: KVFlow: Efficient Prefix Caching for Accelerating LLM-Based Multi-Agent Workflows
**Authors**: Zaifeng Pan, Ajjkumar Patel, Zhengding Hu, Yipeng Shen, Yue Guan, Wan-Lu Li, Lianhui Qin, Yida Wang, Yufei Ding
**Venue**: **NeurIPS 2025** (Main Conference, Poster)
**Links**: [arXiv:2507.07400](https://arxiv.org/abs/2507.07400) · [NeurIPS proceedings](https://proceedings.neurips.cc/paper_files/paper/2025/hash/b7971d31a7d5eb0f1eed2f8f6f368195-Abstract-Conference.html) · [OpenReview 5Iw1nDtYmT](https://openreview.net/forum?id=5Iw1nDtYmT) · [poster page](https://neurips.cc/virtual/2025/poster/119883)
**Code**: [github.com/PanZaifeng/KVFlow](https://github.com/PanZaifeng/KVFlow) (built on SGLang)
**Fetched**: 2026-09-10

## Abstract
LLM-based agentic workflows repeatedly invoke specialized agents, each defined by a large fixed prompt, in structured execution patterns. Existing engines (vLLM, SGLang) reuse KV via prefix caching but evict with LRU when GPU memory fills — a policy that ignores the known future execution order of the workflow and often evicts entries shortly before their reuse. KVFlow is a workflow-aware KV cache management framework that abstracts the schedule as an Agent Step Graph, assigns each agent a steps-to-execution value estimating temporal proximity to its next activation, and evicts at the KV-node level of the tree-structured cache using those values. It additionally overlaps CPU→GPU KV prefetching for the next-step agents in background threads. Reports 1.83× speedup for single workflows with large prompts and 2.19× for scenarios with many concurrent workflows over SGLang + hierarchical radix cache.

## Taxonomy placement
- Unit: **workflow / agent-step** (not request, not session).
- Layer: **KV-cache management** (eviction policy + prefetch), NOT admission control.
- Signal used: static workflow structure (Agent Step Graph) → derived steps-to-execution scalar per agent.
- SLO-awareness: none (throughput / latency speedup only).
- Cluster: **5.5 KV-cache-management-adjacent**, not admission-primary.

## Contribution
- **Agent Step Graph abstraction.** Lifts the multi-agent workflow (AutoGen / LangGraph / MetaGPT-style DAG or loop) into a scheduling graph where nodes are agent invocations. From this the system computes a per-agent *steps-to-execution* value — a lookahead estimate of how soon each cached prefix will be reused.
- **Workflow-aware KV eviction at node granularity.** Replaces LRU eviction inside SGLang's tree-structured radix cache with a policy that ranks KV nodes by steps-to-execution, so entries about to be reused are protected even if they are not the most recently accessed.
- **Fully overlapped CPU→GPU KV prefetching.** Background threads proactively stage KV tensors for the agents scheduled in the next step, hiding miss stalls behind current-step generation.
- **Fine-grained per-node accounting on shared prefixes.** Because agents in a workflow share substantial prefix material (system prompt, role scaffolding, shared context), eviction/prefetch decisions operate on tree nodes rather than whole request prefixes, allowing partial retention of shared subtrees.
- **Drop-in on SGLang.** Implemented on top of SGLang; the baseline it displaces is SGLang's own hierarchical radix cache with LRU.

## Baselines
- **SGLang + hierarchical radix cache (LRU)** — primary and, per the abstract, essentially only headline baseline.
- Implicitly: vLLM-style prefix caching + LRU (discussed as the class KVFlow beats, not run as a separate bar in the reported headline numbers).

## Evaluation setup
- **Engine:** SGLang (KVFlow patches the cache manager).
- **Workflow frameworks referenced:** AutoGen, MetaGPT, LangGraph-style structured multi-agent workflows.
- **Regimes:** (i) *single workflow with large prompts* — stresses per-step prefix reuse; (ii) *many concurrent workflows* — stresses cross-workflow cache pressure and eviction ordering.
- **Hardware:** GPU + CPU host with staged KV (specific GPU SKU not surfaced in abstract/openreview; code repo targets standard SGLang GPU setup).
- **Metrics:** end-to-end workflow latency / speedup vs SGLang baseline.

## Claimed numbers
- **Up to 1.83× speedup** on single workflows with large prompts vs SGLang + hierarchical radix cache.
- **Up to 2.19× speedup** on many-concurrent-workflows scenarios vs same baseline.

## Fidelity
- **Code released** at PanZaifeng/KVFlow on SGLang — good reproducibility floor.
- **Baseline is narrow** — headline is only vs SGLang's hierarchical radix + LRU; no comparison to other workflow-aware cache systems (e.g., Parrot, AutoGen-native caching) or to admission-control approaches, which is exactly why CONCUR's Reviewer Afcg flagged it.
- **Workflow structure assumed known a priori** — the Agent Step Graph and steps-to-execution values presume the DAG/loop is declared by the framework (AutoGen/LangGraph do give this). Dynamic / conditional branching not stress-tested in the headline.
- **Hardware config under-specified** in the abstract-level extract; the arXiv full text would need to be re-fetched for exact GPU SKU and prompt-length distributions.

## Relevance to survey
Cluster 5.5 anchor — **KV-cache management adjacent, not admission-primary**. KVFlow controls *what stays in cache*; it does not control *what enters the system*. It is the natural comparison point for any admission-control paper that claims agentic-workflow gains, because a reviewer will (rightly) ask whether a smarter eviction policy on the same engine already captures most of the win. This is precisely the CONCUR Reviewer Afcg critique: without a KVFlow bar, we cannot separate admission-control gains from eviction-policy gains on multi-agent workloads.

## Open questions surfaced
- **No admission-control component.** KVFlow is pure cache-side: it never rejects, defers, or gates a workflow at ingress; it assumes the concurrent workload is given and only chooses eviction/prefetch order. This makes it *complementary* to CONCUR / Continuum rather than a substitute — but the survey needs to say so explicitly.
- **Steps-to-execution assumes a declared workflow graph.** Robustness to conditional branches, tool-call loops with unknown iteration count, or LLM-router agents that reshape the DAG at runtime is not characterized.
- **Cluster-wide eviction on shared subtrees may create fairness artifacts.** A workflow whose next step is imminent will systematically win eviction contests over one whose next step is far — analogous to shortest-remaining-time; long-horizon workflows could be starved of cache under load. Not analyzed.
- **Interaction with admission control is unexplored.** If an admission controller (CONCUR-style) already caps concurrent workflows to fit the KV working set, KVFlow's marginal gain likely shrinks — the two are coupled and neither paper measures the interaction.
- **No SLO / TTFT metric.** All headline numbers are throughput / speedup; the paper does not report tail latency or deadline attainment, so its relevance to online serving (survey Open Problem 2) is unclear.
