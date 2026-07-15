---
name: parity-receipt
description: Use when verifying a built UI against a source-of-truth prototype or design and you cannot afford to miss granular behind-a-click details (dropdowns, expanders, tabs, modals, row-click destinations, cell-level links, revealed lists) or visual/design-intent divergence (layout, hierarchy, color roles), OR when verifying a single UI fix/feature by value inside a ship run - before sign-off, after a port, when testers keep filing interaction-level parity gaps, when prior reviews "looked at it" but missed leaf details. Formerly parity-sweep.
---

# parity-receipt

## Overview

Produces a **receipt** that a built UI matches its source of truth: not "we
looked at it" but a per-leaf artifact whose completeness a script can check.
Two modes:
- **Mode 1 - scoped receipt** (the daily workhorse; ship invokes it on every
  UI fix): by-value verification of one fix/feature.
- **Mode 2 - full receipt** (surface/app sign-off; `proto-port`'s finishing
  step): mechanical crawl-diff of both running apps, every flow driven to
  its terminal action, and a design-intent judgment on every captured
  screenshot pair.

Core principle: parity bugs hide in **revealed state** (what a click shows)
and **leaf attributes** (is the revealed cell a link, where does it route),
which neither a code read nor a glance can prove. **Enumeration is
mechanical wherever possible** - a crawl script does not get tired at
surface 26 of 34, while hand enumeration by agents is the documented failure
mode (the June-8 sweep left 9 surfaces unconfirmed with nothing flagging
it). Agents do semantic judgment and flow-driving, not counting.
Verification asserts VALUES on the live app; the gate is validated by
script, never asserted in prose.

## Mode 1 - scoped receipt (one fix/feature, no fan-out)

1. Read the source-of-truth CODE for the feature and extract the expected
   VALUES/states (badge text, colors, formulas, routes). The source code is
   the spec - do not ask for screenshots of it.
2. Drive the app's exact flow to the leaf (the DEPLOYED build for any
   close-out claim).
3. Assert by VALUE: `input.value` (a grey placeholder showing the expected
   text is a FAIL - the field is empty), the `<select>`'s selected option
   (not the option's existence), checked state (not the control's presence),
   computed style, the rendered number. Presence is never a content pass.
   Cover each state behind a toggle/expander (on -> edited -> reverted).
4. Judge the changed area's LOOK against the source of truth whenever the
   change is visible: layout, hierarchy, and color ROLE (design intent, not
   pixels). A control that keeps its data and behavior but loses its look -
   a colored action button shipped white/transparent - is a FAIL.
5. Confirm no-regression on a sibling that should be unchanged.
6. If the fix sits inside a multi-step flow, drive to the TERMINAL action
   (submit/activate/save) accepting pre-filled defaults - step-local checks
   miss the state-seam regressions that only surface at the final gate.
7. If the fix changes a shared PATTERN (control, label, icon placement,
   mask, color convention), check the twin surface implementing the same
   pattern - diverged twins are a finding even when each looks fine alone.
8. Glance at the console - a render that "works" while logging exceptions is
   a finding.

## Mode 2 - full receipt (surface or app sign-off)

Inputs: the source-of-truth (code path and/or running URL), the app (code
path + running URL), optional surface scope. PAUSE and ask the user at any
login/auth wall - never enter credentials. Which parts may fan out is
`fanout` VERIFY-MODE's rule: data/by-value reads parallelize; an authed
deployed-UI session serializes on the orchestrator; the gate-read and the
judgment never leave the orchestrator.

1. **Enumerate mechanically.** Write a per-run crawl script (Playwright /
   chrome-devtools) and run it against BOTH running apps: walk routes (from
   router/nav), enumerate every interactive node, PERFORM each reveal
   (click/hover/expand/tab/advance) and record the revealed structure -
   elements, columns, copy, link targets, and for each revealed sub-element
   whether it is itself interactive and where it routes. Crawl to a
   **fixpoint** (re-crawl until a pass adds no new node - loop-until-dry as
   a computation, not a promise). Node contract:
   `{id (dot-path), kind, route, revealed: [...], links: [...], step_advances_to}`.
   Supplement with AST/route extraction (graphify-style) for states
   unreachable behind missing data, flagging those as seed-gaps. Hand
   enumeration by an agent is the FALLBACK only (no running app) - if used,
   the receipt must say so and why.
2. **Machine-diff** the two node sets into candidate `MISSING` /
   `DIVERGENT` / `EXTRA` leaves. Scripts find structural gaps; they cannot
   judge semantic equivalence - that is the next step, and skipping it (or
   treating an empty diff as "done") is a red flag below.
3. **Mapper agent** (`subagents/crawl-mapper.md`): map proto nodes to app
   nodes where ids differ but meaning matches; judge semantic equivalence;
   classify per the taxonomy; attach `src: file:line` on both sides. NEVER
   roll leaves up into a headline finding - rollup is how the
   customer-ledger link leaf got buried.
4. **Flow-driver agent(s)** (`subagents/flow-driver.md`): drive EVERY
   multi-step flow Step-1 -> TERMINAL on seeded data (proto side too when a
   behavior comparison is needed); by-value evidence per interactive leaf
   (screenshot + DOM value read). A step the proto reaches that the app
   cannot is `MISSING` for that step AND every step downstream, plus a
   top-severity blocker. An empty/sparse surface (0 rows, or 1 vs the
   proto's N) is a `seed-gap` + an INCOMPLETE receipt, never a pass: seed
   it and re-drive.
5. **Visual judge** (`subagents/visual-judge.md`): for EVERY leaf whose
   evidence carries a proto_shot + app_shot pair, judge DESIGN-INTENT
   equivalence - layout, hierarchy, spacing rhythm, emphasis, and color
   ROLES (is the primary action visually primary; is a colored action
   still colored) - never pixel equality: the two stacks legitimately
   differ in fonts, widths, and rendering, and pixel-diffing them is
   noise. A leaf that keeps its data and behavior but loses its look is
   `DIVERGENT` with `facet: visual` (the 2026-06-29 button-color revert is
   the canonical case). A pair the judge cannot call (intent vs rendering)
   is `borderline`: the leaf keeps its verdict, the pair still counts as
   judged, and the id is surfaced in the report for a human glance - never
   silently dropped. Record the roll-up on the artifact
   (`visual: { pairs_judged: N, divergent: [ids], borderline: [ids] }`);
   `pairs_judged` must equal the shot-pair count - that is how the gate
   proves this pass ran.
6. **Adversarial verifier** (`subagents/adversarial-verifier.md`): re-check
   every non-PARITY leaf against evidence (visual facets included), kill
   false positives, stamp `user_impact`, then **validate the gate
   mechanically** - a few lines of python/yq confirming every leaf is
   verdicted, every interactive leaf's evidence files exist on disk, and
   `visual.pairs_judged` equals the shot-pair count, printing the roll-up
   (surfaces x leaves x verdicts). Anything unverdicted makes the receipt
   INCOMPLETE, loudly (the June-8 run shipped 9 unconfirmed surfaces
   silently; this line exists because of it).
7. **Conflicts go to the user.** `CONFLICT` (the proto contradicts a shipped
   spec, or the build is deliberately ahead: real backend vs proto mock,
   richer status set) is a USER decision - keep the app as-is, record both
   sides, surface the list. Only `MISSING`/`DIVERGENT` route to fixes
   automatically.

## Artifact + gate (single source of truth - proto-port references this)

One file per surface, `parity/<surface>.yaml`, one entry per leaf:

```yaml
- id: customer-ledger.row.expand.account-row.link
  kind: link        # static|row|dropdown|expander|tab|modal|button|hover|link|cell|step
  label: "expanded account row -> account detail"
  proto: { revealed: "per-account rows, each links", route: "/account/:id", src: "file:line" }
  app:   { revealed: "sub-table, not linked", route: null, src: "file:line" }
  status: BUILT          # port runs only: BUILT|PENDING|BACKEND-GATED|SCOPED-OUT (build axis)
  verdict: DIVERGENT     # parity axis - independent of status; never conflate the two
  facet: structural      # non-PARITY leaves: structural|behavioral|visual - which dimension diverges
  user_impact: high      # blocker|high|low - stamped by the verifier; orders the report
  evidence: { proto_shot, app_shot }
```

**Taxonomy:** `PARITY` | `DIVERGENT` (present, different) | `MISSING` (in
proto, absent in app) | `EXTRA` (app exceeds proto - note, not a defect) |
`CONFLICT` (user decides) | `BACKEND-GATED` (UI present, data/endpoint
absent) | `SCOPED-OUT` | `seed-gap` (unexercisable).

**Gate:** a surface is receipted only when 100% of its leaves carry a
verdict, every interactive leaf has by-value browser evidence, every
screenshot pair carries a visual judgment (`visual.pairs_judged` equals the
pair count), every multi-step flow was driven Step-1 -> terminal, and the
surface was actually exercisable (seeded). Script-validated, not asserted. `user_impact` orders
the report; it can never bury a leaf, because the per-leaf entry persists
regardless.

**Re-runs are incremental:** verdicts key to the app files they cover
(`app.src`) + the app commit; a re-receipt re-drives only leaves whose
files changed since, plus anything INCOMPLETE. A Mode-1 verified fix counts
as fresh evidence for exactly the leaves it drove, at the commit it drove.

## Common mistakes (red flags - STOP)

| Rationalization | Reality |
|---|---|
| "The table matches, looks the same" | You compared the visible row. Expand it - the parity bug is in the revealed state. |
| "Captured the expanded columns, good enough" | Is each revealed cell a LINK, and where does it route? That's the leaf. |
| "I'll roll the small ones into the big finding" | Rollup buries leaves. Every leaf keeps its OWN verdict in the artifact. |
| "Code looks equivalent, skip the browser" | Behind-a-click state is only proven by driving. No evidence = not receipted. |
| "The crawl diff found nothing, we're done" | The script finds structure. Semantic judgment (mapper) and behavior (flows to terminal) are still open. |
| "I'll enumerate by hand, it's just one surface" | Hand enumeration is the documented failure mode. Write the crawl script; hand-fallback only without a running app, stated in the receipt. |
| "Representative sample is enough" | The miss is always in the element you didn't drive. Drive every interactive leaf. |
| "Queue's empty but the page renders - pass" | An unexercisable surface proves nothing: `seed-gap` + INCOMPLETE. Seed every path (incl. failure branches) and re-drive. |
| "Step 1 renders correctly, the workflow's fine" | Drive Next -> ... -> terminal. A wizard stuck/missing past Step 1 is the #1 tester blocker, and a Step-1 look cannot see it. |
| "The placeholder shows the right text" | A placeholder is an EMPTY field. Read `value`. FAIL. |
| "Same elements, same handlers - PARITY" | Same structure with the wrong LOOK is still DIVERGENT (`facet: visual`). Judge the screenshot pair - a colored action gone white/neutral is the canonical miss. |
| "The screenshots differ, flag it all" | Cross-stack pixel differences (fonts, widths, rendering) are noise. Judge design INTENT - layout, hierarchy, color roles - and flag only intent breaks. |

## Standing regression corpus

`known-misses.md` (this directory) lists the historical production misses
this method exists to catch. ANY edit to this skill, `proto-port`, or the
subagent prompts must re-verify each entry is still caught by the edited
text (walk the method against the miss; if it no longer forces the catch,
the edit fails). New production misses are added to the corpus FIRST, then
the skill is patched - failing test before fix.

## Related

- `proto-port` - the build sibling: translate-first port that finishes by
  invoking this skill and uses this artifact's `status` axis.
- `fanout` - VERIFY-MODE governs which verification labor fans out.
- `ship` - invokes Mode 1 on every UI fix (its by-value verification step in
  depth).

Design rationale + restructure history: `REFERENCE.md`.
