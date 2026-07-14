# graphify (the real graphifyy CLI + skill)
- `/graphify .` maps a project into `graphify-out/` (graph.json, GRAPH_REPORT.md,
  interactive graph.html) via local AST extraction - no API cost for code. The
  installed `graphify` skill handles queries; `/graphify` triggers it.
- If `graphify-out/` exists in a project, treat codebase/architecture questions
  as graphify queries FIRST (`graphify query "..."` / read GRAPH_REPORT.md)
  before grepping - this is what answers "what renders X / what else renders the
  same thing" (the wrong-surface + parallel-flow misses).
- After editing code in a session, run `graphify update .` to keep the graph
  current (AST-only, local). The graph is a hint - the live app is ground truth.

# Development pipeline (route work through skills - do not freestyle)

For any multi-step dev work, invoke the matching entry skill FIRST; each chains
its downstream skills. The user should never need to name the chain.

Slice work so each phase/PR is a MINIMUM SHIPPABLE PRODUCT - independently
mergeable, CI-green, and deployable on its own, never a partial slice that leaves
the integration branch broken. (the MSP rules - cluster = one PR, `after` orders MSPs,
waves = the schedule - live in `ship`'s MSPs section;
`writing-plans` slices net-new features into MSPs under them; the PR+CI gate
enforces the green; `fanout` computes the clusters/waves MSPs come from.)

A work-set can MIX types - each PR-cluster (MSP) goes down the pipeline matching ITS
type (feature / prototype port / bug fix / migration), and all converge on the one
shared gate (review -> PR -> CI-green -> rebase-merge -> deploy-verify).

- **Bug / ticket / tester feedback** ("fix #NN", "X commented", "run the
  loop") -> `ship`. It loads the project's fix-loop facts skill (e.g.
  a `<project>-loop` skill) and chains: systematic-debugging -> worktree fix ->
  `pre-commit` (local pre-check) -> `git-commit` -> PR + CI-green gate
  (rebase-merge to preserve authorship, never admin-bypass the required check)
  -> deploy-verify (ship step 8) -> `parity-sweep` scoped verify -> close ticket in-thread.
- **New feature (net-new design)** -> `superpowers:brainstorming` first;
  `writing-plans` if multi-step; TDD for logic; then join the same gates ->
  commit -> PR + CI-green -> deploy-verify -> verify chain.
- **Port/build a surface from an existing prototype or design source of
  truth** -> `parity-builder` (the prototype IS the spec - cartograph first;
  brainstorming is for net-new design, NOT ports). It self-finishes with a
  scoped `parity-sweep`, then joins the same gates -> commit -> PR + CI-green ->
  deploy-verify chain.
- **Large mechanical migration / sweep** (codemod, rename, API bump across many
  sites) -> scout the sites first, then `fanout` the per-site transforms
  (worktree isolation, usually cheap-tier), verify each, then join the same gates ->
  commit -> PR + CI-green -> deploy-verify.
- **Parallel multi-item builds** (2+ actionable items EXIST or ARRIVE - tickets
  sitting Open on a board, several asks in one or successive messages; the trigger
  is the items existing, NOT a pre-made decision to parallelize) -> FIRST
  enumerate the full work-set (a plain list of asks in chat IS a work-set; when
  the project has a tracker, a board-shaped ask additionally pulls its Open
  column) and run `fanout` over it, BEFORE launching any per-item pipeline; an
  item arriving MID-SESSION re-batches into the work-set and dispatches in
  parallel if disjoint - it never silently queues behind the current item:
  it returns file-disjoint = parallel vs shared-file = serial clusters + a
  per-leaf model tier (top for orchestration/review + the surfaces the PROJECT
  flags high-risk - high blast radius or subtle-if-wrong, e.g. financial/ledger,
  auth, migrations, service contracts; cheap for mechanical fully-specified
  leaves; the project supplies the markers). THEN launch the matching pipeline
  (`ship` / `parity-builder`) per item, per that plan, executing
  disjoint clusters CONCURRENTLY (parallel background agents or the Workflow
  tool's `parallel()`/`pipeline()` with worktree isolation) - sequential
  one-at-a-time execution is for coupled chains only. Tier REVIEW depth by risk
  too (high-risk -> full adversarial review; mechanical -> a diff-glance).
  Parallelism NESTS two levels: independent (dependency-ready) MSPs run in
  parallel, each shipping its OWN PR; and WITHIN each MSP its file-disjoint leaves
  fan out, converging into that ONE PR (same `fanout` rule at both levels).
  Two zones per MSP: the BUILD zone FORKS (leaf clusters, tiered - cheap for
  mechanical leaves, top for high-risk) and hands its diffs to the orchestrator at
  a CONVERGENCE point (review depth per leaf's tier); the MSP then crosses the
  shared SPINE (review -> gate -> CI-green -> merge -> deploy-verify ->
  verify-by-value), which is UNIFORMLY top-tier - tiering lives ONLY in the build
  zone, so the cheap tier never touches review, the gate, or the verification GATE-READ - though it MAY do verification LABOR (mechanical by-value reads that fan out like build leaves); the gate-read, the judgment, and any authed-UI live-drive stay orchestrator-owned and top-tier (see `fanout` VERIFY-MODE for the verify fan-out - the labor-vs-gate split AND the per-leaf verify-mode; it is work-type-agnostic, NOT prototype-only). This bounds
  the practical width (concurrency cap + dependency order).
  Parallelizability is DISCOVERED, not guaranteed: it needs file-disjointness (from
  `fanout`) AND dependency-independence (producer->consumer edges are found at
  recon/triage and DECLARED as `after` - `fanout` orders them but cannot discover
  them; it also emits a `coupling_review` of file-disjoint
  pairs that still share a signal - render an explicit parallelize-vs-serialize verdict
  on EVERY such pair before dispatch, skeptical default = serialize; declare
  `contract_group` to serialize known halves-of-one-contract outright, `after` to
  order without merging). Parallelize
  what's both; serialize the rest per the plan's `waves` (a big cluster executes
  as ORDERED WAVES - parallel within a wave, integrate between waves - never as
  one serial lump); degrade to fully-serial only when nothing qualifies. A cluster is a serialize-together group -
  an ORDERED chain when there are deps - not necessarily one MSP. Deps apply WITHIN an
  MSP too and can cross tiers: a reasoning/design leaf (Opus) decides the shared
  contract, then file-disjoint impl leaves (Sonnet) fan out against it (Workflow:
  serial `agent()` -> `parallel()`).
  Implementers never push or merge;
  gating, shipping, and verification stay with the orchestrator. The
  orchestrator's spine WAITS (CI polling, deploy polling) are the next item's
  build/review window - pipeline the spine, never idle-poll; when several PRs
  sit CI-green together, merge as a group so one deploy + one deploy-verify
  covers them (high-blast-radius merges ride alone).
- **"Is this surface/module done?"** -> `parity-sweep` (full). **Proactive
  bug hunt before testers** -> the project's module-audit skill; its lens-2
  "build the missing prototype feature" findings route to `parity-builder`,
  not a blind build.
- **Review**: own risky diff -> `/code-review` or `codex` cross-model;
  someone else's PR -> `github-pr-review`.
- **Session end** -> `session-handoff`. **Periodic** -> `design-drift`,
  `anthropic-skills:consolidate-memory`.
- **New project setup** -> create `<project>/.claude/skills/<project>-loop/`
  with the facts (copy an existing loop skill's shape), then
  `fewer-permission-prompts`.

Hard rule: never claim "fixed / green / deployed / verified" without the
corresponding step's evidence - fresh gate output, CI-green on the PR (never
admin-bypass a required check), sha-matched deploy, and a value-asserted check on
the deployed build that THE REPORTED SYMPTOM is resolved (your change being live is
NOT the same as the symptom being gone - reproduce the symptom FIRST so you have an
acceptance test to re-check; placeholder text is a FAIL; if you cannot reproduce
the symptom, DOWNGRADE the claim rather than assert a fix - see ship G0).

# MCP auth recovery (mid-session "Unauthorized")

If an MCP tool starts returning Unauthorized / auth-expired MID-SESSION (it worked
earlier), suspect a STALE TOKEN cached by the running server, NOT a real logout -
especially a LOCAL stdio server (e.g. a CLI-backed `<tool> mcp`) that reads creds from a
config/keychain at spawn. First confirm the underlying login is still valid (the
tool's own CLI `whoami`/status, or the cred file's mtime); if it is, RESPAWN the
server before asking the user to re-auth: `pgrep -fl <server>` -> kill the PID ->
re-call any tool (Claude Code relaunches stdio MCP servers on demand with fresh
creds). Only if respawn fails, or it's a REMOTE/OAuth MCP (no local process to kill),
ask the user to re-authenticate. Never run interactive `login` yourself (auth wall).
