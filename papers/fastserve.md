# FastServe

**Full title**: Fast Distributed Inference Serving for Large Language Models
**Authors**: Bingyang Wu, Yinmin Zhong, Zili Zhang, Shengyu Liu, Fangyue Liu, Yuanhang Sun, Gang Huang, Xuanzhe Liu, Xin Jin (Peking University)
**Venue**: **NSDI '26** (per USENIX conference page — verify final publication)
**Links**: arXiv:2305.05920 · [USENIX NSDI 26 program](https://www.usenix.org/conference/nsdi26/presentation/wu-bingyang) · GitHub: [LLMServe/FastServe](https://github.com/LLMServe/FastServe), mirror [MachineLearningSystem/NSDI26-FastServe](https://github.com/MachineLearningSystem/NSDI26-FastServe)
**Code**: **Yes** (Python + C++, on SwiftTransformer — not vLLM)
**Fetched**: 2026-09-10

## Abstract
Exploits autoregressive pattern to enable preemption at output-token granularity. Skip-join Multi-Level Feedback Queue scheduler + efficient GPU memory management + proactive KV offload. Up to 31.4× / 17.9× throughput vs vLLM under average / tail latency requirements.

## Taxonomy placement
- Unit of admission: **request** (with token-level preemption)
- Setting: **online serving**
- SLO-awareness: **deadline-aware** (average + tail)
- Signal used: multi-level queue position + estimated remaining work

## Contribution (deep-read summary — Days 2-6)
TBD

## Baselines
**vLLM** (primary, called "state-of-the-art")

## Evaluation setup
- Model(s): TBD deep read
- Engine: custom on SwiftTransformer (not vLLM/SGLang)
- Workload: TBD (interactive AI applications like ChatGPT)
- Metrics: average latency, tail latency, throughput

## Claimed headline numbers
Up to 31.4× (average) and 17.9× (tail) throughput vs vLLM

## Fidelity / reproducibility
- Code: available, but on SwiftTransformer engine — porting to vLLM is high-effort
- Notes: this is a design constraint for AdmitBench Track 2 (would need engine port)

## Relevance to survey
Represents preemption-based admission approach — token-granular preemption as alternative to reject-on-arrival admission. Load-bearing for the "preemption vs admission" discussion in 5.6.

## Open questions surfaced
TBD deep read
