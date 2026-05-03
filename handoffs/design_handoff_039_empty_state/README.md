# Handoff: Ticket shared-039 — Empty State + In-App Content Guide

## Overview

Two related changes for the **Library** (Geführte Meditationen) screen of the Still Moment meditation app:

1. **New empty state** — replaces the current "No meditations yet" placeholder with an inviting welcome screen: waveform icon, title, body, primary CTA ("Meditation importieren"), and a secondary text link ("Wo finde ich Meditationen?").
2. **Content Guide Sheet** — a compact, scrollable, non-full-screen sheet listing curated free meditation sources, split by app locale (DE / EN). Reachable from the empty state's secondary CTA **and** from a persistent `ⓘ` icon in the library nav bar (so it stays accessible once the library is no longer empty).

Reference: see the original ticket text. Concept doc: `dev-docs/concepts/byom-strategy.md`.

## About the Design Files

The files in this bundle (`library-empty.jsx`, `shell.jsx`, `styles.css`) are **design references created in HTML/React for prototyping** — they show intended look, layout, and copy. They are **not production code to copy directly**.

The implementation task is to **recreate these designs in the target codebase's existing environment**:

- **iOS**: SwiftUI, in `ios/StillMoment/Presentation/Views/GuidedMeditations/` (see `GuidedMeditationsListView.swift` for the existing empty state)
- **Android**: Kotlin/Compose, in `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/` (see `EmptyLibraryState.kt`)

Use the established design tokens, components, and theming patterns of each platform — match the three existing color themes plus light/dark mode.

## Fidelity

**High-fidelity.** Final colors, typography, spacing, copy, and interactions. The implementation should match the prototypes pixel-perfectly within the constraints of the platform's existing design system. Specifically: the visible "warm" theme in the prototype (mahogany background + copper accent) is one of the three themes — the other two (sage / dusk accents) must keep the same layout and typography, only swapping accent variables.

## Screens / Views

There are **3 distinct visual deliverables** plus the persistent nav-bar entry point.

### 1. Empty State (final variant — "A. Treu zur Spec")

**Purpose:** First-run / empty-library state. Welcomes the user, names the BYOM model, gives one primary action (import) and one secondary path (find sources).

**Layout (top-to-bottom inside the standard phone shell):**

- **Status bar** — platform standard, height 54.
- **Top nav bar** — 64 high (`8px 20px 16px` padding), three groups:
  - **Left**: hamburger / menu icon button (36×36 circular, `rgba(235,226,214,0.06)` bg)
  - **Center**: Title `Geführte Meditationen` (DE) / `Guided Meditations` (EN), Newsreader 18, regular weight
  - **Right**: two icon buttons in a row (`gap: 8`), 36×36 each: `+` (Plus) and `ⓘ` (Info-Circle)
- **Empty content block** — vertically stacked, centered, `padding: 80px 36px 0`, `text-align: center`:
  1. **Waveform glyph in glow circle** — 120×120 round container with a radial-gradient background (`radial-gradient(circle, var(--sm-accent-dim) 0%, transparent 65%)`), waveform sits inside at 104px wide. `margin-bottom: 32`. The waveform is three sine ribbons with fade edges using copper accent color (see "Waveform glyph" below).
  2. **Title** — `Newsreader 26 / 1.18 line-height`, `max-width: 260`, `margin-bottom: 14`.
     - DE: `Dein persönlicher Meditationsraum`
     - EN: `Your Personal Meditation Space`
  3. **Body** — Geist 14 / 1.55, color `--sm-text-2` (`#a89a8c`), `max-width: 280`, `margin-bottom: 36`.
     - DE: `Importiere Meditationen von deinen Lieblingslehrern und erstelle so deine persönliche Bibliothek.`
     - EN: `Bring meditations from your favorite teachers and build a library that's truly yours.`
  4. **Primary CTA** — pill button, copper gradient `linear-gradient(180deg, #d68a6e, #b06a4f)`, text `#2a1208`, weight 600, font-size 15, padding `14px 28px`, with a `+` icon on the left (`gap: 10`). Shadow: `0 16px 40px -12px rgba(196,122,94,0.5), 0 0 0 1px rgba(214,138,110,0.3) inset`.
     - DE: `+ Meditation importieren`
     - EN: `+ Import a meditation`
  5. **Secondary link** — text-only button, color `var(--sm-accent-text)` (`#d99a7e`), font-size 14, `margin-top: 22`. Underlined with `text-underline-offset: 4px` and `text-decoration-color: rgba(217,154,126,0.35)`.
     - DE: `Wo finde ich Meditationen?`
     - EN: `Where can I find meditations?`
- **Tab bar** — platform standard at bottom.

**No mention of the timer tab anywhere on this screen.** The tab bar itself makes it discoverable.

### 2. Content Guide Sheet

**Purpose:** Curated, locale-specific list of free meditation sources. Compact, scrollable, no full-screen takeover. Closes when the user taps a link (which opens the system browser) or the close button.

**Layout (sheet sits on a dimmed library backdrop):**

- **Backdrop** — dimming overlay over the library content (`rgba(10,6,4,0.55)`), with the library still faintly visible underneath.
- **Sheet container** — bottom-anchored, `height: 720` of an 852 viewport (so ~78% of phone height). Background gradient `linear-gradient(180deg, #2a1812 0%, #1d100b 100%)`. Top corners rounded `28px`. Top border 1px `rgba(235,226,214,0.08)`. Drop shadow upward `0 -20px 60px rgba(0,0,0,0.5)`.
- **Grabber** — 38×4 pill, `rgba(235,226,214,0.18)`, centered, padding `10px 0 6px`.
- **Title row** — `padding: 8px 22px 18px`, flex space-between:
  - Title: Newsreader 22, regular.
    - DE: `Wo finde ich Meditationen?`
    - EN: `Where to find meditations`
  - Close button: 30×30 circular, `rgba(235,226,214,0.06)` bg, X glyph, color `--sm-text-2`.
- **Intro paragraph** — Geist 13 / 1.55, color `--sm-text-2`, padding `0 22px 16px`.
  - DE: `Eine kleine, kuratierte Auswahl. Kostenlos, frei zugänglich. Tippe einen Eintrag, um die Quelle im Browser zu öffnen.`
  - EN: `A small, curated set. Free and openly accessible. Tap an entry to open the source in your browser.`
- **Section header** — `padding: 0 22px 8px`, flex baseline space-between:
  - Left: `h-section` style (Geist 13, weight 500, uppercase, letter-spacing 0.08em, color `--sm-text-3`). Text: `Quellen · Deutsch` (DE) / `Sources · English` (EN).
  - Right: count number, font-size 11, color `--sm-text-3`.
- **Source list** — flex-1, scrollable, padding `0 18px 18px`. Wrapped in a `.card` container (background `rgba(255,255,255,0.02)`, border 1px `--sm-card-line`, radius `--sm-r-lg` (24px)). Each row:
  - Padding `14px 16px`. Top border 1px `rgba(235,226,214,0.05)` (except first row).
  - Flex row, `gap: 12`, items-center.
  - **Left column (flex 1)**:
    - First line: Newsreader 15 — source name, optionally followed by a `·` separator and Geist 12 author in `--sm-text-2`. Wraps via `flex-wrap: wrap` and `gap: 8`.
    - Second line: Geist 12, color `--sm-text-2`, line-height 1.45, margin-top 4 — short description (1 sentence).
    - Third line: Geist 12, color `--sm-text-3`, margin-top 6, letter-spacing 0.01em — **plain sans-serif** (NOT monospace) host string.
  - **Right**: external-link icon, 22×22, color `--sm-accent-text`.
- **Footnote** — under the card, padding `16px 8px 0`, info icon + text. Geist 11 / 1.55, color `--sm-text-3`.
  - DE: `Links öffnen im System-Browser. Keine Tracking-Daten verlassen die App.`
  - EN: `Links open in the system browser. No tracking data leaves the app.`

**Source content (locale-gated; only one set is ever shown at a time):**

DE-Locale (4 entries):

| Name | Author | Description (1 sentence) | Host |
|---|---|---|---|
| Achtsamkeit & Selbstmitgefühl | Jörg Mangold | MBSR, MSC, Körperscans. 3–49 Min. Als Arzt und Psychotherapeut zertifiziert. | podcast |
| Einfach meditieren | Melissa Gein | Achtsamkeit, Selbstliebe, Schlaf. 6–19 Min. Direkt-Download via podcast.de. | podcast.de |
| Meditation-Download.de | — | Geführte Meditationen, kein Account nötig. | meditation-download.de |
| Zentrum für Achtsamkeit Köln | — | MBSR Body Scan, Sitzmeditation. | achtsamkeit-koeln.de |

EN-Locale (6 entries):

| Name | Author | Description | Host |
|---|---|---|---|
| Dharma Seed | — | Thousands of dharma talks & guided meditations. Direct MP3. | dharmaseed.org |
| Audio Dharma | Gil Fronsdal | Vipassana tradition. Direct MP3. | audiodharma.org |
| Tara Brach | — | Guided meditations, RAIN practice. Direct MP3. | tarabrach.com |
| Jack Kornfield | — | Lovingkindness, forgiveness practices. | jackkornfield.com |
| UCLA Mindful | — | Research-based mindfulness. German translations also available. | uclahealth.org |
| Free Mindfulness Project | — | Creative-commons licensed, freely shareable. | freemindfulness.org |

**The actual `https://…` URLs must be stored in localization files** (e.g. `guided_meditations_source_dharma_seed_url`), not hardcoded in views. This is an explicit acceptance criterion.

### 3. Library Populated — Persistent Guide Entry

Shown so reviewers can see that the `ⓘ` entry remains visible after the library has content.

- **Top nav** is identical to the empty state: title on the left, `+` and `ⓘ` icons on the right (38×38 in this denser variant).
- After the meditation list (grouped by author, existing pattern), a **Hint Card** anchors the guide:
  - Full-width, padding `14px 16px`, margin-top 6.
  - Background `rgba(196,122,94,0.06)`, **dashed** border `1px dashed rgba(196,122,94,0.22)`, border-radius 18.
  - Left: 28×28 circle, `var(--sm-accent-dim)` bg, color `--sm-accent-text`, info icon inside (14×14).
  - Center (flex 1):
    - Line 1: Geist 14, the secondary-CTA text (`Wo finde ich Meditationen?` / `Where can I find meditations?`).
    - Line 2: Geist 11, color `--sm-text-2`, margin-top 2.
      - DE: `Kuratierte Quellen — jederzeit hier oder über das ⓘ-Symbol oben.`
      - EN: `Curated sources — always here, or via the ⓘ icon above.`
  - Right: chevron-right, 16×16, color `--sm-text-3`.
- Tap → opens the same Content Guide Sheet.

## Interactions & Behavior

- **Empty state primary CTA** → opens the existing document picker (BYOM import flow). No change to import logic.
- **Empty state secondary CTA** → opens Content Guide Sheet (modal sheet presentation: from-bottom slide).
- **Library nav `ⓘ` button** → opens Content Guide Sheet. Always present, regardless of library state.
- **Library Hint Card** → opens Content Guide Sheet.
- **Content Guide source row tap** → opens the URL in the **system browser** (Safari / Chrome). Not an in-app web view. After navigation, the sheet is dismissed and the user returns to the library unchanged.
- **Sheet close button** → dismisses the sheet.
- **Sheet grabber drag-down** → dismisses the sheet (use platform-standard sheet semantics).
- **No tracking** of which links are clicked. No analytics events on guide row taps.

### Animations

- Sheet present/dismiss: platform-standard sheet animation (iOS detent, Android modal bottom sheet).
- Empty-state appearance: fade in over ~200ms when the library is determined to be empty, no further motion.
- All button presses: 0.98 scale on active (`transform: scale(0.98)`), 150ms ease.

### States

- **Loading**: while the library is being read from local storage, show no empty state — show a brief skeleton or just nothing. The empty state is only shown once we *know* the library is empty.
- **Error states**: if the document picker fails or import errors, surface via existing toast/snackbar pattern.
- **Locale switch at runtime**: if the device locale changes while the sheet is open, all strings re-resolve immediately (use the platform's standard string-table lookup; do not cache).

## State Management

- `isLibraryEmpty: Bool` — derived from the meditations store; drives whether to show the empty state vs. the populated list.
- `isGuideSheetPresented: Bool` — drives sheet presentation. Toggled by the secondary CTA, the nav `ⓘ` button, and the Hint Card.
- `currentLocale: Locale` — already exists; used to select between DE and EN source lists at the localization layer.

No new persisted state. No backend calls. The guide is fully static.

## Design Tokens

All values come from the existing token system. Excerpt (warm theme, see `styles.css` for full list):

```
/* Background */
--sm-bg-deep:   #150a07
--sm-card:      #2a1812
--sm-card-line: rgba(235, 226, 214, 0.06)

/* Accent — copper (warm theme) */
--sm-accent:       #c47a5e
--sm-accent-soft:  #b06a4f
--sm-accent-glow:  #d68a6e
--sm-accent-dim:   rgba(196, 122, 94, 0.18)
--sm-accent-text:  #d99a7e

/* Text */
--sm-text:    #ebe2d6
--sm-text-2:  #a89a8c
--sm-text-3:  #6f6358

/* Radii */
--sm-r-md: 18px
--sm-r-lg: 24px
--sm-r-xl: 32px (sheet top corners use 28px)

/* Type */
display: Newsreader (serif, regular 400) — used for titles, source names, row titles
ui:      Geist (sans, 400/500) — used for body, labels, eyebrows
```

For the **sage** and **dusk** themes, only the `--sm-accent*` group changes. Layout, sizes, and base text colors stay the same.

### Spacing scale used here

`6, 8, 12, 14, 16, 18, 22, 28, 32, 36` px. Card padding pattern: `14px 16px` for rows, `padding: 0 22px` for sheet outer gutter, `padding: 0 18px` for list gutter (so the card sits 4px wider than the title).

## Assets

- **Waveform glyph**: use the platform's native equivalent of SF Symbols `waveform`.
  - iOS: `Image(systemName: "waveform")`, foreground color `--sm-accent-glow`, font weight `.regular`, size ~80pt inside the 120-pt glow circle.
  - Android: a Material Symbols equivalent (`graphic_eq` is the closest Material analogue). If a closer match is available in the project's icon set, prefer that.
  - The HTML prototype draws sine ribbons by hand for fidelity; do **not** port the SVG — use the native symbol.
- **Plus / Info / Chevron / External-link icons**: use the existing icon system in each codebase. Stroke weight ~1.6, rounded caps to match other icons.
- **No custom illustrations or imagery.** The waveform symbol is the only visual.

## Acceptance Criteria (from the ticket)

### Empty State (both platforms)
- [ ] Waveform icon above the title (SF Symbol `waveform` / Material equivalent)
- [ ] Title: `Dein persönlicher Meditationsraum` (DE) / `Your Personal Meditation Space` (EN)
- [ ] Body copy as specified above
- [ ] Primary CTA opens the document picker (existing logic, unchanged)
- [ ] Secondary CTA opens the Content Guide Sheet
- [ ] No mention of the Timer tab
- [ ] Looks correct in all 3 themes, light + dark

### Content Guide Sheet (both platforms)
- [ ] Reachable via empty-state secondary CTA AND via `ⓘ` icon in the nav bar
- [ ] DE locale shows DE sources; EN locale shows EN sources
- [ ] Each source: name, 1-sentence description, link
- [ ] Links open in the system browser (Safari / Chrome), NOT an in-app browser
- [ ] No tracking of which links are tapped
- [ ] Sheet is scrollable
- [ ] All URLs centralized in localization files, not hardcoded in views

### Quality
- [ ] Localized (DE + EN) — copy and source lists
- [ ] Visually consistent between iOS and Android
- [ ] Accessibility: links semantically marked as links; section headers exposed to screen readers

### Tests
- [ ] Unit tests: sheet renders correctly in DE and EN locale
- [ ] Snapshot/screenshot test for empty state (at least 1 theme, light + dark)

### Documentation
- [ ] CHANGELOG.md updated

## Manual Test Plan

**Empty state:**
1. Delete all meditations (or fresh install)
2. Open Library tab
3. Expect: waveform icon, welcome copy, two CTAs visible
4. Tap primary → document picker opens
5. Tap secondary → Content Guide Sheet opens

**Content guide sheet:**
1. Open sheet (via empty state OR `ⓘ` icon)
2. Scroll through sources
3. Tap a link
4. Expect: Safari/Chrome opens; the app stays in the background
5. Return to app → sheet is closed; library is unchanged

**Persistent access:**
1. Import a meditation (library no longer empty)
2. `ⓘ` icon in the nav bar is still visible
3. Tap → Content Guide Sheet opens

**Locale separation:**
1. Set device to DE → only German sources shown
2. Set device to EN → only English sources shown

## Files in this bundle

- `library-empty.jsx` — React/HTML reference implementation of the three empty-state explorations plus the populated-library and guide-sheet components. **The exported `EmptyStateA` and `GuideSheet` components are the final design.** `EmptyStateB` and `EmptyStateC` are earlier explorations kept only for reference; do not implement.
- `shell.jsx` — shared phone-shell components used by the prototypes (status bar, tab bar, icon set). Reference only — your platform already has these.
- `styles.css` — full design-token CSS for the warm theme. Use this as the source-of-truth for color and type values; map them to your platform's token system.

## Notes

- The source list is intentionally small. Quality > quantity.
- The guide is purely static. No dynamic content. No API calls.
- Keep URLs in localization files so they can be updated without a code change.
- Reference files in the existing codebase:
  - iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
  - Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/EmptyLibraryState.kt`
