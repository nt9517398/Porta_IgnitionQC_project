# Alarm pipeline configuration guide

Same disclosure as the RBAC guide: I have no ground-truth example of Ignition's alarm-pipeline resource JSON in this conversation, so this is Designer GUI steps, not a file I generated and am asking you to trust blindly.

## What already exists in this build
- 3 tag-level alarms (`LatheThicknessOutOfSpec`, `DryerMoistureOutOfSpec`, `FinishedPanelMoistureOutOfSpec`) — defined directly on the relevant tags in `tags.json`, these import as normal tag configuration and will show up in Designer's Alarm Status table the moment a `Pending/*` value crosses its configured tolerance. This part needs nothing further from you to function at a basic level.
- `qc.alarm_journal` table + the `qc/alarms/insert_journal_entry` and `qc/alarms/journal_history` Named Queries — the DB-side half of "store alarm history in the database, not just the Gateway's internal store" per your own architect skill's alarm reference.
- The `alarm_status` view + `alarm_ack_popup` — the UI-side half, reading from the journal and writing acknowledgments back to it.

## What's NOT wired yet: the middle piece
Nothing currently calls `qc/alarms/insert_journal_entry` when a tag alarm actually fires. That connection — tag alarm activates → row appears in `qc.alarm_journal` — is exactly what an Ignition **Alarm Pipeline** is for, and it's configured in Designer, not hand-authored as JSON:

1. Designer → Alarming → Pipelines → new pipeline, e.g. `QC_Journal_And_Notify`.
2. **On Active** block → **Script** step → call `system.db.runNamedQuery("site_quality_control", "qc/alarms/insert_journal_entry", {...})`, populating `sourcePath`/`displayPath`/`priority` from the pipeline's built-in alarm-event bindings, `state: "Active"`.
3. (Optional, matches your alarms-and-pipelines.md reference's escalation table) **On Active, delayed by priority** → **Email** step → notify the Supervisor distribution list for Medium+, matching the response-time table in that reference (Medium: 10 min/operator ack; High: 2 min/supervisor notify).
4. Assign this pipeline to the 3 alarms in `tags.json` under each alarm's Notification tab, or set it as the project-wide default pipeline for the `Medium` priority class if you want every future alarm to inherit it without per-alarm assignment.
5. Point an **Alarm Journal profile** (Gateway → Config → Alarming → Journal) at the same Postgres connection if you want Ignition's own built-in alarm history view to agree with `qc.alarm_journal` — otherwise the two are independent stores of overlapping-but-not-identical data, which is fine but worth knowing rather than assuming they're the same thing.

I can draft the exact script-step Python for step 2 right now if useful — it's a 6-line call using the same `system.db.runNamedQuery` pattern already used everywhere else in this build, I just can't package the pipeline's own container/routing JSON without a ground-truth shape to check it against.
