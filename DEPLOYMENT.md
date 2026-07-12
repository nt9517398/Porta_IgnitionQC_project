# Deploying the Porta brand theme

Mechanism confirmed against the "Modern Table" Ignition Exchange example (README + working `style.css` you provided) — this is a **Gateway file-system step, not a project-import step**. `porta-mes-theme.css` cannot be zipped into the project export and imported through Designer; Perspective themes live outside any single project.

## Steps (mirrors the reference example exactly, renamed to Porta's files)

1. On the Gateway server, navigate to:
   `<Ignition install dir>/data/modules/com.inductiveautomation.perspective/themes/`
2. Create a new folder here called `custom-css`.
3. Copy `porta-mes-theme.css` (in this deliverable's `theme/` folder) into `themes/custom-css/`.
4. Open whichever theme your session actually uses — check `session.props.theme` in a running session, almost certainly `light.css` or `dark.css` in that same `themes/` folder — and add as the last line:
   ```css
   @import "./custom-css/porta-mes-theme.css";
   ```
   This needs admin rights on the Gateway file system to save.
5. In Designer: **File → Update Project** (or restart the Gateway if it doesn't pick up the change live).
6. On any component, add the relevant class to its `style.classes` prop — e.g. `porta-button-primary` on a button, `porta-table` on a Perspective Table. Perspective matches that name to the `.psc-porta-button-primary` selector automatically; you type the bare name, not the `psc-` prefix.

I've already wired `style.classes` on every button/header/table in this build (see below), so step 6 is done for you inside the project — steps 1–5 are the one part that needs your hands on the actual Gateway file system, which I don't have access to.

## The one gap I can't close myself

`porta-mes-theme.css` references two self-hosted font files:
```
./porta-fonts/poppins-600.woff2
./porta-fonts/poppins-700.woff2
```
**These two files don't exist yet.** My sandbox's network allowlist doesn't include `fonts.gstatic.com` (it's scoped to package registries — PyPI, npm, GitHub — not font CDNs), so I genuinely cannot fetch them from here. Two options, your call:

- **Self-hosted (what the CSS currently expects):** download Poppins weights 600 and 700 as `.woff2` from [Google Fonts](https://fonts.google.com/specimen/Poppins) or [fonts.google.com/download](https://fonts.google.com/specimen/Poppins) on any machine with internet access, place them at `themes/custom-css/porta-fonts/` on the Gateway. Zero runtime dependency on external internet after that — the right call if the Gateway/OT network is locked down, which is common enough in a plant environment that I defaulted to it.
- **CDN (what the Modern Table reference actually does):** replace the two `@font-face` blocks in `porta-mes-theme.css` with `@import "https://fonts.googleapis.com/css2?family=Poppins:wght@600;700&display=swap";` — one line, works immediately, but every client session now depends on reaching Google's CDN at render time. Fine if Porta's plant network allows general internet egress; a silent fallback-to-system-font if it doesn't.

Until either is done, `font-family: var(--porta-font-display)` degrades gracefully to `'Segoe UI', system-ui, sans-serif` — nothing breaks, headers just render in the OS default instead of Poppins until the font question is settled.
