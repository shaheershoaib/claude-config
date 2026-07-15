# known-misses - the standing regression corpus

Every entry is a real production miss. Any edit to `parity-receipt`,
`proto-port`, or the subagent prompts must re-verify the edited method still
catches each one: walk the method against the miss step by step; if the
edited text no longer forces the catch, the edit fails. New production
misses are added HERE first, then the skill is patched - failing test
before fix (writing-skills iron law).

1. **Customer-ledger revealed-link (June 2026).** Proto: expanding a
   customer row reveals per-account rows, each a LINK into that account.
   App: flat sub-table, not linked. A reviewer SAW the expansion, tagged it
   medium, triage rolled it up into a bigger item, the leaf died, a tester
   filed it later. Caught now by: reveal-to-the-leaf enumeration (link
   targets recorded per revealed sub-element) + the no-rollup rule +
   per-leaf verdicts.

2. **M5 Return-Payment stuck at Step 1 (2026-06-23/24 wave).** Steps 2-7
   were absent; every Step-1 field looked right, so field-level checks
   passed. Caught now by: flow-driver drives Step-1 -> terminal; a step the
   proto reaches that the app cannot = MISSING for it + all downstream + a
   top-severity blocker; proto-port treats a multi-step workflow as ONE
   port unit.

3. **Seed blindness (same wave).** Surfaces shipped empty; testers opened
   "0 of 0" (or 1 row vs the proto's 12) and filed seed tickets on the
   spot. Root mechanism: translation deletes the proto's mocks and nothing
   forced their re-creation. Caught now by: `seed-gap` verdict + INCOMPLETE
   receipt on unexercisable surfaces; proto-port's seeds pass (failure
   branches + example counts + the empty state).

4. **Zero-premium invented contract (July 2026, three sibling tickets).** The
   proto mocks a per-policy status enum including "Resolved" that the real
   API can never return, and a wizard persisting fields the backend model
   doesn't store. A direct wire-up either fabricates data or silently drops
   persistence. Caught now by: proto-port's contract-extraction pass before
   FE work + CONFLICT = user decision, never an auto-pick.

5. **June-8 unconfirmed tail.** A full-app sweep cartographed ~34 surfaces
   (the repo's parity-receipts dir), but 9 (including Return/Refund) never
   received their confirm pass, and nothing flagged the run incomplete -
   the gate lived in prose. Caught now by: mechanical gate validation (a
   script confirms every leaf verdicted + evidence files exist; INCOMPLETE
   loudly) + hand enumeration demoted to stated fallback.

6. **Story-mediation (the build's original sin).** The app was built from
   stories and sweep-summaries of the proto rather than the proto code;
   every lossy intermediary shed leaves (root cause of the ~50-ticket
   wave). Caught now by: proto-port's translate-first rule - the proto CODE
   is the build's input; stories, summaries, and hand inventories never
   are. (The old "inventory is the spec, cartograph before code" rule is
   retired for the same reason: a hand inventory is an intermediary too.)

7. **Button-color sweep regression (2026-06-29, PRs #200/#201 -> reverted
   via #202).** An app-wide restyle shipped action buttons neutral/white
   (transparent outline). Structurally and behaviorally identical - same
   buttons, same handlers, same data - so no structural or behavioral
   check could flag it; the user read the look itself as a regression
   ("white button") and the sweep was reverted. Purely a VISUAL-tier miss.
   Caught now by: the visual-judge pass (design-INTENT judgment per
   captured screenshot pair - layout, hierarchy, color ROLES, never pixel
   equality; a control that keeps its data and behavior but loses its look
   is DIVERGENT with `facet: visual`) + Mode 1's look-check on the changed
   area. The gate proves the pass ran: `visual.pairs_judged` must equal
   the shot-pair count.
