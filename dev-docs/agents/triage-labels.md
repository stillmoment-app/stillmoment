# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles
to the vocabulary actually used in this repo's tracker (`dev-docs/tickets/`).

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this ticket |
| `needs-info`               | `needs-info`         | Waiting on the reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `status: wontfix`    | Will not be actioned — see below         |

## How this coexists with the ticket status

Triage roles and the ticket's frontmatter `status` are **two different axes** and
must not be conflated:

- **Status** answers "how far along is the work?" — `todo`, `in-progress`, `done`,
  `wontfix` (shared tickets per platform, plus `n/a`). It lives only in the
  ticket's YAML frontmatter; `INDEX.md` is generated from it.
- **Triage role** answers "is this ticket ready to be worked, and by whom?" It is
  recorded as a `Triage:` line directly under the ticket's title line, and only on
  tickets that are actually being triaged. Most tickets never need one: a ticket
  created via `/create-ticket` is specified up front and goes straight to TODO.

`wontfix` is the one place the two axes meet. Do **not** add a `Triage: wontfix`
line — the repo already expresses this as `status: wontfix` plus a
`## WONTFIX` section giving the reason. Use the existing convention so there is
one answer, not two.

## GitHub labels

The GitHub repo carries the stock label set (`bug`, `enhancement`, `wontfix`, …),
but it has no issues and none are tracked there — see
`dev-docs/agents/issue-tracker.md`. Those labels are not this table's right-hand
column and should not be applied.
