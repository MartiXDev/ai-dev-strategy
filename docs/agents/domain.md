# Domain Docs

How engineering skills should consume this repo's domain documentation.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root
- **`docs/adr/`** for architectural decisions relevant to the topic

If these files are missing in another repo state, proceed silently and do not
block execution.

## Layout for this repository

This repository is **single-context**.

```text
/
├── CONTEXT.md
├── docs/adr/
│   └── 0001-github-native-orchestration-phase-1.md
└── src/
```

## Use glossary vocabulary

When naming domain concepts, use terms from `CONTEXT.md`. Do not drift to
synonyms that the glossary avoids.

## Flag ADR conflicts

If output contradicts an ADR, surface the conflict explicitly instead of
silently overriding it.
