# Token Pools

**Full title**: Token Management in Multi-Tenant AI Inference Platforms
**Author**: William J. Cunningham (sole author)
**Venue**: CAIS '26  ·  arXiv:2603.00356, submitted 27 Feb 2026, 10 pages
**Verified**: 2026-09-21 (full PDF text-extracted)

## Taxonomy placement
- Unit: **tenant** (entitlement)  ·  Setting: **online**  ·  Decision moment: **ingress**
- SLO-awareness: priority and tiered guarantees  ·  Signal: entitlement state + priority threshold

## Role in the survey
The partial counter-example to the nine-paper finding: it sits outside the seven-venue
slice and does gate at the API boundary.

## Verified claims
§4.3, verbatim: "The auth service intercepts every request before it reaches the backend.
On each request, it validates the API key against an entitlement, retrieves the
entitlement's current state from Redis, and makes an admission decision based on multiple
factors."

Rejection contract, verbatim: "Under contention, the admission threshold is set to the
minimum priority among currently-admitted requests. Requests with priority below this
threshold are rejected with HTTP 429 and a Retry-After header, allowing clients to back
off gracefully."

Evaluation, verbatim: "a single-node cluster with one vLLM replica serving
nvidia/Qwen3-8B-NVFP4, providing capacity for 16 concurrent sequences ... at a total
throughput of roughly 240 tokens/sec" on **a DGX Spark**. The authors defend the
constrained setup: "token pools operate at the admission control layer, where behavior
depends on the ratio of demand to capacity rather than absolute scale."

Coupling with autoscaling, from the abstract: "token pools authorize both admission and
autoscaling from the same capacity model" — which is what makes it the anchor for OP5.

## Correction made (2026-09-21)
The survey quoted the admission sentence as ending "based on multiple **criteria**". The
source says "multiple **factors**". Corrected, since it sat inside quotation marks.
