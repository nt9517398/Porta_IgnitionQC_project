# RBAC / Security Zone configuration guide

**This is a configuration guide, not an importable resource.** Everything else in this build (views, tags, queries) was either validated against your own real project export or against the two Ignition Exchange references you provided. Identity Provider and Security Level definitions are neither — I have no ground-truth example of that resource's JSON in this conversation, and fabricating one with the same confidence as the rest of the build would be dishonest about what's actually verified. This is written as exact Designer GUI steps instead.

## Roles needed (4)

| Role | Access |
|---|---|
| **Operator** | The 4 data-entry pages only. Cannot see `/alarms`. |
| **Supervisor** | Everything Operator has, plus `/alarms`, plus alarm acknowledgment (the popup calls `qc/alarms/acknowledge` — restrict who can trigger that action to this role and above). |
| **QA** | Read-only across all pages — history tables, SPC, correlation, alarm journal. No Enter buttons, no acknowledgment. Not yet enforced anywhere in this build (see gap below). |
| **Engineer** | Full access, plus whatever Designer-level project editing your existing IT policy already gates separately. |

## What's already wired to roles in this build
- `page-config/config.json` gates `/alarms` behind `requiredRoles: ["Supervisor", "Engineer"]` — standard Perspective page-security, this part **is** a normal project resource and imports fine.
- `shell/nav_shell/view.json` hides the "Alarms" nav link from anyone without those roles, via `hasRole()` in an expression binding.

## What's a genuine gap, not an oversight
**QA's "read-only" restriction is not enforced anywhere yet.** A QA-role user hitting `/lathe` directly today would see the same Enter button an Operator does — nothing currently checks role before allowing a submit. Closing this needs one of:
- Per-page `requiredRoles` restricting the 4 data-entry pages to Operator/Supervisor/Engineer only (simplest — QA gets a clear "not authorized" rather than a button that quietly shouldn't be pressed), or
- A `visible`/`enabled` binding on each Enter button checking `!hasRole(session.props.auth.user, "QA")` (more permissive — QA can see the entry screen mid-shift for context, just can't submit).

I didn't pick one because it's a genuine judgment call about whether QA should see live entry screens at all — say which and I'll wire it in.

## Designer steps to actually create the roles
1. Gateway webpage → Config → Security → Identity Providers → confirm which IdP is active (internal Ignition user source, AD/LDAP, etc. — I don't know which Porta uses).
2. Under that IdP's User Sources, create/confirm the 4 roles above exist with those exact names — the `hasRole()` calls and `requiredRoles` arrays in this build are case-sensitive string matches against whatever you name them.
3. Assign at least one test user per role before FAT.
