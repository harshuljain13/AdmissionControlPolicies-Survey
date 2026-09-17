# 6.2 Why this minimum: a sensitivity study

*Draft for `paper.md`, to follow 6.1. No em-dashes, per house style. Every
number is traceable to a bundle in the companion repository; the provenance
label on each claim is deliberate and should survive editing.*

---

Section 6.1 proposes a minimum set of things an admission-control paper should
report. A contract proposed on taste is worth little, so this section derives
each item from a measurement. We took one published algorithm, implemented it
faithfully, ran it on a rented GPU, and moved the parameters that no paper is
currently obliged to report. The result moved with them.

The specimen is a port of the Chronos admission test (Algorithm 1), chosen
because it is recent, formally specified, and comes with proofs. We are not
evaluating whether Chronos is a good policy. We are asking a narrower question:
**can a faithful implementation of a published policy be made to report
different conclusions without changing the algorithm?** It can, six ways.

All measurements use one NVIDIA A10G on Modal, Qwen2.5-0.5B-Instruct on vLLM
0.29.0, with a concurrency cap of 10 and a Poisson arrival process over three
SLO classes. One deployment, one model, one accelerator: nothing here
generalizes to other hardware, and that limitation is itself part of the
argument.

## 6.2.1 The context window has to be reported against the traffic

The default workload generates requests of up to 6144 tokens. The engine was
configured with a 2048-token context window. vLLM answers an over-long request
with HTTP 400, and the harness recorded those as admitted requests that failed.
Roughly a third of every run was configuration error wearing the costume of
overload, and the summary statistics could not tell the difference.

A reader of such a result would see a policy performing badly under load. The
policy was never consulted.

> **Report the engine's context window against the token-length distribution of
> the workload.** A benchmark harness should refuse to start when the workload
> can generate requests the engine cannot accept.

## 6.2.2 Repeats are not optional, and the spread is the result

One configuration, three repeats differing only in the seed of the arrival
process. The policy admitted **0.0%, 34.0% and 4.1%** of offered traffic, for
offered-SLO attainment of 0.000, 0.222 and 0.024 respectively.

Any one of those runs is a true statement about the policy. Published alone,
each is useless, and the three support three different conclusions. Note that
this is variance across traffic samples rather than nondeterminism: the
configuration is identical and the seeds are not.

> **Report at least three repeats and the observed spread.** A single run is a
> measurement, not a comparison.

## 6.2.3 A policy that cannot see anything is still a row in the table

A KV-pressure policy with a 0.9 threshold admitted 100% of traffic in all three
runs. Its attainment, 0.5537, is indistinguishable from the uncontrolled
baseline's 0.5553.

The reason is visible only in the decision log. Across 485 decisions,
`kv_used_fraction` ranged from **0.0000 to 0.0046**, against a threshold of 0.9.
On a 0.5B model with a small concurrency cap, the cache never fills; the binding
constraint is the concurrency cap, and the signal that moves is the wait queue.
The policy was structurally incapable of refusing anything, and its row in the
results table is the baseline under another name.

> **Report the observed range of the signal the policy reads.** A policy whose
> signal never approached its threshold did not run, whatever the table says.

## 6.2.4 Inherited constants decide the answer

The Chronos admission test is parameterised by a prefill cost model: a per-token
cost and a fixed per-chunk overhead. The source paper derives them from a
roofline model for a 7B model on an A100-80GB. We run a 0.5B model on an A10G.

Holding everything else fixed and sweeping those two constants across plausible
values for the two hardware configurations, the admit rate moves from **1.8% to
100%** (Figure N). The algorithm is unchanged. The traffic is unchanged. Two
numbers carried across from another accelerator decide whether the policy
refuses almost everything or admits everything.

This sweep is analytical rather than measured: arrivals are synthesized, the
system state is held fixed, and telemetry fitting is disabled so the constants
remain where they are set. On a live engine the same constants would also move
the fitted parameters and the state the test reads, so the true sensitivity is
at least this large.

> **Report which parameters were fitted on the evaluation hardware and which
> were inherited from the source.** An inherited constant is a hidden
> configuration variable.

## 6.2.5 Load has to be expressed relative to what the machine can serve

The same offered rate is a different experiment on every deployment. At 4
arrivals per second our deployment met 55% of deadlines while admitting
everything; earlier configurations of the same hardware were an order of
magnitude oversubscribed at 15 arrivals per second. "15 requests per second"
tells a reader nothing without the capacity it is a fraction of.

> **Report offered load as a multiple of measured serveable rate, and state how
> capacity was measured.** A benchmark should provide a capacity probe so this
> is cheap to obtain.

## 6.2.6 Deadlines have to be expressed relative to the machine's own latency

Our interactive class carries a 500 ms first-token deadline. Under load the
measured p50 was between 281 and 293 ms. A worst-case admission test cannot
certify a system whose typical latency sits that close to the deadline, so the
formally correct behaviour is to refuse almost everything, which is what
happened, while an uncontrolled baseline met 55% of the same deadlines.

The policy is not wrong. The deadline was set in absolute milliseconds on
hardware whose service time nobody measured first.

> **Report deadlines as a multiple of measured unloaded latency.** Absolute
> milliseconds do not transfer between accelerators or model sizes.

## 6.2.7 What this does and does not show

It does not show that Chronos is a poor policy. Every failure above is a
property of how we configured and calibrated the experiment, which is precisely
the point: a reader of a published table cannot distinguish a policy that
performed badly from one that was mis-calibrated, mis-loaded, or never
consulted, because the information needed to tell them apart is not currently
required.

It also does not show that the effect is unique to one algorithm. Two of the six
knobs (6.2.2, 6.2.3) were observed on a threshold policy as well. Demonstrating
the remainder on a second published algorithm from a different family is the
next step, and is in progress.

What it does show is that six parameters, none of which a reader can currently
demand, each move a published policy's reported behaviour across most of its
possible range. Section 6.1's contract is the minimum set that makes those six
visible. Each item exists because we watched the result move when it was
absent.
