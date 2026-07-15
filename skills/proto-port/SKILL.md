---
name: proto-port
description: Use when building or porting a surface, page, module, or feature FROM a prototype or design source of truth - "port the X page from the prototype", "build module N to match the proto", net-new screens where a runnable/readable prototype exists and testers will compare the build against it leaf by leaf. Formerly parity-builder. NOT for fixing tickets on an existing surface (ship) and NOT for verifying an already-built surface (parity-receipt).
---

# proto-port

## Overview

Ports a surface from its prototype by **translating the prototype's code
directly** (translate-first: the proto source is the input, never a story,
summary, or hand-built inventory of it), re-creating the three things
translation cannot carry (data, backend contract, runtime behavior), and
finishing with a `parity-receipt` proving nothing was dropped.

**The two failures this prevents (both documented in this project's history):**
- **Indirection sheds leaves.** The original app build fed stories and
  sweep-summaries of the proto into the build instead of the proto code
  itself; every lossy intermediary drops leaves, and testers file each
  dropped leaf as a ticket (the ~50-ticket M4/M5 wave was root-caused to
  story-anchored building).
- **Unchecked regeneration ships the leaner cut.** Cross-stack translation is
  regeneration by a model, not transpilation; even with the source fully in
  context, output samples (validated: a blind parity audit rediscovered 3/3
  of a tester's just-filed gaps on a module an 89-agent correctness audit had
  passed). The translation's "I did all of it" is a claim authored by the
  thing being checked - hence the receipt.

## Step 0 - translation-distance triage

Assess how much the port must INVENT, then pick the lane:
- **Distance ~0** (same stack, proto already calls the real API,
  production-grade code): **PROMOTE** the proto - fork it, then run only the
  seeds pass (step 3) and a smoke `parity-receipt`. Running the full flow
  here is waste; the skill's weight must scale with translation distance.
- **Distance large** (mock data, different framework, backend endpoints don't
  exist yet - the usual case): full flow below.

## Flow

1. **Contract-extraction pass (before any FE work).** The proto's mock data
   encodes an implicit API: every rendered field, enum value, derived number,
   and status the UI can display. Extract that into an explicit contract list
   and check the real backend serves each item (cross-repo contract check).
   Gaps become explicit work items or `BACKEND-GATED` entries - never silent
   per-component invention mid-translation. A proto-vs-backend contradiction
   (a status the real payload can never produce, persistence the model
   doesn't have) is a `CONFLICT`: state both sides, let the USER decide -
   never silently down-build to the mock and never silently invent. While a
   port's CONFLICT awaits the user (no existing app behavior to keep),
   render only what the real contract can truthfully support - derive
   honestly from the actual payload, label honestly, never fabricate the
   proto's impossible state. Stories/specs are CONTEXT here (scope,
   priorities, tie-breaking a CONFLICT), never the translation input. If
   the setup provides a trajectory memory, query the surface before
   planning - a prior port's recorded failure is spec input.
2. **Translate-first implementation.** The proto source files are the direct
   input: translate whole files, component by component, in a worktree.
   Never work from a story, a summary, or a leaf inventory - the code is the
   only complete representation of itself. Maintain a **file map** as you
   go: every in-scope proto file -> the impl file(s) it became, or
   `BACKEND-GATED`/`SCOPED-OUT` with a reason. Plan the fan-out with
   `fanout` (file-disjoint parallel vs shared serial, risk-tier per leaf);
   implementers return `file:line - claim - evidence` + `totals:` per ship's
   subagent contract - you review diffs, run gates, and commit yourself. For
   any leaf that adds a backend endpoint, add its client-side wiring (proxy /
   route handler, generated client) in the SAME pass and run the cross-repo
   contract check before the PR - an endpoint with no client wiring 404s at
   runtime.
3. **Seeds pass.** Translation DELETES the proto's mock data, and that data
   was half the spec (populated states, example counts, failure branches).
   Re-create it as real seeds (the project's seed command / fixtures): every
   path including failure branches (returned/declined/over-limit/blocked),
   roughly the proto's example count, AND check the empty state - the app
   boots against an empty DB, a state the proto cannot even render. An
   unseeded surface cannot be receipt-verified and ships as a tester's seed
   ticket.
4. **Receipt + gates.** Finish with `parity-receipt` (full) over the built
   surface: the crawl-diff + drive-to-terminal harness writes the per-leaf
   verdicts (use its artifact's `status` axis for build-state). A multi-step
   workflow is ONE port unit - every step, Step-1 -> terminal advancement on
   seeded data, terminal action persists - never a per-field or single-step
   slice. Fix `MISSING`/`DIVERGENT` findings; `CONFLICT`s go to the user.
   Then the normal gates: PR + CI-green (ship step 7), never direct-push. At
   close-out, append to the trajectory memory (if the setup provides one):
   surface, outcome, files, what worked/failed, and any gap the receipt caught.

## Completion gate

A port is done only when:
- the **file map** covers 100% of in-scope proto files (impl pointer, or an
  explicit `BACKEND-GATED`/`SCOPED-OUT` reason - nothing dropped silently);
- the **contract list** has no silently-invented entries: each proto-implied
  field/enum is served, `BACKEND-GATED`, or `CONFLICT`-flagged for the user;
- **seeds** exist for every path including failure branches, and the empty
  state renders;
- the **parity-receipt is green**: 100% of crawled leaves verdicted, every
  flow driven Step-1 -> terminal on seeded data, every screenshot pair
  visually judged (design intent), conflicts surfaced.

Coverage is a number, not a claim. The unmapped file and the undriven step
are where the tester's ticket comes from.

## Failure modes (red flags - STOP)

| Rationalization | Reality |
|---|---|
| "I'll build from the story/spec doc" | Stories are thinner than the proto. Indirection sheds leaves - the proto CODE is the input. |
| "Cartograph/inventory first, then build" | Retired rule (pre-2026-07). A hand inventory is a lossy intermediary too, and its completeness gated the build's. Translate the code; the receipt comes AFTER, mechanically. |
| "I translated every file - ship it" | Regeneration samples even with the source in context. No receipt = an unverified claim by the claimant. |
| "The mocks show the data, so data's handled" | Translation deletes the mocks. Seed every path + failure branches, and check the EMPTY state. |
| "I'll wire each component to whatever API shape fits" | Per-component contract invention fabricates UI states the backend can never produce. Extract the contract first; gaps are BACKEND-GATED or user-decided CONFLICTs. |
| "Steps render, the wizard's basically done" | Every step's JSX can translate faithfully while the flow can't advance on real persistence. Drive Step-1 -> terminal; "stuck at Step 1" was the M5 wave's #1 blocker. |
| "95% mapped, close it out" | The unmapped 5% are exactly the tickets testers will file. 100% or it's open. |
| "The proto does X, the app deliberately does Y - I'll pick" | That's a CONFLICT. Keep the app, note both sides, USER decides. Never silently down-build to a leaner/mock proto. |

Any edit to this skill must re-verify against
`~/.claude/skills/parity-receipt/known-misses.md` (the standing regression
corpus) - failing test before fix.

## Related

- `parity-receipt` - verification sibling: crawl-diff harness, scoped
  fix-verify, and the artifact format + verdict taxonomy + completion gate
  (single source of truth for both skills).
- `fanout` - plan the translation fan-out (file-disjointness + risk tiers).
- `ship` - the gates this joins: PR + CI-green, subagent output contract,
  deploy-verify.
- The setup's trajectory memory (if provided) - query at planning, append at
  close-out.
- `superpowers:writing-plans` - multi-surface efforts plan the surface
  sequence there; this skill governs each surface's port.
