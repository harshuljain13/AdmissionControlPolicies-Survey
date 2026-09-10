# Paper Index — LLM Admission Control Survey

Target: 30-50 papers deep-read + cited. ~80-120 total citations (including foundational + adjacent).

## Tier 1 — Admission-control-primary (MUST deep-read, ~15 papers)

| # | Paper | Venue | Cluster |
|---|---|---|---|
| 1 | CONCUR / PACE (Ye et al.) | **ICML 2026** | Agent-level |
| 2 | QLM (Patke et al.) | **SoCC '24** | Request-level SLO |
| 3 | Chronos | **Frontiers CS 2026** | Request-level SLO |
| 4 | SOLA (Hong et al.) | **MLSys 2025** | Request-level SLO |
| 5 | FastServe (Wu et al.) | **NSDI 2026** | Request-level SLO + preemption |
| 6 | Shen et al. Two-Layer Framework | **ICML 2026** (poster; code released) | Joint config + admission |
| 7 | SLOs-Serve (Chen et al.) | arXiv:2504.08784 (still preprint 2026-09-10) | Multi-SLO with soft admission; per-stage SLOs |
| 8 | Continuum (Li et al., Berkeley/Stoica) | **ICLR 2026 Workshop on Lifelong Agents** (poster); VLDB submission in flight; code released as vLLM fork | Agent-level (KV TTL) |
| 9 | Fluid-WAIT (Ao et al.) | arXiv:2504.11320 | Threshold admission |
| 10 | AQUA (Kumar et al.) | **ASPLOS '25** (DOI 10.1145/3676641.3715983; code at github.com/aquaml) | Preemption alternative — canonical foil to admission-based work |
| 11 | Service-Induced Congestion | arXiv:2606.15555 | Stability analysis |
| 12 | Flow-controlled scheduling | arXiv:2604.11001 | Rate limiting |
| 13 | FairBatching (Lyu et al.) | arXiv:2510.14392 | Fair batch formation |
| 14 | ProServe | arXiv:2512.12928 | Multi-priority |
| 15 | Clairvoyant | arXiv:2606.07248 | Predictive SJF |

## Tier 2 — Fairness + Queueing theory (~8 papers)

| # | Paper | Venue | Cluster |
|---|---|---|---|
| 16 | VTC / Fairness in Serving LLMs (Sheng et al.) | **OSDI '24** | Fairness |
| 17 | Equinox | arXiv:2508.16646 | Fair scheduling |
| 18 | Sun et al. Queueing Predictions LLMs | SIGMETRICS 2025 tutorial | Queueing theory |
| 19 | Jaillet et al. Online Scheduling with KV | arXiv:2502.07115 | Queueing theory |
| 20 | Throughput-Optimal Scheduling | arXiv:2504.07347 | Queueing theory |
| 21 | Beyond Prediction (Tail-Aware) | arXiv:2606.18431 | Tail latency |
| 22 | Chiron (Hierarchical Autoscaling) | arXiv:2501.08090 | Autoscaling + admission |
| 23 | Ascendra | arXiv:2504.20828 | Request dropping |

## Tier 3 — KV-cache management adjacent (~6 papers)

| # | Paper | Venue |
|---|---|---|
| 24 | KVFlow (Pan et al.) | **NeurIPS 2025** — arXiv:2507.07400 — code at github.com/PanZaifeng/KVFlow |
| 25 | Cake | **ICML 2025** — arXiv:2410.03065 — PMLR v267 jin25d |
| 26 | InferCept (Abhyankar et al.) | **ICML 2024** — arXiv:2402.01869 — code at github.com/WukLab/InferCept |
| 27 | Pie (Gim et al.) | **SOSP 2025** — arXiv:2510.24051 — code at github.com/pie-project/pie |
| 28 | ThunderAgent (Kang et al.) | **ICML 2026 Spotlight** — arXiv:2602.13692 — integrated into NVIDIA Dynamo 2.0; code at github.com/ThunderAgent-org/ThunderAgent |
| 29 | Mooncake | **FAST '25** |

## Tier 4 — Scheduling papers with admission components (~8 papers)

| # | Paper | Venue |
|---|---|---|
| 30 | Sarathi-Serve | **OSDI '24** |
| 31 | Llumnix | **OSDI '24** |
| 32 | DistServe | arXiv (widely cited) |
| 33 | Orca | **OSDI '22** (foundational) |
| 34 | Aegaeon | **SOSP '25** |
| 35 | Jenga | **SOSP '25** |
| 36 | Past-Future Scheduler | **ASPLOS '25** |
| 37 | AdaServe | **EuroSys '25** |
| 38 | PASCAL (phase-aware for reasoning) | **HPCA 2026** |

## Tier 5 — Foundational / adjacent (~6 papers, cite in Background)

| # | Paper | Venue |
|---|---|---|
| 39 | SHEPHERD (DNN admission) | **NSDI '23** |
| 40 | PreQuaL (Wydrowski et al.) | **NSDI '24** |
| 41 | vLLM / PagedAttention | **SOSP '23** |
| 42 | SGLang | arXiv (widely cited) |
| 43 | Splitwise | **ISCA '24** |
| 44 | Kleinrock Queueing Systems Vol I | Textbook (1975) |
| 45 | Little's Law | Foundational |

## Tier 6 — Existing broad surveys to differentiate against

| # | Paper | Venue |
|---|---|---|
| 46 | Heisler et al. LLM Inference Scheduling: A Survey | TechRxiv Nov 2025 |
| 47 | Zhen et al. Taming the Titans | **INLG 2025** |
| 48 | Li et al. LLM Inference Serving | **IEEE HPEC 2024** |
| 49 | Li et al. KV Cache Management Survey | arXiv:2412.19442 |
| 50 | Existing broader surveys — from Tensor Buffer to Distributed Memory | arXiv:2607.02574 |

Total: 50 papers. Roughly 40 will get first-class treatment; 10 will appear in citations only.

## Reading order (Week 1)

**Days 1-2** (Tier 1, top 8): CONCUR, QLM, Chronos, SOLA, FastServe, Shen et al., Continuum, Fluid-WAIT.
**Days 3-4** (Tier 1 rest + Tier 2): Aqua, Service-Induced Congestion, Flow-controlled, FairBatching, ProServe, Clairvoyant, VTC, Sun et al. tutorial.
**Days 5-6** (Tier 3 + Tier 4): KVFlow, Cake, InferCept, Pie, ThunderAgent, Sarathi-Serve, Llumnix, Aegaeon, Jenga, Past-Future, AdaServe, PASCAL.
**Day 7**: Tier 5 + Tier 6 (foundational + differentiation surveys). Build taxonomy table.

Per-paper notes go in `papers/{short-name}.md`. Format: 1-page max, sections: contribution / signal used / unit / setting / SLO-awareness / baselines / measurement setup / claimed numbers / code availability / relevance to our taxonomy.
