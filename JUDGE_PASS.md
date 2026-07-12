# Judge pass — site_quality_control MES build

**Method disclosure, upfront:** the `/judge` skill wants a sub-agent with isolated context via a Task tool. That tool doesn't exist in this environment. This is the same model that wrote the build evaluating it in the same context window — it cannot fully escape the confirmation bias that isolation exists to prevent. What follows is disciplined by evidence citation (every score points at a specific file/line, not a vibe) rather than by independence, because independence isn't available here. Treat this as a structured self-check, not a second opinion.

## Rubric

### 1. Instruction Following — Partial
- Ignition 8.3, Postgres (recommended + reasoned, not silently assumed), scope (alarms + historian + RBAC, OEE excluded) — all honored, traceable to your 3 answers.
- `/judge`: see method disclosure above — can't fully deliver what was asked, disclosed rather than silently substituted.
- `/learn`: reinterpreted as "explain the why inline," not Socratic dialogue — the skill's own trigger list excludes task requests, flagged at the time rather than silently ignored or silently complied with literally.
- Reference materials: both ZIPs actually extracted and read, not just acknowledged — the Vision/Perspective module mismatch on the popup example was caught and reasoned through rather than glossed over; the table CSS mechanism was directly reused, not reinvented.
- Company theme: logo color extracted programmatically (§ below), not eyeballed.

### 2. Output Completeness — Partial, gaps disclosed rather than hidden
**Built and internally verified:** DB schema (6 tables), 5 UDTs + 5 instances + 3 alarms, 11 Named Queries, 1 shared script library, 1 timer script, 9 Perspective views, 1 reusable popup, page routing, session props, brand theme CSS + deployment doc.

**Explicitly NOT built, stated plainly:**
- Font files (`poppins-*.woff2`) — referenced by the CSS, don't exist; my sandbox can't reach `fonts.gstatic.com`. Disclosed in `DEPLOYMENT.md`, not silently assumed present.
- Alarm pipeline routing (tag alarm → `alarm_journal` row) — the two ends exist, the middle is a Designer GUI step I gave instructions for rather than fabricated JSON for (no ground-truth schema).
- RBAC/IdP resource — same treatment, guide not fabricated JSON.
- QA read-only enforcement — flagged as a genuine open gap in `RBAC_CONFIGURATION_GUIDE.md`, not fixed, because which of two fixes is right is a judgment call that's yours to make, not mine to guess.
- Shift-selection UI — `session.custom.activeShift` is read by every submit script but nothing lets an operator set it; it silently stays at the "DAY" default. **This should have been caught earlier and wasn't until this judge pass** — noting it here rather than quietly patching it into the final zip without telling you, since a real second reviewer would flag it as a gap to decide on, not something I should unilaterally resolve.
- Phase 8/9 (FAT/SAT harness, 3am diagnostics playbook) — not requested this round, not built, mentioning so "complete" doesn't quietly expand to cover them.

### 3. Solution Quality — evidence for and against

**For:** the DRY architecture claim is checked, not asserted — `generate_named_queries.py` and `generate_stage_views.py` are real generators, re-run from source, not hand-copied per file. Tag/view cross-reference was verified programmatically after generation (once with a bug in my own checker, caught and fixed before trusting the result — shown in chat, not edited out).

**Against — the one that matters most:** the `stagePosition` bug (dead variable, never reached the query, would have 100%-failed dryer infeed/outfeed submission) was caught in this judge pass, not before. That means the verification discipline applied to the *first* build (audit turn) wasn't automatically applied with the same rigor to *this* build until explicitly forced by writing this section. That's a real process gap, not a one-off — worth naming rather than letting the fix speak for itself and moving on.

**Also against:** several pieces rest on moderate-confidence, not verified-against-ground-truth, patterns — UDT inheritance JSON shape, `style.classes` prop nesting, `ia.input.link`/`targetURL`, `hasRole()` exact signature, `session.props.auth.user.userName` path, Gateway timer script `resource.json` shape. None of these had a real example to check against (unlike `view.json`/Named-Query `resource.json`, which were validated against your actual project). Flagged individually as they came up — collecting them here so they're visible as a set, since six moderate-confidence assumptions clustered in the tag/security layer is a meaningfully different risk profile than one or two scattered through 41 files.

### 4. Reasoning Quality — Good, with one honest limit
Steelmanned SQL Server before recommending Postgres, with a quantified reason (existing query's own `LIMIT` syntax) rather than a preference. Caught my own `GREATEST`/`LEAST` portability bug against the project's own stated engine target. Made the brand-color-vs-alarm-color separation explicit with a stated safety reason, not just "looks nicer." The limit: none of this reasoning was pressure-tested by anything other than me re-reading my own output — same-context ceiling again.

### 5. Response Coherence — Good
Delta-traceable against the prior turn's audit report; file organization matches the architect skill's canonical layout; theme mechanism traced to a real example rather than asserted from memory.

## Net
Ship-able for a controlled FAT, not for the floor unfiltered. The `stagePosition` catch is the concrete argument for running this section at all rather than skipping straight to a summary — it changes the answer to "does this work," not just the polish.
