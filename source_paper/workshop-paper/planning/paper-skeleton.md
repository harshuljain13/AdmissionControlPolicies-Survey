> **SUPERSEDED as the paper source.** The paper is now LaTeX:
> `../body.tex`, `../abstract.tex` and `../preprint/paper.tex`, built with
> `make workshop`. This file is kept for the venue analysis, the figure plan
> and the timeline, which have no LaTeX equivalent.
>
> Three claims in it do not survive checking and are not carried into the
> LaTeX. See `SKELETON-REVIEW.md`. In short: the survey finding is stated
> backwards here (all five axes fill, not four), the "quoted from survey"
> definition of inertness is not in the survey, and R1 rests on a pilot run
> whose configuration made the result arithmetic rather than a finding.

# Workshop Paper Skeleton: Signal Liveness in LLM Admission Control

**Format:** 6-page core (fits MLSys workshops at 4-8pp and ICLR workshops at 4-9pp)
**Status:** Venue-neutral skeleton, drafted 2026-09-27
**Grounds on:** *Admission Control for LLM Inference Serving: A Systematic Review* (Jain et al., under review at ACM Computing Surveys, submitted 2026-09-26)
**Author:** Harshul Jain
**Target venues (CFPs not open yet):** ES-FoMo @ MLSys 2027, ML for Systems @ MLSys 2027, ES-FoMo @ ICLR 2027, Trustworthy ML / Evaluation @ ICLR 2027

---

## One-sentence pitch

The survey found that zero of sixteen published admission-control policies for LLM serving report the operating range of the signal their policy reads on; this paper takes that finding from bibliographic absence to demonstrated fact by running two published policies on real vLLM and showing that the signal one of them reads never leaves a narrow band under realistic offered load.

## Load-bearing contribution

1. An empirical probe protocol that any deployment can run in an afternoon to detect a policy whose declared signal is inert in the target regime.
2. Measurement of two published policies (Fluid-WAIT queue-depth, KV-threshold) on real vLLM across three arrival regimes, quantifying admission-decision agreement between policies whose signals disagree by orders of magnitude.
3. A capability-declaration schema derived from the survey's five-axis taxonomy that lets a policy state its signal requirements, and a runtime gate that refuses to deploy a policy whose signals the engine cannot supply.

This is a **methodological** contribution, not a new admission mechanism. Precedent: MLPerf Inference (Reddi et al., MLSys 2020) as an evaluation-harness paper at a systems venue.

---

## Section outline (6 pages)

### §1 Introduction (0.6 pp)

Opening: an LLM inference cluster under overload has one shared postmortem shape, and every recent public incident (OpenAI Nov 2023, Anthropic 2024, Cloudflare AI Gateway, Azure OpenAI throttling) names the same layer as the failure site. The serving literature has spent five years on what happens after the door.

Companion survey (Jain et al., under review) reviewed 55 admission and admission-adjacent works between 2022 and 2026 and reported three findings. This paper is a follow-on to the third: of sixteen admission-primary papers, four axes of the five-axis taxonomy are recoverable from every paper (unit, setting, objective, portability). One axis is recoverable in name but not in operating range: **the observed range of the signal the policy reads is reported by none of the sixteen**.

Contribution of this paper: convert that finding from a claim about a literature to a measured fact about a deployment, using two policies and one open harness.

### §2 Background: the taxonomy and the missing axis (0.5 pp)

Half-page recap of the five-axis taxonomy (unit / setting / objective / signal quantity / portability) with an inline table showing which axes are recoverable from published text and which are not. Cite the survey (as under review) for the master classification of 28 works with admission mechanism, and for the GRADE-adapted evidence ratings.

Key definition, quoted from survey: a policy's signal is **inert** in a regime if the range observed during a representative offered-load probe stays inside a configurable band around its neutral value (default: within one decision-threshold width of the policy's admit boundary).

### §3 Method: the signal-liveness probe (1.0 pp)

Protocol (three steps):

1. **Declare capability.** Policy states which signal it reads (KV pressure, queue depth, deadline slack, tenant credit, session state, wait estimate) and the operating band it assumes.
2. **Offer load.** Run a stress workload at a set of arrival rates spanning the engine's rated capacity.
3. **Record signal range.** Sample the declared signal at 100ms cadence for the full run; report min, max, p50, p95, p99 and the fraction of samples inside the policy's assumed band.

A policy is **live** in the tested regime if the signal leaves its neutral band on a nontrivial fraction of samples; **inert** otherwise.

Include a figure: signal timeseries for one live and one inert policy on the same offered load.

### §4 Experimental setup (0.7 pp)

**Engine.** vLLM (version pinned in appendix), single GPU, OpenAI-compatible API front-end. No engine modifications.

**Model.** Qwen3-1.5B on A10G (small model chosen per survey's reproducibility discussion; lowers replication cost for reviewers).

**Policies.**
- Fluid-WAIT-inspired queue-depth policy (declared signal: waiting_requests).
- KV-threshold policy (declared signal: kv_cache_utilization; threshold 0.9).

**Workloads.** ShareGPT-shaped chat (short prompts, medium generations) and one long-CoT workload (MATH-style prompts) as a stress case.

**Arrival regimes.** Steady Poisson at 50% and 90% of capacity, plus one bursty regime with CV=3.

**Seeds.** Three per condition.

**Metrics.** Signal range percentiles as defined in §3; admission rate; per-decision agreement between the two policies on identical arriving requests (fraction of requests where policy A admits and policy B rejects, or vice versa).

**Compute budget.** ~30 GPU-hours on Modal, ~$40.

### §5 Results (1.5 pp)

Structured around three claims, one paragraph and one figure each:

**R1: The KV-threshold signal is inert in the steady 50%-capacity regime.** Report the range of kv_cache_utilization observed; contrast against the 0.9 threshold. Expected finding based on the pilot data in the survey (KV signal stayed in [0.0000, 0.0071] against a 0.9 threshold in a similar setup). Confirmation would land the finding.

**R2: Under identical offered load, the two policies disagree on individual admission decisions at a rate that would be indistinguishable from noise if the reader only saw aggregate admission rate.** Report per-decision agreement matrix. Point: aggregate rate is not sufficient reporting; signal-liveness is what would have caught it.

**R3: Under the bursty regime the KV signal becomes live, but only above 90% capacity.** Report the crossover point. Confirms the survey's prediction that liveness is regime-dependent and cannot be assumed from the policy alone.

Table: for each (policy, regime) cell, report signal-range percentiles and admission rate. Table is the paper's central artifact.

### §6 Discussion (0.9 pp)

Three subsections, one paragraph each:

**§6.1 Implication for the seven reporting items.** Signal liveness (item 3 in the survey's seven-item contract) is the item that would have caught this. Adding one column ("signal range in reported deployment") to a results table costs one line and rules out the failure mode this paper measured.

**§6.2 Capability declaration as a runtime gate.** Sketch the schema (unit / setting / objective / requires / portability) and show pseudocode of the gate that refuses to deploy a KV-threshold policy against an engine that cannot supply KV utilization, or against a regime where prior probes show the signal is inert. This is where AdmitPerf (the harness that runs the experiments in §4-5) contributes a general-purpose mechanism, not just this paper's measurements.

**§6.3 What the survey cannot claim from this paper.** Two policies on one engine does not establish inert-signal frequency across the literature. It establishes that inertness is measurable, that it occurs on at least one published policy in a plausible regime, and that its absence from reported results is a genuine information gap rather than a stylistic omission.

### §7 Threats to validity (0.4 pp)

- Single engine (vLLM). SGLang and TGI may expose different signal profiles.
- Single small model. Larger models change KV pressure dynamics.
- Two policies out of sixteen. Broader replication is future work.
- Workload synthesis vs production traces. ShareGPT and MATH are proxies; agentic and multi-tenant workloads may differ.

### §8 Conclusion and reproducibility (0.4 pp)

One-command reproduction from a clean clone at a named commit; Modal cost stated. Companion survey cited as under review at ACM Computing Surveys with the exact submission date. Link to AdmitPerf repo (public, permissive license) for the harness itself.

---

## Figures / tables plan

- **Fig 1** (§1): stack diagram with the ingress boundary highlighted, redrawn from the survey.
- **Fig 2** (§3): signal timeseries for one live (queue-depth) and one inert (KV-threshold) policy on the same offered load. Load-bearing figure.
- **Fig 3** (§5, R2): per-decision agreement matrix between the two policies.
- **Fig 4** (§5, R3): crossover plot showing where KV signal becomes live as offered load rises.
- **Table 1** (§2): five-axis taxonomy recap with recoverable/not-recoverable column.
- **Table 2** (§5): (policy, regime) grid with signal-range percentiles and admission rate. Central artifact.

---

## Venue reframe wrappers

Same paper, different one-paragraph introduction and one different discussion emphasis. Everything else identical.

### MLSys workshops (ES-FoMo, ML for Systems)

**Intro emphasis:** systems measurement on real hardware; the shape is finding + evaluation + real workloads with no new algorithm, matching the precedent set by NVIDIA's prefill-decode disaggregation study at MLSys 2026 Industry Track. **Discussion emphasis:** operational implications for GPU serving deployments; capability-declaration schema as engine-agnostic contract; roadmap for adding more policies and engines. **Bio framing:** independent researcher on LLM serving systems, first author of systematic review under review at CSUR.

### ICLR workshops (ES-FoMo, Trustworthy ML / Evaluation)

**Intro emphasis:** evaluation methodology for a subfield where every paper claims improvement over a different baseline; a specific instance of the broader ML reproducibility discussion. **Discussion emphasis:** why signal-range reporting is analogous to the confidence-interval reporting norms in mainstream ML; connection to reviewer-checklist proposals at NeurIPS and ICLR; how the seven-item reporting contract could be adopted by future admission-control CFPs. **Bio framing:** same, plus positioning as methodology-oriented work in the trustworthy ML tradition.

---

## Prerequisites and honest state check

**What exists today (2026-09-27):**
- Survey manuscript at CSUR (Long Survey track), submitted 2026-09-26, under review.
- Pilot data referenced in the survey (KV signal in [0.0000, 0.0071] against 0.9 threshold on a KV-threshold policy).
- AdmitPerf harness (private, per prior sessions).

**What has to run before the workshop paper is submittable:**
- The measurements in §4-5. Approximately 30 GPU-hours on Modal at ~$40. Two weeks of focused work assuming the harness runs one policy end-to-end today. **Confirm state of Fluid-WAIT + KV-threshold experiment before committing dates.**
- Figures 2-4 rendered from the run data.
- Public-repo release of the harness, since one-command reproduction is claimed in §8.

**What can be drafted today, no experiments required:**
- §1 Introduction (grounded on survey).
- §2 Background (grounded on survey taxonomy).
- §3 Method protocol (grounded on survey's OP7 and the seven reporting items).
- §7 Threats to validity.
- Figure 1 (stack diagram, adaptable from survey figures).

**Timeline to submit-ready (assumes harness runnable today):**
- Week 1: run experiments, generate Figures 2-4, populate Table 2.
- Week 2: fill §4, §5, §6; polish §1-3, §7, §8.
- Week 3: internal review, AI-tell pass targeting zero em-dashes per the writing lessons.
- Total: 3 weeks of focused work.

**CFP dates to watch (verify at posting time):**
- ICLR 2027 workshop acceptance list: Nov 29, 2026. Per-workshop CFPs land Dec 2026 - Jan 2027. Paper deadlines Jan-Feb 2027.
- MLSys 2027 workshop list: not yet posted, expected Jan-Feb 2027.

**Compliance:** derivative workshop paper from a CSUR-under-review manuscript is allowed under ACM policy if (1) written notification is sent to the CSUR EiC AND the workshop program chair, (2) the workshop paper cites the CSUR submission as under review, and (3) the workshop paper carries a genuinely narrower and new empirical contribution. All three conditions are met by this design.
