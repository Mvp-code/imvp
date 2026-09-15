# React and Next.js Usage (Cursor)

## React
- Build UI with small, composable components.
- Centralize tokens (color, spacing, radius, typography) in a shared module.
- Use variants (`className`, `cva`, or equivalent) to avoid style duplication.

## Next.js
- Define a stable base shell in `app/layout.tsx` and route-specific shells by segment.
- Use loading/skeleton patterns to improve perceived performance.
- Prefer Server Components for data reading and Client Components for user interaction.

## Practical implementation hints
- Encode design decisions with semantic props (`tone`, `intent`, `density`).
- Add a consistency checklist in PR reviews (spacing, contrast, states, accessibility).
- Avoid ad-hoc styling; prefer reusable tokens and utilities.
