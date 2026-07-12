Version: 1.1
Date: 2026-07-10 (same-day follow-up to v1.0)
Delta Summary:

**Verification pass — the actual point of this version.** v1.0 disclosed 6 moderate-confidence, unverified JSON-schema assumptions in JUDGE_PASS.md rather than presenting them as fact. This version checked as many of them as possible against Inductive Automation's own documentation, an 8.3.2-specific forum post, and independent practitioner sources — and found 3 real bugs in the process, not just reassurance:

1. **Alarm setpoint key name — wrong, now fixed.** `tags.json`'s 3 alarm `setpointA` blocks used `"expression": "..."` as the value key. A forum post from a practitioner running Ignition 8.3.2 (Nguyen's exact target version), showing JSON copied directly out of Designer's alarm binding editor, confirms the real key is `"value"`, not `"expression"` — `{"bindType":"Expression","value":"..."}`. [T3 — single forum source, but version-matched and directly-observed JSON, not a guess] All 3 alarms fixed.

2. **Tag binding mode — wrong, now fixed.** `measurement_field`'s core value-display binding used `"mode": "direct"` with a `{view.params.tagPath}` placeholder in the path. Official docs confirm direct/indirect/expression are three *distinct* Perspective tag-binding modes, and a path containing a substitutable `{parameter}` is specifically the indirect mode. [T1 — docs.inductiveautomation.com] Changed to `"mode": "indirect"`. This binding pattern is used 19 times across the 4 stage views (every measurement field), so this was the highest-leverage fix in this pass.

3. **Bidirectional property binding — wrong, now fixed in 2 places.** Both the new shift-selector dropdown and the alarm-popup notes field used `"mode": "readWrite"` to make a property binding write back. Every official doc describing this uses "Bidirectional checkbox" / "bidirectional option" — never a mode string. [T1] Changed both to `"bidirectional": true`.

**Two functional gaps closed** (flagged as open in v1.0's JUDGE_PASS.md, not silently carried forward):
4. Added an actual shift-selector control to `nav_shell` — `session.custom.activeShift` was read by every submit script in v1.0 but nothing ever set it away from the "DAY" default. Now a dropdown, bidirectionally bound.
5. QA read-only access — resolved via page-level `requiredRoles` on all 4 data-entry pages (Operator/Supervisor/Engineer only). Chosen over the visible-but-disabled alternative for auditability; documented as a reversible decision in `RBAC_CONFIGURATION_GUIDE.md`, not a final word if QA turns out to need shift-time visibility.

**Positive finding, stated plainly:** the `typeId`-based UDT inheritance structure, the `_types_`/instance folder split, and the `AtomicTag`/`UdtType`/`UdtInstance` vocabulary in `tags.json` all matched the official docs' own example JSON on first check — no changes needed there. Also confirmed independently: two unrelated sources flag a real Ignition bug where spaces in UDT member names break Tag Drop bindings, which retroactively corroborates the H-001 finding in the original forensic audit (the old project's `"Moisture Content LHS"` naming) as more than a style preference.

Confidence Shifts:
- Alarm setpoint schema, tag-binding indirect mode, bidirectional property flag: [ASSUMED, moderate confidence] → [FACT, T1/T3-version-matched] for the first two, [CONFIGURED, verified] for all three now that the fix is applied and re-validated.
- UDT `typeId` inheritance shape: [ASSUMED, moderate confidence] → [FACT, T1 confirmed against official example JSON].
- Remaining unverified: `ia.input.link`/`targetURL` component existence, `hasRole()` exact expression-function signature, `session.props.auth.user.userName` exact path, Gateway timer script `resource.json` shape. Not checked this pass — flagging rather than implying this pass was exhaustive.
