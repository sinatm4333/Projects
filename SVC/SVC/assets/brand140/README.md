# Brand 140 logo assets

**Bare «140» icon mark only — no «Mobile140» / «موبایل ۱۴۰» wordmark.** (Confirmed 1405/05/23: the wordmark
lockups this folder originally had were wrong for this use case; removed.)

Source: `Y:\Management\Hamed-Sina\HR\Mobile140\Logo\140.png` (color) and a same-geometry crop of
`140 - FA - white.png`'s icon region (white — that file's own icon crop, not a separate asset in the source
folder). Originals ~9450×3922px, transparent background.
Guideline reference: `Y:\Management\Hamed-Sina\سیستم آقا حامد - دستکتاپ\برندبوک\Guide line\Mobile140-Visual Guideline-1402-08-8.pdf`,
page 13 ("لوگو بر روی بک‌گراندهای رنگی" — logo on colored backgrounds, cases A–E).

Resized here (System.Drawing/GDI+ high-quality bicubic, alpha preserved) to keep the base64 payload small — same
reasoning as the embedded Peyda font (no shared static-asset hosting on this platform, each bot carries its own copy).

| File | Use |
|------|-----|
| `logo140-mark-color.png` (241×100) | **Color** gradient mark — white / light-gray backgrounds |
| `logo140-mark-white.png` (241×100) | **White** mark — the `#16509D` accent band, dark or black surfaces |

`*.b64.txt` = base64 of the matching `.png`, ready to paste into an `<img src="data:image/png;base64,...">` —
regenerate via `base64 -w0 file.png`, never paste the blob inline in a written response (project convention).

## Background-pairing rule (guideline page 13, cases A–E)

The guideline's own text labels and its example images disagree on case B (text says "colored", the example
image shows white on that dark-gray swatch — an inconsistency in the source PDF). Going with the **example
images** (also the only reading consistent with the guideline's own "misuse" page, which explicitly shows a
colored gradient logo on a colored/dark panel as wrong):

| Background | Case | Variant |
|---|---|---|
| White / light gray (≈10–20% black) | A | **Color** (`logo140-mark-color.png`) |
| Dark gray (≈20–100% black) | B | **White** (`logo140-mark-white.png`) |
| The brand's own colored surfaces, e.g. the `#16509D` accent band | C | **White** |
| Black | D | **White** |

Practical rule for this project's HTML reports: **color mark on white/light-gray surfaces (page background,
table zebra rows, white cards); white mark anywhere on the `#16509D` accent** (header band, toolbar buttons,
`thead th`) or on black. Never the color gradient mark on the accent color or any dark surface.

There's also a separate "MONOCHROM FORMATS" page (14) with 3 flat single-tone alternatives (solid blue, solid
black, solid silver — no gradient) for cases the two-tone gradient can't reproduce. Not needed for HTML/screen
use; not included here.

## Primary palette (for reference — does NOT replace the mandatory `#16509D` report accent; see CLAUDE.md)

- Gradient: `#00AEEF` → `#192F7C`
- Spot / solid: `#192F7C` (Pantone 2756 C)
- Secondary (sparing use only, never as a large fill): `#0072BC` (blue), `#EF3C51` (red), `#EFEFED` (neutral gray)
