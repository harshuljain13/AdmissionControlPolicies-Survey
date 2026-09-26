# Cover letter

*Paste into the ScholarOne cover-letter field, or attach as a PDF if the form
prefers one. Fill in the editor's name if the submission form asks you to address
someone specific. This file is not part of the manuscript and is not anonymised;
the editor sees it, reviewers do not.*

---

Dear Editors,

We are submitting "Admission Control for LLM Inference Serving: A Systematic
Review" for consideration at ACM Computing Surveys.

The paper reviews fifty-five works published between 2022 and 2026 on the
decision made before a request enters an LLM serving system: admit it, hold it,
or refuse it. We followed an adapted PRISMA protocol, and the per-paper coding
sheets are released with the paper so the classification can be checked.

CSUR describes a survey article as one that emphasises classification of existing
literature, developing a perspective, and evaluating trends. That is what we set
out to do. The taxonomy classifies the corpus on five axes.

Three findings came out of it.

Admission control turns out to sit at a layer the serving literature does not
study. We took the nine serving systems that the admission-primary papers most
often build on or compare against, and all nine handle overload inside the engine
through batching, migration, placement, autoscaling or memory management. None
takes a decision at the ingress. The corpus work that does gate at ingress is a
control-plane contribution rather than an engine one, which is the distinction
that matters here; it is not about venue, and we say in the paper that we would
draw the same conclusion had that work appeared alongside the nine.

We are careful about how this reads. Those nine are scheduling and
memory-management papers, and refusing work at the door is outside the problem
each of them set for itself. It is an observation about where attention has gone,
not a criticism of those systems.

No two of the sixteen admission-primary papers share a baseline set. Policies are
measured against the absence of admission control and almost never against one
another, so a practitioner cannot use the literature to decide which policy suits
their deployment.

The third finding came out of testing whether the taxonomy was usable. We placed
all sixteen papers on it, recording seven properties each: the five axes, plus
what a policy assumes an arriving request carries, plus the range its signal took
during the paper's own evaluation. Six of the seven filled from the published
text, and all five axes were among them. One property did not fill for any
paper. None reports the range its own signal took during the
evaluation, which means a policy whose threshold was never approached and a policy
that evaluated a varying signal and declined to reject produce the same reported
numbers. We state this as an absence in our extraction rather than as a proof that
no such reporting exists anywhere, and we have written a threats-to-validity
section that says so plainly.

On positioning: five surveys of LLM inference serving precede this one. Zhen et
al., Heisler et al., and Li et al. cover efficient serving broadly and treat
admission as one component among many. Mitzenmacher and Shahout give the
queueing-theoretic view and enumerate a theoretical agenda; our open problems
overlap theirs on reasoning workloads and on schedulability, and we say so in
Section 10 rather than claiming the lists are disjoint. Ma et al. address load
balancing, which is routing rather than ingress. None of the five makes admission
the primary axis, and none audits what the literature reports.

Two disclosures. First, the screening and coding were done by one reader, so there
is no inter-rater agreement statistic; we have owned that in the
threats-to-validity section and released the coding sheets so the placements can be
disputed. Second, we intend to post a preprint to arXiv. If it is up before review
concludes we will note the prior appearance on the title page, and we understand
this does not count as prior publication under CSUR's policy. We have not
submitted this work anywhere else.

The manuscript runs to 30 pages in the acmsmall template, which we understand
falls under the full survey category rather than the short one.

Thank you for considering it.

Sincerely,

Harshul Jain, Tanmay Sah, Tanya Sah, Parv Khatri, Dolly Sah
Corresponding author: Harshul Jain (harshuljain1393@gmail.com)
