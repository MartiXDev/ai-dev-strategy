# Copilot Baseline Instructions (Plugin-First)

Use `docs/martix-dotnet-ai-skills` as the strategy source of truth for AI customization decisions in this repository.

## 1) Plugin-first policy (collections are excluded)

- Prefer plugins as the primary packaging/distribution unit for reusable AI capabilities.
- Build and compose customizations through instructions, prompts, agents, skills, hooks, and MCP integrations.
- Do **not** introduce or depend on collection-based workflows (`*.collection.yml`) for new work.
- If older collection artifacts are encountered, treat them as legacy references unless migration is explicitly requested.

## 2) Context-window minimization rules

- Keep every task single-purpose and tightly scoped to explicit files/paths.
- Load only the minimum context needed to complete the current task correctly.
- Prefer focused agents/skills/plugins over broad repository reads.
- Avoid large, unrelated file dumps; summarize findings and carry forward only actionable facts.

## 3) Model cost-awareness guidance

- Default to fast/standard models for routine implementation, documentation, and straightforward refactors.
- Use premium models only for high-complexity architecture, security-critical analysis, or deep debugging.
- Escalate model tier only when quality signals indicate it is necessary.
- Keep prompts concise and bounded to reduce token usage and unnecessary model spend.

## 4) Quality gates expectations

- Outputs must satisfy repository standards for correctness, security, consistency, and maintainability.
- Run the smallest relevant validation gates for changed scope (format/lint/build/test/security checks where applicable).
- Do not merge or finalize changes that leave critical quality or security issues unresolved.
- Prefer deterministic checks and hooks for repeatable gate enforcement.

## 5) Scope discipline

- Implement only what is requested by the active task/todo.
- Make the smallest viable change set; avoid opportunistic refactors.
- Do not modify unrelated files, behavior, or architecture.
- If a requested change depends on broader work, clearly report the dependency/blocker instead of silently expanding scope.
