---
name: ship
description: >-
  The work-set execution loop - the single entry point for landing a set of
  changes end to end under verification guardrails. Any task set, from any
  source: a list of asks in chat ("here are 5 things"), tracker tickets
  (Notion, Jira, GitHub issues, Linear), a plan/handoff/audit document on
  disk - single task or a batch, mixed work types, on any project shape (web
  app, API service, CLI, library). Use for "fix this ticket", "fix these",
  "address the comments on #NN", "the tester reopened X", "run the loop",
  "work the board", or any "make these changes and ship them" request.
  Project facts (repos, branches, verification target, optional ticket board,
  commit identities) come from the project's own skill/CLAUDE.md/memory - this
  skill is the project-agnostic skeleton, and it runs under the environment's
  verification-gates layer (canonical for gate definitions and the close-out
  evidence bar), which it invokes at loop entry.
---

# Ship (the work-set loop)

The standard pipeline for turning a WORK-SET - however it arrives: a list of
asks in chat, tracker tickets, a reporter's follow-up comment, a plan/handoff
document on disk - into shipped, verified, closed changes. The mechanical steps
are easy; the discipline is the point. The VERIFICATION discipline (the gates)
belongs to the environment's verification layer - this loop invokes it at entry
and runs every item under it (see "The gates" below); what this file carries is
the loop's own scheduling discipline, each rule paid for by a real miss.

**Boundary: `fanout` writes the schedule; ship runs the job.** The planner is a
deterministic tool this loop CALLS at step 0 (clusters/waves/tiers in seconds);
everything that acts - dispatching agents, worktrees, gates, PRs, merges,
verification, close-outs - happens HERE, orchestrator-owned.

**Vocabulary (used throughout):** a WORK-ITEM is one actionable ask, whatever
its source (a ticket, a chat ask, a document line-item). The REPORTER is
whoever's experience defines done for an item: the ticket filer, the user in
chat, the document's author - for a mechanical sweep, the pattern spec itself.
A CLUSTER is a set of items that MUST serialize (shared edited files or one
declared contract - `fanout` computes it). An MSP (minimum shippable
product) is the unit that ships as ONE PR - see "MSPs" below. A LEAF is one
dispatched unit of build work inside an MSP. WAVES are the execution schedule:
everything in a wave runs concurrently; integrate between waves.

**Project facts live elsewhere.** Before running, load the project's facts from
(in order): a project-level skill (e.g. `<project>/.claude/skills/*`), the
project CLAUDE.md, and auto-memory. You need: repo paths + integration
branches, gate commands, commit identity rules, the VERIFICATION TARGET, and -
IF the project has one - the tracker layer (ticket board + status taxonomy).
Two of these are project-SHAPED, never assumptions:
- **The tracker is an EXTENSION, not a requirement**: with no board, tasks
  arrive as text and close out as an evidence-cited report instead of a ticket
  move.
- **The VERIFICATION TARGET is whatever artifact a real user runs**, and every
  "deployed build" in this skill means THAT target: a deployed web build
  (staging URL, browser drive), a released/installed package (build/install
  the artifact FROM the merged sha, run the command), or a service endpoint
  (staging API call). A CLI/library with no deploy is NOT exempt - its target
  is the built artifact at the merged sha; only the observation tool changes
  (run the command / call the endpoint instead of driving a browser).
If a needed fact is missing, ask - do not guess. **Bootstrapping a new project?** Copy
`references/project-facts-template.md` (in this skill's directory) to
`<project>/.claude/skills/<project>-loop/SKILL.md` and fill in the
placeholders - it carries the section skeleton this loop expects, including
the terminal-action and twin-surface hooks.

---

## The gates (the verification layer is canonical - honor ALL of it)

Gate definitions, the receipt + close-out evidence bar, the downgrade statuses,
the referees/tripwires, and the per-medium "what counts as the value" mapping
are NOT this skill's to define. They live in the environment's bootstrapped
verification layer (a gates skill + close-out hooks + a per-project config + a
trajectory store), and that layer is canonical wherever the two could overlap.
This loop deliberately does NOT restate its spec: a partial restatement here
would SHADOW the full set - an agent reading six gates concludes those are the
gates, and the ones the prose never names silently stop being honored.

Make the deferral ACTIVE, not assumed:
- **At loop entry, INVOKE the environment's gates skill** (via the Skill tool)
  so the FULL gate set is in context - not a remembered subset. The layer
  covers more than the obvious verify checks (reproduce / assert-the-value /
  right-build / right-surface / terminal-action / twins): dependents,
  fresh-base, rollout compatibility, referee integrity, and diff congruence
  live there too.
- **Steps 8-10 EXECUTE that layer's spec** - the machine-checkable evidence on
  the deployed target, the close-out statuses, the referee's floor. They never
  redefine it.
- **A gate you cannot clear exits through the layer's honesty ladder** - an
  honest downgraded status, never a silent "fixed", never relabeling one
  downgrade as a milder one, and never out-arguing a referee that fires: do
  the verify or take the honest downgrade.
- **No verification layer in this environment?** The bar binds by norms anyway -
  hold it harder, not softer (no referee is exactly when quiet skips creep
  back) - and flag the missing layer to the user as setup debt.

What the LOOP itself owns is scheduling, not spec - three disciplines its steps
depend on:
- **Pin the before-state and PRE-REGISTER the acceptance line at step 2**,
  before any code: observe the reporter's surface as-is (reproduce the
  symptom; for additive work capture the surface WITHOUT the change; a
  mechanical sweep's before-state is its site census) and write the exact
  observable-that-must-change into the work-set notes ("Acceptance: clicking
  Generate advances to Step 4"). No acceptance line -> not allowed to build.
  Step 9 re-runs that exact line - this is what makes the end-check mechanical
  instead of "looks right".
- **An ask that stays SUBJECTIVE after one clarifying question is DESIGN, not
  a fix** ("improve X", "make it feel better"): route it to
  `superpowers:brainstorming` with the observations you gathered (step 0's
  typing rule). Never enter the build path with an unpinnable acceptance line.
- **A code-inference about a surface you could not observe is a HYPOTHESIS.**
  At diagnosis time state it as one, cross-check the authoritative definition
  (the enum/type/schema/contract - or, for a render or progression symptom,
  the LIVE build itself: drive the reporter's exact click before writing the
  fix), and treat a refuting gate (tsc, a failing test) as re-opening the
  diagnosis, not a nuisance. A ticket's stated cause - especially one YOU
  authored earlier from inference - is also a hypothesis to re-test, never a
  fact.

---

## The loop

0. **Enumerate the WORK-SET before starting any item (the step that was
   missing - serial-by-default died here).** The work-set is what EXISTS, not
   just what the message cited:
   - The loop's INPUT is a set of tasks, however they arrive. A plain list of
     asks in chat is the primary, first-class form - each ask is a work-item,
     no tracker needed; the loop runs end to end on text input alone. A
     plan/handoff/audit DOCUMENT on disk is the same thing in a file: its
     line-items/findings are the work-items and its author is their reporter -
     enumerate it like a message. Collect every actionable ask from the
     message(s)/document first. THEN, only when the project HAS a tracker layer
     (a project skill naming a board/queue - that layer is a project EXTENSION
     of this loop, not an assumption of it): a board-shaped ask ("run the
     loop", "work the board", "new items") expands the work-set with the
     board's FULL Open/reopened column, and multiple tickets sitting Open ARE
     the work-set even if the user named only one.
   - **TYPE each item; non-fix shapes ROUTE, but everything stays in ONE
     plan.** Fixes/regressions and small fully-specifiable additions run this
     loop natively (the before-state pin picks the matching form). An item that needs real DESIGN
     (its shape is undecided) goes to `superpowers:brainstorming` /
     `superpowers:writing-plans` FIRST, and its output - specified items, an
     MSP-sliced plan - re-enters THIS work-set as items. A prototype/design
     -source port is a `proto-port` MSP. A mechanical many-site sweep runs
     natively, sweep-shaped (census first - the census IS the before-state pin). Routing changes WHO
     designs/builds an item, never the plan or the gates: every item, routed or
     native, appears in the same `fanout` items JSON (a design item is a
     wave-0 producer; its impl items declare `after` it) and crosses the same
     spine.
   - **2+ actionable items -> `fanout` is the MANDATORY next step, before
     any per-item work** (see Batching). Prep is itself a fan-out: refresh the
     graph NOW (`graphify update .` per touched repo - GitHub-side merges never
     fire the local post-commit rebuild, so the graph is otherwise weeks stale)
     and scaffold the items JSON with one cheap recon agent per work-item
     predicting its edited files + surfacing producer->consumer edges to
     declare as `after` - never hand-decompose (recorded failure: a hand split
     missed a shared test file and two same-file leaves collided). No graph?
     Build it now (`graphify .`) when the stack supports it; otherwise run
     fanout WITHOUT `--graph` - only the import-adjacency signal is lost.
     A missing graph is never a reason to skip the planner.
   - Exactly 1 item: proceed to step 1 - but the re-batch rule below stays armed
     for the whole session.
   - **RE-BATCH ON ARRIVAL (the standing rule):** a new ask or ticket landing
     mid-session JOINS the work-set immediately - triage it, re-run
     `fanout` over remaining+new, and if it is disjoint from in-flight
     work, dispatch its build in parallel NOW. Never queue it silently behind
     the current item's close-out; "I'll finish this first" is the serial trap.
     Your spine waits (CI polling, deploy polling) are exactly when the new
     item's build should be running.
1. **Triage the task AND everything attached to it.** For a tracker ticket
   that means the ticket AND every comment; for a text-input task the chat
   thread IS the ticket - triage the ask plus every prior correction or
   follow-up the user gave on it. A closed-pending ticket with a fresh
   reporter comment is REOPENED - comments are new requirements, not
   chatter. Separate: (a) actionable, (b) already-answered, (c) blocked on
   input you genuinely cannot recover (note: if a prototype/design source
   exists in the repo, extract the spec from it YOURSELF before declaring
   anything blocked - "needs a screenshot" is rarely true when the prototype
   code is on disk).
   **If triage GROWS the work-set past one actionable item (comments spawned
   new asks), step 0's rule applies NOW: run `fanout` before touching any
   fix, THEN run the per-item steps below per that plan.**
2. **Pin the flow.** If the project has a graphify graph
   (`graphify-out/` exists - see `graphify`), query it FIRST to find which
   component renders the reporter's surface and whether parallel
   implementations of the feature exist (`graphify query "what renders
   <surface>"`, or read `graphify-out/GRAPH_REPORT.md`). **Also query the
   trajectory memory FIRST** (if the setup provides one - see "Cross-loop
   memory" below): what was already tried on this surface and what failed - a
   prior recorded failure ("capped height - wrong axis") is the wrong-axis /
   wrong-surface trap pre-recorded,
   surfaced before you spend a build on it. graphify answers "what renders X"
   (structure); the trajectory memory answers "what did we try on X and what
   happened" (history). Then identify the
   exact component/route, pin the BEFORE-STATE live (reproduce the symptom,
   or capture the surface without the change), and **PRE-REGISTER the
   acceptance line** - write the exact observable-that-must-change into the
   ticket / work-set notes ("Acceptance: clicking Generate advances to Step
   4"). No acceptance line recorded -> not allowed to build; step 9 re-runs
   this exact line (graph = hint, live app = truth).
3. **Isolated worktree.** `git worktree add -b <branch> <path> <integration>`;
   symlink untracked deps the build needs (node_modules, .env files, venvs).
   Keep work off the integration branch until gated. (A solo LITE-lane item may
   use a plain branch instead - see Proportionality; a batch always worktrees.)
4. **Implement.** For a non-trivial bug, run `superpowers:systematic-debugging`
   first - its Iron Law (no fix without root-cause investigation) is the one
   discipline the gates do NOT cover: the before-state pin already reproduced the
   symptom for the acceptance test, so REUSE that as its Phase 1 (don't reproduce twice) and spend
   the effort on WHY - fix the cause, not the symptom. Recurring traps worth checking
   explicitly:
   - `'' ?? fallback === ''` but `'' || fallback === fallback` - empty-string
     defaults need `||`.
   - A form that errors with "required information" while every visible field
     is filled has a HIDDEN required field being stamped empty.
   - Prefer controlled inputs over uncontrolled defaultValues (the render gap).
   - Two-sources-of-truth divergence (the terminal-action seam): any value that enters a
     form WITHOUT a change event - seed, default, async hydration - must be
     explicitly synced to the shared store the final validator reads. When
     adding a seed/prefill, grep for the store's readers (final validation,
     submit payload) and add a test that runs the REAL final validator against
     the store as a user would leave it (defaults accepted, nothing re-typed).
   - Add a pure-logic unit test for any mapping/seeding/formatting helper.
5. **Gate** - run the `pre-commit` skill: the project's REAL commands
   (typecheck, lint, tests, plus any custom gates like ASCII-only diffs), all
   green before commit. Never claim green without running them
   (`superpowers:verification-before-completion`).
6. **Commit** - via the `git-commit` skill, honoring the project's per-repo
   commit identity + required trailers (never edit git config).
7. **Open a PR and merge only on green CI** (replaces any direct-push that
   admin-bypasses a required check; CI is the authoritative gate). Push the
   branch, open a PR against the integration branch, poll the required check to
   green (deploy-verify-style - do not hammer), then merge with a method that
   PRESERVES THE COMMIT AUTHOR where the deploy platform author-gates the HEAD
   (e.g. rebase-and-merge). NEVER merge red and NEVER admin-bypass the required
   check; on red, read the logs, fix on the branch, re-push. The local
   `pre-commit` gate stays as a fast pre-check. (Project facts - branch names, the
   required check's name, the merge method, the author-gate - come from the
   project skill.)
8. **Ship to the verification target + confirm it carries your sha** (the
   deploy-verify step). Web app: poll the platform's deployment status until it
   is READY **and** reports your merged sha. Deploys take time (roughly a
   minute to several), so background-wait and re-check instead of hammering -
   and never start verifying on hope: a green look at the PREVIOUS build proves
   nothing, and an evidence capture made before the new build is live binds
   your observation to the WRONG sha. The project skill names the platform, the
   exact alias/endpoint to poll, and the typical build time. CLI/library/
   service with no auto-deploy: build/install the artifact FROM the merged
   integration sha (fresh venv/install, never your worktree) - that artifact IS
   the "deployed build" the next step verifies.
9. **Verify by value on the target**, driving the reporter's exact
   flow, then the flow's terminal action and the changed pattern's twins.
   Re-run the step-2 acceptance line verbatim, and **capture the evidence
   artifacts the gates layer requires as you verify - required, not a
   nicety** (its machine-checkable live evidence bound to the deployed sha;
   any wired close-out referee checks for them; per-medium artifact shapes
   are the layer's spec - e.g. a UI item is typically a screenshot PLUS a
   by-value DOM read, because a screenshot alone can show a grey placeholder
   and pass the eye). If you cannot re-check the acceptance line, say so - do
   not assert "fixed". When UI-driving the repro is fragile or slow, construct
   the reporter's state via the app's own API and assert persisted state by
   value - a legitimate repro, often 10x faster.
10. **Close out**: move the ticket to the project's "fixed, pending retest"
    status with concise resolution notes (what changed + that it was
    browser-verified). No tracker (the task arrived as text)? Same close-out,
    different medium: report to the user per task with the SAME observed-value
    evidence - the gates layer's evidence bar and the trajectory
    append below apply identically. **The note MUST cite the OBSERVED VALUE, never the bare
    word "fixed" / "verified":** "verified live on the deployed build: the
    Resolved tile shows 3" or "by-value staging query returns resolved_count =
    3" - that observed value is the artifact the gate, the reporter, and the
    next retest all read; a note that says only "browser-verified" has not
    earned the claim. Then reply **in the reporter's comment thread**
    addressing each ask point by point. Net-new deliverables get their own
    ticket so they are tracked for retest - and so does any net-new BUG
    discovered while verifying: file/flag it, never scope-creep the current
    fix or silently drop it (no tracker? list it as a FLAGGED item in the
    close-out report for the user's disposition - same rule, different
    medium). **Then record the trajectory, if the setup provides a trajectory
    memory** - the touchpoints live in "Cross-loop memory" below. Record the
    outcome exactly as shipped (verified / downgraded / reverted / blocked),
    failures and blocked exits recorded too; the
    only exit that skips the append is a loop genuinely paused mid-flight.
11. **Clean up**: remove the worktree, delete the branch. If the project has a
    graphify graph and you changed code, run `graphify update .` to keep it
    current (AST-only, local, no API cost).
12. **Ratchet the project facts.** If this run taught you a durable mechanic -
    a state-construction shortcut (how to build a repro via the app's API), a
    twin-surface pair, a push/identity quirk, a browser-driving workaround, a
    flaky-looking-but-real gate behavior - write it into the PROJECT skill
    before ending, in the matching section. Auto-memory is for session state;
    mechanics that any future loop run needs belong in the skill, or every
    session re-learns them by trial and error (proof: an entire session's
    worth of click-scaling, push-mechanics, and repro-recipe discoveries sat
    only in memory until a manual audit moved them). One paragraph per fact,
    same style as the section it joins.

## Proportionality: the lane scales, the gates do not

Full ceremony on a one-line copy fix trains everyone to route AROUND the skill -
the worst outcome. The LITE LANE applies only when ALL hold: a single item; no
logic / contract / data-shape change (copy, a label, a comment, a style token,
docs); <= ~5 lines across 1-2 files; no high-risk-marker surface. When in
doubt -> standard lane.
- **LITE KEEPS (non-negotiable):** a branch + PR + CI-green (shared policy,
  never bypassed), the before-state pin + a one-sentence acceptance line,
  ONE by-value check on the verification target, the twin grep (labels and
  typos have twins), and an evidence-cited close-out.
- **LITE WAIVES:** fanout (it is a single item), recon scaffolding, the
  graphify/trajectory queries (a grep suffices), the isolated worktree when
  working SOLO (a branch on the main checkout is fine; a batch ALWAYS
  worktrees), systematic-debugging, the screenshot+DOM dual artifact (one
  observation suffices), the trajectory append (unless something SURPRISING
  happened - surprises always append), and the step-12 ratchet.
- **ANTI-STRETCH:** the lane is for changes whose entire diff a reviewer
  absorbs in one glance. The moment a lite item grows (a second concern, a
  conditional, a data shape), it upgrades to the standard lane MID-FLIGHT.
  Lane creep is how bypass starts.

## MSPs: how a work-set becomes PRs

An MSP (minimum shippable product) is the smallest INDEPENDENTLY-MERGEABLE
unit: CI-green on its own, deployable on its own, revertable on its own.
**The MSP is the PR: one MSP = one branch = one PR**, and MSPs are what run in
parallel. The mapping from a `fanout` output is mechanical:

- **Each serialize-together CLUSTER = one MSP.** Single-item clusters are the
  common case (one item, one PR). Items forced together by a shared file or a
  `contract_group` ship as ONE PR - their leaves build inside it and converge;
  never hold two open PRs that edit the same file.
- **`after` edges order MSPs without merging them.** A consumer MSP starts
  building when its producer INTEGRATES (merges) - or, when pipelining harder,
  branches off the producer's branch and rebases on its merge (state the risk).
  Two consumers of one producer stay parallel with each other.
- **The global `waves` ARE the MSP schedule:** wave N's MSPs build and ship
  concurrently; integrate between waves.
- **Too big for one PR?** A cluster whose diff a reviewer cannot hold (rule of
  thumb: > ~800 changed lines, or it crosses a high-risk boundary mid-way)
  splits at wave boundaries into STACKED MSPs - ordered PRs, each CI-green,
  each independently shippable; never a partial slice that leaves the
  integration branch broken.
- **Design-first items:** the design leaf (`brainstorming`/`writing-plans`
  output) is a wave-0 producer; its impl items declare `after` it.
  `writing-plans` slices a big feature INTO MSPs under these same rules.
- **Degenerate case:** a one-item work-set is one MSP - no planner run needed;
  the loop above IS that MSP's spine.

Two-level parallelism, explicitly: MSPs run in parallel, each shipping its OWN
PR; WITHIN an MSP, its file-disjoint leaves fan out and CONVERGE into that one
PR. Tiering lives in the build zone only; every MSP crosses the same spine
(review -> gate -> CI-green -> merge -> target-verify -> close), which stays
orchestrator-owned and top-tier.

## Batching a work-set (fan-out)

When one loop run covers 2+ actionable work-items, the FAN-OUT PLAN comes
first: run the `fanout` skill BEFORE dispatching any per-item agent - it
decides what parallelizes, in what order (`waves`), and on which model tier;
the MSPs section above maps its output to branches/PRs. Then execute: one
background build agent per MSP (leaves within a big MSP fan out too), each in
its OWN worktree (step 3) on its assigned tier, while you do the
trust-boundary work yourself - review each diff, re-run the gates fresh,
commit/push, merge, confirm each deploy/artifact. Verification is per-item in
SCOPE (the by-value, right-surface, and terminal-action checks are never
batched away) but PIPELINED in TIME - an item
verifies the moment ITS target is live, never saved for a serial end-sweep.
Items sharing files are ONE MSP in one worktree. Never let agents push, merge,
or close items themselves - implementation parallelizes; gating, shipping, and
verification judgment do not. Dispatch mechanics: use the Workflow tool
(`parallel()`/`pipeline()`, worktree isolation - skill-directed use is
authorized) when the batch shape is known up front - the script survives a long
session; use ad-hoc background agents when items trickle in or need
conversational steering. Either way, EXECUTE disjoint work CONCURRENTLY - the
speed win is real only if you actually fan out.

**Plan from file-disjointness + declared dependencies, never by feel.** Feed
`fanout` the work-items with their recon-predicted files, `after` edges,
and the project's risk-markers; consume its `clusters`/`waves`/`tier` per its
own skill doc (canonical for the tool's semantics). Two consumption rules are
non-negotiable: render an explicit parallelize-vs-serialize verdict on EVERY
`coupling_review` pair before dispatch (skeptical default = serialize), and
declare `contract_group` / `after` rather than eyeballing coupling - repo
-disjoint is NOT dependency-independent (a BE producer and its FE consumers
look parallel to a file view). File-level disjointness of the EDITED files is
the merge-safety unit - not symbol-level, not transitive import-coupling.

**Pipeline the SPINE - the orchestrator's wait states are the batch's schedule.**
The serial spine (review -> PR -> CI-green -> merge -> target-verify -> verify ->
close) is per-MSP and orchestrator-owned, and its waits dominate a batch's
wall-clock: a CI run is 10-20 minutes and a deploy poll is minutes, PER MSP.
Never sit idle in a spine wait: while MSP A's CI runs or its deploy builds,
dispatch/review MSP B's build, scaffold the next wave's items, or do the next
diff review - polling is a background activity, not a foreground task. And BATCH
the merges: when several PRs are CI-green together, merge them as a group so they
ride ONE deploy -> ONE deploy-verify sha-confirm -> per-item by-value checks
(by-value/right-surface/terminal-action checks stay per-item; the
deploy-confirm is per-DEPLOY). Exception: a
high-blast-radius change (money/ledger, auth, destructive migration) merges ALONE
so a revert stays clean - the orchestrator calls it.

**Tier the model by RISK, not role** (mechanics in `fanout`, canonical).
The orchestrator and every leaf touching a project-flagged HIGH-RISK surface
stay top-tier; only mechanical, fully-specified leaves with no high-risk
surface drop to a cheap model (in a Workflow: `agent(prompt, {model:'<cheap>'})`
for those, omit the override otherwise). Tier REVIEW depth the same way:
high-risk leaves get a full adversarial review, mechanical leaves an
orchestrator diff-glance - review rigor matches blast radius so review overhead
never exceeds the tiering saving.

**Batch the orchestrator's own labor - it is the real width ceiling.** Waits
are pipelined (above), but your ACTIVE serial work scales with fan-out width
too: review diffs in CONVERGENCE GROUPS as waves complete (not in arrival
order, one by one); write close-outs in a batch after each group-merge;
append trajectories at natural pause points (each entry still per-item). The
per-item gate-read stays per-item, but it is ONE cheap read each. Practical
batch width = what you can review and close without becoming the queue - when
the review backlog grows faster than builds land, stop dispatching and drain.

**Subagent output contract.** Every dispatched agent's final message is
injected into YOUR context verbatim - across a 10-agent fan-out, verbose
prose returns are the difference between finishing and compacting. Demand
contract-shaped returns in the dispatch prompt: one line per finding/change
as `file:line - claim - evidence`, a closing `totals:` count line, no prose
preamble or recap. Two hard rules: (1) evidence is never compressed away - a
bare verdict ("no issues", "done") without the supporting line/quote/output
fails verification and gets re-run; (2) the contract is for agent-to-you
returns ONLY - anything a human reads (ticket replies, commit bodies,
summaries to the user) stays full prose.

**Parallelize the verification LABOR** (the full rule set - the labor-vs-gate
split, the authed-UI single-session rule, per-leaf verify-modes - lives in
`fanout` VERIFY-MODE, canonical; note it is doctrine read off the
project's markers at consume time, NOT a computed plan field). The two moves:
PIPELINE build->verify (Workflow `pipeline(items, build, verify)`, no barrier)
so an item verifies the moment ITS target is live; and FAN OUT by-value / DATA
verification to a verifier-agent pool (cheap tier, session-less reads
returning `{item, observed_value, sha, pass, evidence}`). What never fans out:
the gate-satisfying observation + judgment (any wired Stop referee reads YOUR
transcript, not a subagent's - do the ONE cheap confirming read yourself and
cite the value) and
the authed deployed-UI live-drive (a single authenticated session). This shape
is work-type-agnostic - net-new builds and ports verify the same way.

## Cross-loop memory (optional)

If the setup provides a trajectory-memory store (an MCP/plugin recording
per-surface work history - ideally global, repo-tagged, and append-only, so a
trap recorded on one project warns the next), wire it into two touchpoints:

- **Read at the start (step 2, with graphify):** query the surface before
  building. graphify tells you what renders the surface; the trajectory memory
  tells you what was already tried on it and what failed. A past recorded
  failure is the wrong-surface / wrong-axis miss pre-recorded - the cheapest
  possible way to not repeat it.
- **Write at every loop EXIT (step 10), not just a clean close - after the
  by-value verify when there is one; the only exit that skips it is a loop
  genuinely paused mid-flight (not yet exited):** append the surface, the
  symptom, the root cause, what worked, what failed, and the outcome exactly
  as shipped (verified / downgraded / reverted / blocked), so the store
  doubles as a queryable history of which fixes shipped verified vs downgraded
  vs blocked, per surface. **Record the FAILURES, not just the wins:** a
  downgraded, reverted, or blocked exit (you could not verify and handed the
  ticket back) is the entry most worth keeping - it is what stops the next
  loop repeating the wall; a success-only store is survivorship bias. Include
  a canonical surface key (the primary file / component id) so the same
  surface GROUPS across loops - free-text surface names are almost never
  written identically twice - plus the edited files and any twin surface the
  fix regressed: these feed `fanout`'s history-aware tiering and its
  `regression-history` coupling signal, so a surface with a bad track record
  auto-bumps to the top tier the next time it is planned.

The store's exact tool names, fields, and outcome taxonomy come from the
plugin/config layer that provides it. It does NOT replace the step-12 ratchet
(durable MECHANICS still go into the project skill) or auto-memory (session
state) - it is the per-incident "what we tried on this surface and how it
turned out" layer, the thing previously locked in a closed ticket nobody
re-reads.

## Failure modes (red flags - STOP)

| Rationalization | Reality |
|---|---|
| "CI is green / the test passes / it deployed - close it" | Verification claims are the gates layer's to grade: its skill is loaded (loop entry), its evidence bar applies, and its honesty ladder is the only alternate exit. Never out-argue the referee. |
| "Automation can't reach it, so downgrade" | Exhaust the observation tools first (the user's LIVE authed session via the browser MCP, then Playwright/DevTools/preview). A surface behind a visible button is observable; the honesty ladder is a last resort, not a first one. |
| "This needs the reporter's screenshot" | If a prototype/design source is on disk, extract the spec yourself first. |
| "I'll reply on the ticket page" | Reply in the reporter's THREAD or they won't see it in context. |
| "Auth wall - I'll log in" | Never enter credentials/OTP. Pause and ask the user to re-auth. |
| "I'll just push direct, the bypass notice is normal" | A required check that never blocks is a single point of failure. Open a PR; merge on green (author-preserving). |
| "Starting fresh on this surface" | Maybe not - check the trajectory memory (if wired) first; a past recorded failure is the wrong-surface trap already paid for once. |
| "I'll finish this ticket first, then look at the new ask" | Re-batch (step 0): the new item joins the work-set NOW; your CI/deploy waits are exactly when its build should run. Queueing it is the serial trap. |
| "The board has other Open tickets, but I was only asked about this one" | Board-shaped ask -> the full Open column IS the work-set (step 0). One-at-a-time drains a board at ~1 spine per ticket. |
| "One big cluster - it all serializes" | Read `waves`: a real 92-item work-set runs 25-wide in wave 1. Only clique tails (N items editing ONE file) are one-at-a-time. |
| "CI is running, I'll wait for it" | Polling is background work. Foreground = the next MSP's build/review (Pipeline the SPINE). |
| "It's additive - nothing to reproduce, so the pin doesn't apply" | The pin's second form: capture the surface WITHOUT the change (the before-state) + pre-register the NEW observable. No acceptance line -> not allowed to build. |
| "No deploy on this project, so steps 8-9 don't apply" | The verification target is the built artifact at the merged sha (fresh install, run it, assert output by value). A CLI/library is never exempt. |
| "It's basically trivial" (it touches logic) | The lite lane is copy/docs/token-sized only, and it KEEPS PR+CI+the by-value check. Lane creep is how bypass starts (Proportionality). |
| "These two are in different repos, so they're parallel" | Repo-disjoint is not dependency-independent. Declare the `after` edge (BE producer -> FE consumers) and let waves order them. |

## Related skills
- `parity-receipt` - value-assertion methodology in depth + scoped mode.
- `proto-port` - prototype/design-source ports (translate-first): it owns
  those MSPs; they still join this loop's plan and spine (step 0 typing rule).
- `superpowers:brainstorming` / `superpowers:writing-plans` - design-shaped
  items route there first; their output re-enters the work-set as specified
  items / an MSP-sliced plan (step 0 typing rule).
- `fanout` - clusters/waves/tiers + `after` dependency ordering; the MSPs
  section above maps its output to PRs.
- The environment's verification-gates + trajectory-memory layer (a
  bootstrapped plugin/config, when present) - canonical for gate definitions,
  close-out statuses, referees, and cross-loop history.
- `pre-commit` - project-real gates. `git-commit` - identity-aware commits.
- `superpowers:systematic-debugging`, `superpowers:verification-before-completion`.
- The project-level skill supplies all concrete facts (boards, repos, URLs).
