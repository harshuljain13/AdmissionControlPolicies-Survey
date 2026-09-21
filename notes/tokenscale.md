# TokenScale — SCREENED OUT

**Full title**: TokenScale: Timely and Accurate Autoscaling for Disaggregated LLM Serving with Token Velocity
**Authors**: Ruiqi Lai, Hongrui Liu, Chengzhi Lu, Zonghao Liu, Siyu Cao, Siyang Shao, Yixin Zhang, Luo Mai, Dmitrii Ustiugov
**Venue**: arXiv:2512.03416 (2025)
**Verified**: 2026-09-21 (full PDF, 74 KB extracted)

## Status: examined, excluded from the corpus
Cited in §6 precisely to record the exclusion, so that a reader does not read its absence
as an oversight.

## The exclusion claim — VERIFIED
The survey states it is "a pure autoscaling framework (Token Velocity signal drives
prefiller/decoder scaling only) with no admission-control component."

Term counts over the full text:

| term | count |
|---|---|
| admission, admit, reject, refuse, shed | **0** |
| Token Velocity | 54 |
| prefiller | 99 |
| decoder | 158 |
| autoscal | 50 |

The only adjacent phrase is a single "drop request" in Related Work, describing *other*
systems and explicitly contrasting them: "Some methods rely on SLO-aware routing
strategies that drop requests when necessary [8], [48] ... In contrast, TokenScale
han[dles]..."

The exclusion is correct and now evidenced rather than asserted.
