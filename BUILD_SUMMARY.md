Version: 1.0
Date: 2026-07-10
Delta Summary: Greenfield rebuild of site_quality_control as a full MES platform,
using the remediated project as the confirmed data model rather than extending
its file structure directly (per explicit authorization to build fresh).
Confidence Shifts: DB schema, tag/UDT layer, alarm wiring, and RBAC did not
exist in any form in the prior project (H-001/H-002 in the last audit were
literally "this doesn't exist to check") — moved from [SPEC UNKNOWN] to
[CONFIGURED] for schema/tags/queries, and to [DOCUMENTED, MANUAL STEP
REQUIRED] for alarm-pipeline routing and RBAC/IdP, which stayed unfabricated
because no ground-truth schema exists for either resource type.

## What's in this delivery

| Folder | Contents |
|---|---|
| `site_quality_control_MES.zip` | The importable Ignition project — 41 files, validated clean (0 JSON parse errors, cross-referenced tag paths and Named Query bindings, verified via `json.load` not the regex heuristic that false-positived twice this session) |
| `schema/001_site_quality_control_schema.sql` | PostgreSQL DDL — run this against your DB before first import |
| `theme/porta-mes-theme.css` + `DEPLOYMENT.md` | Brand theme, Gateway-level deployment steps, honest disclosure of the missing font files |
| `RBAC_CONFIGURATION_GUIDE.md` | Designer GUI steps for roles — not fabricated JSON, no ground truth existed to check it against |
| `ALARM_PIPELINE_CONFIGURATION_GUIDE.md` | Same treatment for the tag-alarm → DB-journal wiring |
| `JUDGE_PASS.md` | Same-context self-evaluation, including the one real bug it caught |

## Before you import
1. Run the schema SQL against Postgres.
2. Confirm Porta's IT doesn't already standardize on SQL Server — the whole schema/query layer assumes Postgres based on continuity with your old project's own query, not a confirmed fact about your infrastructure.
3. Read `RBAC_CONFIGURATION_GUIDE.md`'s "genuine gap" section before go-live — QA role isn't actually read-only yet, it's just documented that it should be.
4. The `activeShift` session prop has no UI to set it yet — every submit currently logs shift_code = "DAY" regardless of actual shift. Real gap, caught late (see JUDGE_PASS.md), needs a decision on how operators should select it before this goes near a floor.
