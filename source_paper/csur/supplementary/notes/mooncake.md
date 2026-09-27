# Mooncake

**Full title**: Mooncake: Trading More Storage for Less Computation---A KVCache-centric Architecture for Serving LLM Chatbot
**Authors**: Ruoyu Qin, Zheming Li, Weiran He, Mingxing Zhang, Yongwei Wu, Weimin Zheng, Xinran Xu
**Venue**: **FAST '25**  ·  arXiv:2407.00079
**Verified**: 2026-09-21 (abstract)

## Why it appears in the survey
Cited for memory management (§1) and as a baseline in Scorpio's evaluation
(Table~\ref{tab:baselines}).

## The admission claim — VERIFIED
The survey describes Mooncake as "itself an early-rejection mechanism". The abstract
states verbatim: **"we developed a prediction-based early rejection policy"**, motivated
by the fact that Mooncake, unlike "traditional studies that assume all requests will be
processed", faces "highly overloaded scenarios".

This matters twice over. It confirms that Scorpio's comparison against Mooncake is a
policy-versus-policy comparison rather than a policy-versus-engine one, which is what
Table 2's caption claims. And it supports the survey's characterisation of Mooncake as
touching admission.

## Why it is not in tab:master
Not because the paper states no decision rule; it does. The narrower ground is that
admission is a component of a disaggregation architecture rather than the paper's
contribution: the rejection policy is described but not evaluated as a policy, with no
ablation isolating its effect and no comparison against an alternative admission rule.

**Note**: an earlier version of the survey justified the omission by saying the paper
"does not claim a decision rule". That was wrong and has been corrected.

## Bibliography corrections (2026-09-21)
- `author={Qin, Ruoyu and others}` replaced with the full seven-author list.
- Title was truncated to the first clause; now the full FAST '25 title.
