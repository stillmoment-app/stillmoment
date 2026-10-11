---
name: compose-text-overflow-testing
description: Compose text truncation in UI tests and layout - hasVisualOverflow false positives, MiddleEllipsis glyph positions, trailing slack next to a following Text
metadata:
  type: feedback
---

Learned in shared-139 (edit sheet file info, Compose BOM 2026.09):

- `TextLayoutResult.hasVisualOverflow` (via `SemanticsActions.GetTextLayoutResult`) reports `didOverflowWidth = true` for a single-line text that fits easily (width 134 px, maxWidth 921). Unusable for "text is not cut off". Robust instead: `lineCount == 1`, `!isLineEllipsized(0)`, `ceil(multiParagraph.intrinsics.maxIntrinsicWidth) <= size.width`.
- With `TextOverflow.MiddleEllipsis`, `getBoundingBox`/`getLineRight` refer to the unshortened text (values far outside the box, e.g. -214 dp gaps). Do not measure visible glyphs under middle ellipsis; check node bounds and verify by screenshot.
- A middle-ellipsized text is narrower than its box (the "…" replaces whole glyphs). In a Row with a Text after it, that leaves a visible gap of a few dp. `textAlign = TextAlign.End` on the shortened text keeps it flush against the following text; with `weight(1f, fill = false)` short names are unaffected.

**Why:** Each of these cost a build+instrument cycle (~2 min) before it was understood.
**How to apply:** For any Compose UI test about truncation, and for layouts of "shortened text + fixed text".
