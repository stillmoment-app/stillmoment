# Domain Docs

How the engineering skills should consume this repo's domain documentation when
exploring the codebase. This is a **single-context** repo: one domain, two
platform implementations (iOS and Android) that must stay behaviourally identical.

## Before exploring, read these

- **`dev-docs/reference/glossary.md`** — this repo's `CONTEXT.md` equivalent. It
  defines every domain term with its type (Value Object / Enum / Aggregate), its
  sub-domain, and cross-platform file references for both iOS and Android.
- **`dev-docs/architecture/overview.md`** — Clean Architecture + MVVM, and which
  layer owns what. Read it before proposing where new code goes.
- **`dev-docs/architecture/decisions/`** — the ADRs (Michael Nygard format,
  `adr-NNN-<slug>.md`). Read the ones touching the area you're about to work in.
  `README.md` there states when a decision warrants an ADR.

Deeper references, when the topic calls for them:
`dev-docs/architecture/ddd.md` (tactical patterns and the immutability rule),
`audio-system.md`, `timer-state-machine.md`, `dev-docs/reference/color-system.md`.

If a file doesn't exist, **proceed silently**. Don't flag its absence and don't
suggest creating it upfront.

## File structure

```
/
├── CLAUDE.md                              ← product philosophy + hard rules
├── dev-docs/
│   ├── reference/glossary.md              ← the domain glossary (CONTEXT.md role)
│   ├── architecture/
│   │   ├── overview.md
│   │   ├── ddd.md
│   │   └── decisions/                     ← ADRs (adr-001-…, adr-002-…)
│   └── agents/                            ← this directory
├── ios/                                   ← Swift/SwiftUI, ios/CLAUDE.md
└── android/                               ← Kotlin/Compose, android/CLAUDE.md
```

There is no `CONTEXT.md` or `CONTEXT-MAP.md` at the root, and none is needed —
`dev-docs/reference/glossary.md` serves that role. Note that `docs/` at the root is
the **published Jekyll website**, not documentation for agents; it holds HTML only.

## Use the glossary's vocabulary

When your output names a domain concept (a ticket title, a refactor proposal, a
hypothesis, a test name), use the term exactly as `glossary.md` defines it. iOS and
Android deliberately use **identical** terms — a synonym on one platform is a bug
waiting to happen, not a style choice.

If the concept you need isn't in the glossary, that's a signal: either you're
inventing language the project doesn't use (reconsider), or there's a real gap
(note it, and add the entry when the concept lands).

## Before proposing a change, check the platform guide

`ios/CLAUDE.md` and `android/CLAUDE.md` carry the platform-specific patterns, code
examples and forbidden constructs. Read the relevant one before writing code for
that platform — they override generic framework advice.

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than
silently overriding:

> _Contradicts ADR-001 (AudioSessionCoordinator as the one singleton), but worth
> reopening because…_

The same applies to the product philosophy in `CLAUDE.md` — no tracking, no
monetisation, no gamification, simplicity over features. A proposal that violates
one of those needs to say so out loud, not slip through.
