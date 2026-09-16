---
name: mvpg_fonts
description: >-
  Applies MVPx/MVPG Salesforce-style typography (Inter as Salesforce Sans
  stand-in; DM Sans, Open Sans, Work Sans fallbacks). Use when changing fonts,
  headers, text boxes, labels, tables, buttons, type tokens (--font,
  --font-disp, --font-mono), Google Fonts in includeHeader.jsp, or when the
  user mentions mvpg_fonts, Salesforce fonts, Inter, DM Sans, Open Sans,
  Work Sans, or Aller.
---

# mvpg_fonts

Salesforce-style type for the MVPx (MVPG) JSP/Servlet app. Pair with `mvpx-ui-modernization` (CSS-first, no silent markup/JS). This skill owns **which fonts go where**.

## Default: one family

Salesforce Lightning uses **one** UI face (Salesforce Sans). MVPx does the same with **Inter**.

Do not assign a different Google Font to every region. Headers, body, text boxes, table text, and buttons share Inter. Weight and size create hierarchy, not a second family.

**Stack (load order / CSS fallback):**

```text
'Inter', 'DM Sans', 'Open Sans', 'Work Sans', 'Segoe UI', sans-serif
```

**Never use Aller.** Closest wordmark match, but Dalton Maag license is free only up to 25 users — not valid for the live DSP app.

## Why each font is on the list

| Font | Why it is listed | Use in MVPx |
|---|---|---|
| Inter | Humanist sans, screen-optimized at small sizes, OFL | **Primary — all UI text** |
| DM Sans | Low-contrast humanist, strong at small sizes, OFL | Fallback 2 (and optional small-field face if user asks for a split) |
| Open Sans | Open apertures, friendly weight, Apache | Fallback 3 |
| Work Sans | Digital-screen mid-weight, OFL | Fallback 4 (skip as a second live face — too close to Inter) |
| Aller | Closest Salesforce wordmark | **Do not load or apply** |

## Roles (current spec)

| Role | Font | Size / weight |
|---|---|---|
| Page headers (`h1`–`h4`, `.da-headrow h2`, `.tb-page`, `.sb-brand-name`) | Inter | 24px / 700, letter-spacing `-0.015em` |
| Body, chips, labels, nav | Inter | 13–14px / 400–600 |
| Text boxes, selects, textareas, `.da-flt`, `.cmt`, `.statusSel` | Inter | 13px / 400 |
| Table headers | Inter | 12px / 600, no uppercase tracking, **not** Geist Mono |
| Table cells | Inter | 14px / 400 |
| Buttons | Inter | 13.5px / 600 |
| True data (VIN, times, IDs) | Inter | Same stack as body (not Geist Mono) |

If the user later asks for a **split** (not the default):

- Headers → Inter 700
- Text boxes + table → DM Sans
- Buttons / chrome → Open Sans
- Work Sans → still skip
- Aller → still skip

## Files

| File | What to change |
|---|---|
| `jsp/includeHeader.jsp` | Google Fonts `<link>` must include Inter, DM Sans, Open Sans, Work Sans (400/500/600/700). Keep Geist / Bricolage loaded until global rollout is done. |
| `jsp/assets/css/mvpx.css` | `--font` token |
| `jsp/assets/css/mvpx-revc.css` | `:root:root` `--font`, `--font-disp`, `--font-mono`; heading rules that currently set `--font-disp` to Bricolage |
| Page `<style>` | Only for a **one-page preview**. Production rollout belongs in the tokens above. |

Preview was DA Confirmations (`jsp/DAStatus.jsp`). Global tokens now use the Inter stack (`mvpx-revc.css` `:root:root`).

## Workflow

1. Read this skill before any font edit.
2. **Preview first** unless the user says to roll out everywhere. One page, then stop for review.
3. Prefer token changes (`--font`, `--font-disp`) over per-selector `font-family`.
4. Do not restyle via JSP markup or JS. Do not touch form flex/` :has()` layout rules.
5. After a global rollout, set `--font`, `--font-disp`, and `--font-mono` to the Inter stack so REV C stops painting Bricolage headers, Geist body, and Geist Mono table/data.
6. Report: files, selectors/tokens, pages affected, that behavior is unchanged.
7. Hard-refresh (cache-bust `includeHeader.jsp` `?v=` when the Google Fonts URL or CSS tokens change).

## Do not

- Mix Bricolage Grotesque display + Geist UI + Inter on the same Salesforce rollout
- Put Geist Mono on page titles or column headers
- Load Aller, Salesforce Sans (proprietary), or paid Dalton Maag cuts
- Change fonts on parked `mvpg-*` files unless asked
