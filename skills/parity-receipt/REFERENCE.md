# parity-receipt + proto-port - design rationale (2026-07-15 restructure)

Replaces the 2026-06-08 `parity-sweep` design spec and `parity-builder`
(both archived at `~/.claude/.archive/2026-07-15-parity-restructure/`).

## History that forced the restructure

- The app was originally built from **stories and sweep-summaries** of the
  prototype, not the prototype code itself. Indirection sheds leaves; the
  ~50-ticket M4/M5 wave was root-caused to story-anchored building.
- Early hand-run sweeps under-delivered: story-scoped (whole proto workflows
  never opened), shallow (recursion didn't chase Next/advance controls
  through wizard steps until the 2026-06-24 hardening), and unenforced (the
  June-8 full sweep left 9 of ~34 surfaces without their confirm pass and
  nothing flagged the run incomplete).
- The honest conclusion: **hand-run LLM sweeps are unreliable verifiers**,
  and **any intermediate representation used as a build input is lossy**.
  The 2026-06-24 hardening patched scope; the 2026-07-15 restructure changed
  the architecture.

## The architecture

- **Translate-first** (`proto-port`): the proto CODE is the build's direct
  input; stories, summaries, and hand inventories are banned as build
  inputs. The old "inventory is the spec / no code before cartography" rule
  is retired - under it, hand-cartography completeness gated build
  completeness, which was the structural weakness.
- Translation cannot carry three things, which became proto-port's explicit
  passes:
  1. **Seeds** - translation deletes the proto's mock data, and the mocks
     were half the spec (populated states, example counts, failure
     branches, and by omission the empty state).
  2. **Contract** - translation must invent the backend; the proto's
     implicit data model is extracted up front, gaps become BACKEND-GATED
     items, contradictions become user-decided CONFLICTs.
  3. **Behavior** - emergent, not textual: flows must be driven Step-1 ->
     terminal on seeded data.
- **Verification stays but changes instrument** (`parity-receipt`):
  cross-stack translation is regeneration and regeneration samples, so its
  completeness needs a check it didn't author. Enumeration is mechanized (a
  per-run crawl script over both running apps, to a fixpoint); agents do
  semantic mapping, flow-driving, and adversarial verification; the
  completion gate is validated by script and reports INCOMPLETE loudly.
- **Receipts vocabulary**: the artifact is a receipt in the receipts/gates
  sense - a checkable record that the behavior is observably there, not a
  claim that someone looked.

## Deleted from the old design

- The **proto-capture cache** (`parity/proto-cache/`, commit keying,
  dirty-tree guard): documented for a month, never built once. Docs must not
  describe phantom tooling. If crawl re-derivation ever becomes the
  bottleneck, rebuild caching from the crawl outputs (which are cheap,
  mechanical, and re-runnable - a different economics than hand
  cartography).
- The **hand-cartography pipeline** (discoverer / prototype-cartographer /
  app-diff-cartographer prompts): replaced by the crawl + machine-diff +
  mapper flow. The battle-tested pieces (assert-the-value block, reveal
  recursion to the leaf, no-rollup rule) were carried into the new
  subagents and SKILL.md.

## Testing discipline

`known-misses.md` is the standing regression corpus (6 documented
production misses). Any edit to either skill or the subagent prompts must
re-verify each entry is still caught. New misses enter the corpus first,
then the skill gets patched - failing test before fix.
