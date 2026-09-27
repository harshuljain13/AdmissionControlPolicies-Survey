# Review of paper-skeleton.md

Checked 2026-09-27 against the survey source and the AdmitPerf run the skeleton
cites. Three claims do not hold. The third determines whether the central
experiment measures anything.

---

## 1. The survey finding is stated backwards

`paper-skeleton.md:31`:

> four axes of the five-axis taxonomy are recoverable from every paper (unit,
> setting, objective, portability). One axis is recoverable in name but not in
> operating range

The survey, `body.tex:784`:

> Six of the seven fill, and all five axes are among them.

And at `body.tex:774`, about the two extra properties:

> The last two are not axes.

All five axes fill, including signal quantity. Signal *range* is not an axis; it
is one of two additional properties recorded to test whether the axes are usable.
The skeleton says four of five axes fill where the survey says five of five, and
promotes a non-axis into the taxonomy.

This matters beyond pedantry. A reviewer holding both documents sees the
workshop paper contradicting the survey it cites, on the survey's own headline
result. Fix: "the five axes are all recoverable; a sixth recorded property, the
range the signal took, is recoverable for none of the sixteen."

## 2. The quoted definition is not in the survey

`paper-skeleton.md:39`:

> Key definition, quoted from survey: a policy's signal is **inert** in a regime
> if the range observed during a representative offered-load probe stays inside
> a configurable band around its neutral value (default: within one
> decision-threshold width of the policy's admit boundary).

The survey uses "inert" twice, at `body.tex:1776` and `body.tex:1792`, both
times informally and both times inside a statement about what has *not* been
done. It defines no band, no probe, and no default width. The quoted definition
does not exist in the source.

Presenting it as a quotation is the failure mode this project has already hit
twice: Token Pools quoted as "multiple criteria" when the source says "multiple
factors", and OmniServe given a claim taken from a search snippet rather than the
paper. Fix: state the definition as this paper's own contribution, which is what
it is, and a reasonable one.

## 3. R1 rests on a run that could not have produced any other result

This is the blocking problem.

`paper-skeleton.md:77` and `:137` cite "pilot data in the survey (KV signal
stayed in [0.0000, 0.0071] against a 0.9 threshold)" as grounds for expecting
R1 to confirm.

**The survey contains no such data.** Grepping the source for `0.0071` returns
only this skeleton. The survey says the opposite, at `body.tex:1786`:

> Neither is a measurement. We did not run the policies, and we do not claim to
> have observed a policy failing this way in a deployment.

The number comes from `admitperf/experiments/half-capacity-headroom`. That run's
KV-threshold arm reports:

```
admitted = 407
rejected = 0
admit_rate = 1.0
```

The policy never rejected anything, because the signal never reached 0.9. The
skeleton reads that as evidence the signal is inert. The configuration says
otherwise:

```yaml
model: Qwen/Qwen2.5-0.5B-Instruct     # skeleton says Qwen3-1.5B; neither matches
gpu: A10G                              # 24 GB
gpu_memory_utilization: 0.85           # ~20 GB, minus ~1 GB of weights
max_num_seqs: 10                       # concurrency cap
rate: 4.0                              # requests/sec
```

A 0.5B model given roughly 19 GB of KV cache, with concurrency capped at ten
sequences, cannot fill that cache. The ceiling is ten sequences' worth of
context against a cache sized for orders of magnitude more. KV utilization near
zero is the arithmetic of the configuration, not a property of the policy.

The experiment's own config file says this, in a comment:

> gpu_memory_utilization also went 0.25 -> 0.85: at 0.25 the KV cache is so
> small that kv_used_fraction never approaches any useful threshold, which is
> the trap already documented in docs/results.md

The trap was identified and the fix was applied in the wrong direction for this
purpose. Raising the memory fraction made the cache larger and the signal less
reachable, which was correct for the experiment it was tuned for and is fatal
for this one.

There is also the prior finding, from the session where this run was examined:
the engine never saturated. `waiting_requests` was identically zero and
`running_requests` peaked at six to eight against a cap of ten. At rate 4.0/s
with that cap, the load never arrived.

**Consequence.** If the workshop experiment reuses this configuration, R1 will
"confirm" that the KV signal is inert, and the finding will be an artifact of
giving a small model a large cache and a low concurrency cap. A systems reviewer
will identify this immediately, and the paper's central result will not survive
review.

**Fix.** Before any prose is written against §5, establish a configuration in
which the KV signal demonstrably *can* reach 0.9: raise `max_num_seqs`, lower
`gpu_memory_utilization`, use a larger model, or use long-context workloads that
actually consume cache. Then finding it pinned under realistic load is a result.
Without that, §5 is unwritable.

---

## Smaller items

**Authorship.** The skeleton lists Harshul Jain alone; the survey has five
authors. Resolve before drafting, since it changes the acknowledgement and the
relationship between the two papers.

**Submission date.** `:5` and `:136` state the survey was submitted 2026-09-26.
Confirm it actually went through before citing a date in a paper.

**Harness availability.** `:138` says AdmitPerf is private; `:104` promises
one-command reproduction from a public repository. One of those has to change.

**Model mismatch.** `:57` specifies Qwen3-1.5B; the cited pilot ran
Qwen2.5-0.5B. If the pilot is the basis for expecting a result, the model has to
match, and Qwen3-1.5B may not exist as named.

---

## What survives

Most of it. The structure is sound, the venue analysis is right, the split
between what can be drafted now and what needs experiments is honest, and the
threats-to-validity section is appropriately narrow. §1, §2, §3, §7 and Figure 1
can be written today once item 1 and item 2 are corrected.

The three-week timeline at `:152` is the part to discard. It assumes the harness
runs today, and the harness currently produces a measurement that means nothing
for this question. Budget the configuration work first and time the writing off
that.
