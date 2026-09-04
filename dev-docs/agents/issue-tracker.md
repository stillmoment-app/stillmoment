# Issue tracker: Local Markdown (`dev-docs/tickets/`)

Issues for this repo live as markdown files under `dev-docs/tickets/`, **not** in
GitHub Issues. The GitHub repo has issues enabled but holds none — do not create
issues there, and do not treat an empty `gh issue list` as "no work tracked".

## Structure

```
dev-docs/tickets/
├── INDEX.md              ← the overview; every ticket has a row here
├── shared/               ← cross-platform tickets (shared-NNN-<slug>.md)
├── ios/                  ← iOS-only tickets (ios-NNN-<slug>.md)
├── android/              ← Android-only tickets (android-NNN-<slug>.md)
└── plans/                ← implementation plans (<ticket-id>[-<platform>].md)
```

IDs are `shared-NNN`, `ios-NNN`, `android-NNN`, numbered sequentially per prefix.

## Conventions

- **Never guess a filename.** The ID and the slug do not always match the topic
  (e.g. `shared-013-timer-focus-mode.md` holds what the index calls the timer
  state machine). Always glob `dev-docs/tickets/*/<ticket-id>*.md`.
- **Status lives in two places and both must agree**: the `**Status**:` line near
  the top of the ticket file, and the row in `INDEX.md`. Closing a ticket means
  updating both.
- **Status values**: `[ ]` TODO · `[~]` IN PROGRESS · `[x]` DONE · `[-]` WONTFIX.
  A WONTFIX ticket carries a `## WONTFIX` section stating why, and its INDEX row
  is struck through or annotated with the reason.
- **Cross-platform tickets track per platform.** `shared-*` tickets have a
  "Plattform-Status" table (iOS / Android) plus one column per platform in
  `INDEX.md`. A shared ticket is only DONE when both columns are — one platform
  may be DONE while the other is WONTFIX (superseded by a later ticket).
- **Ticket body**: `## Was` (what) and `## Warum` (why) up front, then
  `## Akzeptanzkriterien` as checkboxes, then `## Manueller Test`. Acceptance
  criteria are the implementation roadmap — `/implement-ticket` walks them
  one at a time under TDD.
- Documentation is written in German with ASCII transliteration (`ae`/`oe`/`ue`),
  matching the surrounding files.

## When a skill says "publish to the issue tracker"

Use the `/create-ticket` skill rather than writing a file by hand — it assigns the
next free number, picks the template and validates the ticket against the product
philosophy in `CLAUDE.md`. It also adds the `INDEX.md` row, which is easy to forget.

## When a skill says "fetch the relevant ticket"

1. Resolve the ID from the branch name (`feature/<ticket-id>[-<platform>]`), the
   commit message (`<type>(<scope>): #<ticket-id> …`), or ask the user.
2. Glob `dev-docs/tickets/*/<ticket-id>*.md` and read the file.
3. Check `INDEX.md` for the ticket's row — it carries the per-platform status and
   any dependency note that the ticket file itself may not repeat.

## Related conventions

- **Branches**: `feature/<ticket-id>` or `feature/<ticket-id>-<platform>`.
- **Commits**: `<type>(<scope>): #<ticket-id> <description>`, where type is one of
  `feat`, `fix`, `refactor`, `docs`, `test`, `chore` and scope is `ios`, `android`
  or `shared`.
- **CHANGELOG.md**: every user-visible change gets an entry in `[Unreleased]`
  ending with `(Ticket: <ticket-id>)`. This is the source for release notes, so a
  ticket is not finished without it.

## Ticket lifecycle skills

The repo has its own skills for the full loop; prefer them over ad-hoc edits:

`/create-ticket` → `/plan-ticket` → `/implement-ticket` → `/review-code` → `/close-ticket`
