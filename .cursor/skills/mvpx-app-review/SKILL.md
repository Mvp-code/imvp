---
name: mvpx-app-review
description: >-
  Reviews the live MVPx JSP/Servlet DSP fleet application and produces a ranked
  improvement list plus a short implementation plan for the top items. Use when
  the user asks to review the current application, audit MVPx, suggest
  improvements, prioritize tech debt, run a health check, or asks what to
  improve next.
---

# MVPx Application Review

Review the **current live MVPx app** and recommend improvements. Do not implement unless the user explicitly asks after the review.

Pair with `mvpx-ui-modernization` and `ui-design-brain` for UI findings. This skill owns scope, evidence, ranking, and the plan.

## Non-negotiables

1. Evidence from this repo and, when possible, the running app. No generic Java/JSP advice.
2. Suggest only. Stop after the report unless the user says to implement.
3. This is a production Tomcat 9 JSP/Servlet operational DSP app. Do not recommend a rewrite, a new framework, or a SPA migration as the default path.
4. Prefer incremental, reversible changes that fit `MainCtrl` / `*DAO` / JSP patterns.
5. UI suggestions must respect `mvpx-ui-modernization` (CSS-first, fragile selectors, no silent markup/JS changes).
6. Never recommend committing secrets, `META-INF/context.xml`, Twilio SIDs/tokens, or generated `docs/` binaries.
7. If the user scoped the review (one page, one module), stay in that scope.

## What MVPx is

Amazon DSP operations platform (station DNK7). Users are dispatchers, fleet/HR staff, and TechAdmins — not consumer-app users.

| Layer | Where |
|---|---|
| Front controller | `src/com/servlet/MVPGServlet.java` → `MainCtrl` / `MVPGCtrl` |
| Routing | `/servlet/MVPGServlet?submitType=&controller=` plus some direct `/jsp/*.jsp` links |
| Pages | `jsp/*.jsp` with shared `includeHeader.jsp`, `includeSidebar.jsp`, `includeFooter.jsp` |
| Data | `src/com/dataobjects/*DAO.java`, MySQL via JNDI `jdbc/MVPGDB` |
| APIs | `APIServlet`, `EmilyApiServlet` (`/api/emily/*`), `IngestApiServlet` (`/api/ingest/*`) |
| Live CSS | `jsp/assets/css/mvpx.css`, `jsp/assets/css/mvpx-list.css` |
| Config | `WEB-INF/web.xml` (Servlet 2.3), `ApplicationConfig` |

**Product surfaces:** Operations (DA status/checkin/checkout, SMS, wave sheet, returns, tasks), People (onboarding, employees, schedule, terminations), Safety, Fleet, Documents/uploads, Analytics/scorecard, Emily dispatcher, Admin.

Read [checklist.md](checklist.md) for hotspot checks.

## Workflow

Copy and track:

```
Review:
- [ ] 1. Scope
- [ ] 2. Map current behavior
- [ ] 3. Inspect evidence
- [ ] 4. Score findings
- [ ] 5. Deliver ranked list + top-item plan
```

### 1. Scope

Default: full-app health across UX, UI, architecture, security, ops, and product.

If the user names a page, role, or module, review that depth-first and only mention cross-cutting issues that affect it.

Ask only if the request is impossible to bound (e.g. "improve everything" with no access to the app and no module named). Prefer inspecting over asking.

### 2. Map current behavior

Identify:

- Entry points (login, servlet vs direct JSP)
- Navigation the user actually sees (`includeSidebar.jsp` vs `includeHeader.jsp` `moduleArray`)
- Role gates (`TechAdmin`, driver role `"4"`, `entityID`)
- Create / search / edit / upload / report paths in scope
- What a dispatcher or TechAdmin is trying to finish on that screen

### 3. Inspect evidence

Use the repo, not memory:

- Read the JSP, its `*Ctrl` / `*DAO`, and shared includes
- Compare sidebar links to header module list — flag pages that exist in one nav but not the other
- Grep for SQL concatenation, request-parameter identity, missing session checks, direct JSP access
- Note backup/sample pages (`*_Backup*.jsp`, `*Sample.jsp`) still reachable
- For UI/UX: open the running app when browser tools exist and exercise the flow; screenshots are not a review

### 4. Score findings

Every finding needs:

- **Impact:** High / Med / Low — harm to operators, safety, data, or daily DSP work
- **Effort:** S / M / L — S = localized JSP/CSS/DAO; M = several files; L = cross-cutting (auth filter, SQL parameterization program-wide)
- **Confidence:** High / Med / Low — based on code+runtime evidence
- **Type:** Product / UX / UI / Architecture / Security / Ops

Drop Low-impact + Low-confidence noise. Prefer fewer sharp recommendations.

**Priority score (use to rank):**

`High impact + S effort` first, then High+M, Med+S, High+L, then the rest.

Security that is exploitable on the live app outranks polish.

### 5. Deliver

Use the report template below. Then stop.

If the user later says implement, take items in rank order, smallest safe slice first, and keep UI work inside `mvpx-ui-modernization`.

## Review lenses

### Product / workflow

- Can a dispatcher finish a shift loop (status → checkin → tasks → checkout) without hunting?
- Onboarding, vehicle docs, and uploads: is the next action obvious?
- Dead, sample, or duplicate screens that compete with the live path
- Role-appropriate nav: drivers vs dispatchers vs TechAdmin

### UX

- One primary action per screen; verb-first buttons
- Search/list vs create/edit: can users recover from empty, error, and permission-denied states?
- Mobile/tablet: 44px targets, no truncated operational tables without a path to the data
- Inconsistent entry: servlet controller vs raw JSP URL

### UI

- Visual consistency with live MVPx CSS tokens, not a new palette
- Cite `ui-design-brain` patterns, but do not violate fragile tabular-form CSS
- Flag one-off page CSS and rainbow section colors

### Architecture / tech debt

- Dual navigation sources drifting apart
- Business logic in JSP scriptlets vs DAO
- `System.out` / printStackTrace instead of useful operator errors
- Hardcoded filesystem paths in `web.xml`
- Oracle leftovers in `DatabaseQuery` if MySQL-only in production

### Security

- Session vs request-parameter `loginUser` / `loginUserRoles` / `loginUserID`
- Direct `*.jsp` access with no servlet filter in `web.xml`
- SQL built by string concatenation; quotes escaped by replacing `'`
- Uploads and `docs/` under the webapp (servable files, PII)
- Admin/config pages reachable without TechAdmin

### Ops / reliability

- Upload roots and machine-specific paths (UAT `F:/` vs laptop `C:/`)
- Error handling that strands a dispatcher mid-shift
- Generated PDFs and employee docs showing up as git noise
- Config and secrets loading (Admin Configuration / env, never hardcoded Twilio)

## Report template

```markdown
# MVPx review: [full app | module/page]

**Scope:** …
**Evidence:** files read, screens exercised, date
**Summary:** 3–5 sentences. What is working, what is the biggest constraint, what to do next.

## Ranked improvements

| Rank | Finding | Type | Impact | Effort | Why it matters |
|---:|---|---|---|---|---|
| 1 | … | Security | High | M | … |

## Top-item implementation plan

For ranks 1–3 (or 1–5 if they are all S/M):

### 1. [Finding title]
- **Outcome:** what operators will notice
- **Approach:** files and pattern to change (incremental, in-stack)
- **Out of scope:** what not to touch
- **Verify:** concrete clicks / role / page
- **Risk:** …

### 2. …
### 3. …

## Deferred
Items worth knowing but not next. One line each.

## Do not do
Rewrite/migration ideas and anything that would break live DSP operations.
```

Keep the plan short: enough that a later turn can execute it, not a design doc.

## After the review

- Do not start coding.
- Do not create tickets unless asked.
- Do not git-sync a "review" that only added notes unless the user asked for a committed report file.
- If asked to implement, re-read this skill's ranked plan and `mvpx-ui-modernization` before editing.
