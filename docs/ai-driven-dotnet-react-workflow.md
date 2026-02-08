# AI-Driven .NET + React Development Workflow

> **Stack**: .NET 10, C# 14, React, Next.js, TypeScript, Fluent UI v9, Griffel CSS-in-JS, TUnit  
> **Architecture**: Vertical slices — `src/Features/{Feature}/` in a single project  
> **Workflow**: SpecKit (daytime planning) → Copilot CLI (overnight automation)  
> **Sources**: Awesome Copilot, Anthropic Skills, OpenAI Skills, GitHub Spec Kit

---

## Step 1: Golden Stack of Instructions (auto-applied to files)

Instructions are automatically applied when editing files of the given type — Copilot loads them on its own.

### Backend (.NET 10 / C# 14) — existing (Awesome Copilot)

| Instruction | `applyTo` | Purpose |
|-------------|-----------|---------|
| `csharp.instructions.md` | `**/*.cs` | C# 14 conventions, pattern matching, nullable |
| `dotnet-architecture-good-practices.instructions.md` | `**/*.cs, **/*.csproj` | DDD, SOLID, Clean Architecture, vertical slices |
| `aspnet-rest-apis.instructions.md` | `**/*.cs, **/*.json` | Minimal API vs Controllers, ASP.NET Core 10 |

### Frontend (React / Next.js / TypeScript / Fluent UI) — existing

| Instruction | `applyTo` | Purpose |
|-------------|-----------|---------|
| `reactjs.instructions.md` | `**/*.jsx, **/*.tsx` | React 19+, hooks, functional components |
| `nextjs.instructions.md` | `**/*.tsx, **/*.ts` | Next.js 16, App Router, `use cache`, PPR |
| `typescript-5-es2022.instructions.md` | `**/*.ts` | TypeScript 5.x, ES modules |

### Cross-cutting — existing

| Instruction | `applyTo` | Purpose |
|-------------|-----------|---------|
| `security-and-owasp.instructions.md` | `*` | OWASP Top 10, all files |
| `performance-optimization.instructions.md` | `*` | Core Web Vitals, .NET perf, DB optimization |
| `object-calisthenics.instructions.md` | `**/*.{cs,ts}` | SOLID on steroids |
| `code-review-generic.instructions.md` | `**` | Priority-based code review (Critical/Important/Suggestion) — 419 lines |
| `self-explanatory-code-commenting.instructions.md` | `**/*.{cs,ts,tsx}` | Clean code commenting standards |
| `playwright-typescript.instructions.md` | `**/e2e/**` | E2E testing conventions (TypeScript) |
| `playwright-dotnet.instructions.md` | `**/tests/**/*.cs` | E2E tests (.NET) — scoped to test projects only |
| `containerization-docker-best-practices.instructions.md` | `**/Dockerfile, **/docker-compose*` | Docker best practices — 682 lines |
| `github-actions-ci-cd-best-practices.instructions.md` | `**/.github/workflows/**` | GitHub Actions CI/CD — 608 lines |

### Custom (to be created — not in workspace)

| Instruction | `applyTo` | Purpose |
|-------------|-----------|---------|
| **`vertical-slice-dotnet.instructions.md`** | `**/*.cs, **/*.csproj` | Rules for `src/Features/{Feature}/` structure: each slice contains endpoint, handler, validator, model, tests; minimal number of projects; no cross-slice dependencies outside shared kernel |
| **`griffel-fluent-ui.instructions.md`** | `**/*.{ts,tsx}` | Extended rules for Griffel `makeStyles()`, `mergeClasses()`, design tokens, responsive breakpoints, Zen Garden principle of separating content and presentation via Fluent UI v9 primitives. **Replaces** `pcf-fluent-modern-theming.instructions.md` (which is PowerApps-specific) |
| **`tunit-testing.instructions.md`** | `**/tests/**/*.cs` | TUnit conventions: `[Test]`, `[Arguments]`, parallel-first, source-generated assertions, `ClassHookContext`, `TestContext`; fallback to xUnit for edge cases |

> **Note**: `pcf-fluent-modern-theming.instructions.md` is excluded — it targets PowerApps Component Framework, not general React + Fluent UI v9. The custom `griffel-fluent-ui.instructions.md` replaces it.

---

## Step 2: Specialized Agents by Task Category

### Existing agents (Awesome Copilot) — to be copied into project

| Category | Agent | File | When to use |
|----------|-------|------|-------------|
| **Architecture** | Senior Cloud Architect | `arch.agent.md` | System design, Mermaid diagrams |
| **Planning** | Implementation Plan | `implementation-plan.agent.md` | Generating deterministic plans |
| **Backend .NET** | C# Expert (.NET 10/C# 14) | `CSharpExpert.agent.md` | All C# code — **direct stack match** |
| **Backend .NET** | Expert .NET SE | `expert-dotnet-software-engineer.agent.md` | Design patterns, SOLID, TDD, performance |
| **Frontend React** | React Expert | `expert-react-frontend-engineer.agent.md` | React 19 + **Fluent UI** + TypeScript — 740 lines |
| **Frontend Next.js** | Next.js Expert | `expert-nextjs-developer.agent.md` | Next.js 16, SSR, routing — 479 lines |
| **TDD Red** | Write failing tests | `tdd-red.agent.md` | Overnight: writing tests first. ⚠️ Ensure `tunit-testing.instructions.md` is loaded alongside — TDD agents default to xUnit/NUnit patterns |
| **TDD Green** | Make tests pass | `tdd-green.agent.md` | Overnight: minimal implementation. ⚠️ Same TUnit compatibility note |
| **TDD Refactor** | Refactor + security | `tdd-refactor.agent.md` | Overnight: code cleanup. ⚠️ Same TUnit compatibility note |
| **E2E Tests** | Playwright Tester | `playwright-tester.agent.md` | Overnight: Playwright E2E tests |
| **Security** | Security Reviewer | `se-security-reviewer.agent.md` | OWASP review, Zero Trust — model: GPT-5 |
| **Code Quality** | Principal SE | `principal-software-engineer.agent.md` | SOLID, clean code, tech debt |
| **Code Quality** | Code Alchemist | `wg-code-alchemist.agent.md` | Clean Code + SOLID refactoring specialist |
| **Accessibility** | Accessibility Expert | `accessibility.agent.md` | WCAG 2.1/2.2, ARIA — 300 lines |
| **DevOps** | DevOps Expert | `devops-expert.agent.md` | CI/CD, Docker, deployment |
| **Debug** | Debug Mode | `debug.agent.md` | Systematic debugging |
| **API** | API Architect | `api-architect.agent.md` | REST API, resilience patterns |
| **Janitor** | C#/.NET Janitor | `csharp-dotnet-janitor.agent.md` | Code modernization, nullable ref types |
| **Modernization** | Modernization Agent | `modernization.agent.md` | Deep-dive code modernization — 581 lines |
| **Tech Debt** | Tech Debt Remediation | `tech-debt-remediation-plan.agent.md` | Generates tech debt remediation plans |

### Custom agents to create

| Agent | Purpose |
|-------|---------|
| **`fullstack-dotnet-react.agent.md`** | Composite agent for daily work — combines CSharpExpert + ReactExpert + vertical slice rules |
| **`overnight-orchestrator.agent.md`** | Agent for dispatching tasks from tasks.md — parses categories, selects the right agent |

---

## Step 3: Skills and Collections

### Existing skills to use

| Skill | Source | Purpose |
|-------|--------|---------|
| **NuGet Manager** | Awesome Copilot | Safe NuGet package management |
| **Refactor** | Awesome Copilot | Surgical refactoring — 646 lines |
| **Web Design Reviewer** | Awesome Copilot | Visual inspection, React, Next.js, SPA |
| **Web App Testing** | Awesome Copilot | Playwright-based webapp testing |
| **Playwright CLI** | OpenAI Skills | CLI-first Playwright automation |
| **Security Best Practices** | OpenAI Skills | Language-specific security reviews |
| **Web App Testing** | Anthropic Skills | Playwright testing + server lifecycle |

> **Note**: Anthropic `Frontend Design` skill is excluded — it uses Tailwind + shadcn/ui which directly conflicts with the Griffel/Fluent UI v9 stack.

### Relevant collections (Awesome Copilot)

| Collection | Contents |
|------------|----------|
| `csharp-dotnet-development.collection.yml` | All .NET resources |
| `frontend-web-dev.collection.yml` | All frontend resources |
| `testing-automation.collection.yml` | TDD agents + Playwright |
| `software-engineering-team.collection.yml` | 7 agents covering the full SDLC |
| `security-best-practices.collection.yml` | Security + quality |
| `project-planning.collection.yml` | Planning workflow |

### Custom collection to create

**`dotnet-react-fullstack.collection.yml`** — bundles all selected resources for the stack into a single collection. Should include:

- All agents and instructions listed in Steps 1-2
- Prompts: `csharp-async.prompt.md`, `dotnet-best-practices.prompt.md`, `ef-core.prompt.md`, `conventional-commit.prompt.md`, `csharp-xunit.prompt.md`, `javascript-typescript-jest.prompt.md`, `playwright-generate-test.prompt.md`
- Skills: NuGet Manager, Refactor, Web Design Reviewer, Web App Testing

---

## Step 4: Daytime Planning Workflow

### Core principle: 1 Feature = 1 Branch = 1 Worktree

Every overnight run processes **one feature** — defined by a single PRD/spec created during the day. The feature contains **multiple tasks** (T001–T00N) that are all implemented within the same feature branch and worktree.

**Guarded parallelism for [P] tasks** is optional and conservative. Parallel execution only happens when tasks are explicitly marked `[P]`, pass the guard rules, and fit within the configured concurrency limits. For higher-risk tasks, the runner can use **task branches** (created inside the feature worktree) to isolate changes without introducing extra worktrees.

```
PRD / User Story
 └── /speckit.specify → specs/NNN-feature/spec.md + git branch feature/NNN-feature
      └── /speckit.plan → specs/NNN-feature/plan.md
           └── /speckit.tasks → specs/NNN-feature/tasks.md (T001..T008)
                └── Overnight runner picks up the feature branch
                     └── git worktree add .worktrees/overnight-NNN-feature feature/NNN-feature
                          └── Iterates all tasks T001..T008 inside this single worktree
```

### Daytime workflow

**Morning / during the day** — interactive with premium AI:

```
Copilot CLI (interactive mode, --model claude-sonnet-4-5 or gpt-5)
├── 1. /speckit.specify  → Spec feature → specs/NNN-feature/spec.md
│                          ↳ Auto-creates branch: feature/NNN-feature (worktree is created by overnight runner)
├── 2. /speckit.plan     → Technical plan → specs/NNN-feature/plan.md
├── 3. /speckit.tasks    → Tasks → specs/NNN-feature/tasks.md (multiple tasks per feature)
├── 4. /speckit.clarify  → Clarify ambiguities (optional)
├── 5. /speckit.analyze  → Consistency check (optional)
├── 6. Review + approve  → Manual review of tasks.md + add [CATEGORY] tags
└── 7. Push spec artifacts to feature branch + register in overnight-config.json
```

### Evening handoff — registering features for overnight run

Before leaving for the day, register the planned feature(s) in `overnight-config.json`:

```powershell
# Example: register a single feature for tonight's run
$config = Get-Content overnight-config.json | ConvertFrom-Json
$config.features = @(
  @{
    specDir = "specs/001-user-profile"
    branch  = "feature/001-user-profile"
  }
)
$config | ConvertTo-Json -Depth 10 | Set-Content overnight-config.json

# Then kick off the runner (or schedule via Task Scheduler / cron)
.\scripts\Invoke-OvernightRun.ps1
```

Multiple features can be queued — the runner processes them sequentially (one worktree at a time) or in parallel (separate worktrees, if `parallelFeatures: true` in config).

### Extended tasks.md format (custom convention on top of SpecKit)

Add a **task category** to each task ID:

```markdown
## Phase 2 — Foundational

- [ ] [T001] [BACKEND] Create UserFeature slice in src/Features/Users/
- [ ] [T002] [BACKEND] Implement UserEndpoints in src/Features/Users/UserEndpoints.cs

## Phase 3 — US1: User Profile

- [ ] [T003] [P] [TEST-UNIT] [US1] Add UserService tests in tests/Features/Users/UserServiceTests.cs
- [ ] [T004] [P] [FRONTEND] [US1] Create UserProfile component in src/app/users/UserProfile.tsx
- [ ] [T005] [BACKEND] [US1] Implement UserService in src/Features/Users/UserService.cs

## Phase 4 — Polish

- [ ] [T006] [TEST-E2E] Playwright user flow test in e2e/users.spec.ts
- [ ] [T007] [SECURITY] Security review of auth endpoints
- [ ] [T008] [A11Y] Accessibility audit of UserProfile
```

**Supported categories:**

- `[BACKEND]` — C# / .NET code
- `[FRONTEND]` — React / Next.js / TypeScript / Fluent UI
- `[FULLSTACK]` — Tasks spanning both backend and frontend (see splitting rules below)
- `[TEST-UNIT]` — Unit tests (TUnit / xUnit)
- `[TEST-INTEG]` — Integration tests
- `[TEST-E2E]` — Playwright E2E tests
- `[SECURITY]` — Security review
- `[A11Y]` — Accessibility audit
- `[DEVOPS]` — CI/CD, Docker, deployment
- `[DOCS]` — Documentation

### Guarded parallelism for `[P]` tasks

Only tasks explicitly marked `[P]` are eligible for parallel execution, and only under these guardrails:

- Tasks must be in the **same phase** and **non-overlapping** in scope (no shared files or directories).
- The runner enforces `maxParallelTasks` and queues anything beyond that limit.
- If guard rules cannot prove isolation, the task runs sequentially.

Use `[P]` for independent work (e.g., a frontend component and a unit test file) and avoid `[P]` on shared backend slices or cross-cutting refactors.

**Strict category + path matrix (recommended)**

When `parallelTaskGuard` is set to `category-path-matrix`, tasks must include a path hint and pass both category compatibility and path isolation checks.

Add path hints with a `[PATH:...]` tag (multiple paths allowed, comma-separated):

```
- [ ] [T003] [P] [FRONTEND] [PATH:src/app/features/users] Create UserProfile component
- [ ] [T004] [P] [TEST-UNIT] [PATH:tests/Features/Users] Add UserService tests
```

Helper script to auto-append PATH hints based on conventions:

```powershell
.\scripts\Add-PathHints.ps1 -TasksFile "specs/001-user-profile/tasks.md"
```

### Optional task branches for isolation

For risky or invasive tasks, the runner can create a **task branch inside the feature worktree**:

- Branch name pattern: `task/{featureId}-{taskId}-{slug}`
- Merge strategy: `squash` (default) or `merge`
- Cleanup: delete task branch after merge if `taskBranchCleanup` is enabled

### Handling `[FULLSTACK]` tasks

Tasks that span both backend and frontend (e.g., "Add user avatar upload with React component + .NET endpoint") should be **split** during planning into separate `[BACKEND]` and `[FRONTEND]` tasks with explicit dependencies. If a task cannot be cleanly split, mark it `[FULLSTACK]` — the overnight runner dispatches it to the `fullstack-dotnet-react` composite agent.

### API contract strategy

The React frontend and .NET backend share types via **OpenAPI spec generation**:

1. .NET endpoints generate OpenAPI spec automatically (via Minimal API + `Microsoft.AspNetCore.OpenApi`)
2. TypeScript client is generated from the spec using `openapi-typescript` or `NSwag`
3. The `aspnet-minimal-api-openapi.prompt.md` and `openapi-to-application-csharp-dotnet.collection.yml` support this workflow

This ensures type safety across the stack boundary without manual duplication.

---

## Step 5: Overnight Orchestration Script

### Git worktree strategy

Each overnight feature run operates in an **isolated git worktree** — one worktree per feature. A feature contains multiple tasks (T001–T00N) that are all executed within this single worktree.

```
project-root/                          ← main working tree (daytime work)
├── .worktrees/
│   ├── overnight-001-user-profile/    ← worktree for feature 001 (tasks T001–T008)
│   ├── overnight-002-order-flow/      ← worktree for feature 002 (tasks T009–T015)
│   └── ...
├── specs/
│   ├── 001-user-profile/              ← spec, plan, tasks for feature 001
│   │   ├── spec.md
│   │   ├── plan.md
│   │   └── tasks.md                   ← T001–T008 with [CATEGORY] tags
│   └── 002-order-flow/
│       └── ...
```

**Lifecycle** (for each feature registered in `overnight-config.json`):

```powershell
# 1. Create worktree from feature branch (branch was created during /speckit.specify)
$feature = $config.features[0]
$worktreePath = Join-Path $config.worktreeDir "overnight-$($feature.branch -replace 'feature/','')"
git worktree add $worktreePath $feature.branch

# 2. Copy spec artifacts into worktree (they exist on the feature branch already)
Push-Location $worktreePath

# 3. Runner iterates ALL tasks in specs/NNN/tasks.md inside this worktree
#    Task T001, T002, ... T008 — each dispatched to the right agent
#    All copilot -p calls execute with cwd = worktree path
#    If task branches are enabled, each task can run inside a short-lived task branch

# 4. After each completed phase — commit progress
git add -A
git commit -m "chore(overnight): complete Phase 2 — Foundational [T001-T002]"

# 5. After all tasks complete — push and create draft PR
git push origin $feature.branch
gh pr create --draft `
  --title "feat: $($feature.branch -replace 'feature/','') (overnight)" `
  --body (Get-Content "morning-report.md" -Raw)

Pop-Location

# 6. Morning cleanup — remove worktree after review
git worktree remove $worktreePath
```

**Key constraints:**

- **1 worktree = 1 feature = 1 branch** — never mix tasks from different features
- All tasks (T001–T00N) for a feature run sequentially within the same worktree unless `[P]` guarded parallelism is enabled
- Daytime work on `main` or other branches is never affected
- Multiple features can run overnight in parallel (separate worktrees, if `parallelFeatures: true`)
- Failed runs can be discarded entirely (`git worktree remove --force`)
- Morning review via draft PR with full diff visibility

**Commit strategy:**

- Commit after each **completed phase** (not after every task — too noisy)
- Use conventional commit format: `chore(overnight): complete Phase N — description [T001-T005]`
- Push only after the final phase or when all tasks complete
- Create a **draft PR** — never merge automatically

### Architecture

```
scripts/Invoke-OvernightRun.ps1
├── Reads overnight-config.json → gets feature list + settings
├── For each feature in config.features:
│   ├── Creates git worktree from feature.branch
│   ├── Reads feature.specDir/tasks.md → extracts incomplete tasks with categories
│   ├── Maps categories to agents/models (see table below)
│   ├── Respects phases (Setup → Foundational → Stories → Polish)
│   ├── Evaluates [P] markers for guarded parallel execution (or runs sequentially if disabled)
│   ├── For each task (T001..T00N):
│   │   ├── Loads agent instructions file + calls copilot -p
│   │   └── Build gate: runs dotnet build + dotnet test
│   ├── On failure: logs error, retries once, then skips
│   ├── Commits after each completed phase
│   ├── Updates tasks.md (- [ ] → - [X])
│   ├── Pushes branch + creates draft PR
│   └── Generates morning-report.md for this feature
└── Generates consolidated morning-report.md (all features)
```

### Build validation gates

After **every task** (not just at phase boundaries), the runner executes:

```powershell
# Backend validation
dotnet build --no-incremental 2>&1 | Tee-Object -FilePath "logs/$taskId-build.log"
dotnet test --no-build 2>&1 | Tee-Object -FilePath "logs/$taskId-test.log"

# Frontend validation (if frontend files changed)
npm run build 2>&1 | Tee-Object -FilePath "logs/$taskId-frontend-build.log"
npm run lint 2>&1 | Tee-Object -FilePath "logs/$taskId-lint.log"
```

If build fails after a task, the runner:

1. Logs the failure with full output
2. Attempts a **single retry** with the same model (transient error recovery)
3. If retry fails, reverts the task's changes when `revertOnFailure` is enabled (`git restore .`) and marks it as failed
4. Continues with the next task

### Timeout, budget, and rate limits

| Setting | Default | Description |
|---------|---------|-------------|
| `taskTimeoutMinutes` | `10` | Max duration per task — hanging tasks are killed |
| `phaseTimeoutMinutes` | `45` | Max duration per phase |
| `totalBudgetDollars` | `5.00` | Total overnight spend cap — runner stops when exceeded |
| `maxPremiumRequests` | `100` | Max Copilot premium requests — prevents quota exhaustion |
| `retryOnFailure` | `true` | Retry failed tasks once before skipping |
| `retryWithBetterModel` | `false` | On second failure, retry with daytime (premium) model |
| `parallelTasksEnabled` | `false` | Enables guarded parallel execution for `[P]` tasks |
| `maxParallelTasks` | `2` | Maximum concurrent `[P]` tasks per phase |
| `parallelTaskGuard` | `category` | Guard strategy: `category`, `path-locks`, or `category-path-matrix` |
| `taskBranchesEnabled` | `false` | Use per-task branches inside feature worktree |
| `taskBranchPrefix` | `task/` | Prefix for task branch names |
| `taskBranchMergeStrategy` | `squash` | `squash` or `merge` into feature branch |
| `taskBranchCleanup` | `true` | Delete task branches after merge |
| `parallelTaskMatrix` | `{...}` | Allowed category pairs + path roots (strict guard) |
| `modelMultipliers` | `{ "gpt-4.1-mini": 0.25, "claude-sonnet": 1, ... }` | Cost tracking per model |

These settings live in `overnight-config.json` (see Step 7).

### Category-to-agent-and-model mapping

In Copilot CLI programmatic mode, agents are invoked by loading their instructions file via custom instructions, not via an `--agent` flag. The overnight runner constructs each call by pointing to the agent's `.md` file:

| Category | Agent instructions file | Overnight model | Daytime model |
|----------|------------------------|-----------------|---------------|
| `[BACKEND]` | `.github/agents/CSharpExpert.agent.md` | `gpt-4.1-mini` | `claude-sonnet-4-5` |
| `[FRONTEND]` | `.github/agents/expert-react-frontend-engineer.agent.md` | `gpt-4.1-mini` | `claude-sonnet-4-5` |
| `[FULLSTACK]` | `.github/agents/fullstack-dotnet-react.agent.md` | `gpt-4.1-mini` | `claude-sonnet-4-5` |
| `[TEST-UNIT]` | `.github/agents/tdd-red.agent.md` → `tdd-green.agent.md` | `gpt-4.1-mini` | `gpt-5` |
| `[TEST-E2E]` | `.github/agents/playwright-tester.agent.md` | `gpt-4.1-mini` | `gpt-5` |
| `[SECURITY]` | `.github/agents/se-security-reviewer.agent.md` | `claude-sonnet` | `gpt-5` |
| `[A11Y]` | `.github/agents/accessibility.agent.md` | `gpt-4.1-mini` | `gpt-5` |
| `[DEVOPS]` | `.github/agents/devops-expert.agent.md` | `gpt-4.1-mini` | `claude-sonnet-4-5` |
| `[DOCS]` | `.github/agents/se-technical-writer.agent.md` | `gpt-4.1-mini` | `gpt-4.1` |

### Example Copilot CLI call (programmatic mode)

```powershell
# Individual task — agent loaded via custom instructions
copilot -p "You are the CSharpExpert agent. Read specs/001-user-profile/tasks.md task T001. Follow plan.md. Implement the task. Run build and tests after." `
  --model gpt-4.1-mini `
  --custom-instructions .github/agents/CSharpExpert.agent.md `
  --allow-all-tools `
  --deny-tool 'shell(git push)' `
  --deny-tool 'shell(rm)' `
  --deny-tool 'shell(curl)' `
  --deny-tool 'shell(wget)'

# Fallback to Codex CLI
codex --quiet --model gpt-4.1-mini --approval-mode full-auto `
  "Implement task T001 from specs/001-user-profile/tasks.md following plan.md"
```

> **Note on `--deny-tool`**: Use `'shell(rm)'` (not `'shell(rm -rf)'`) to block all `rm` variants. Also deny `shell(curl)` and `shell(wget)` to prevent data exfiltration during unattended overnight runs.

### Hooks (automatic validation)

Use Copilot CLI hooks for automatic build/test execution after every file change:

```json
// .copilot/hooks/post-file-edit.json
{
  "command": "dotnet build && dotnet test --no-build",
  "on": "file-edit",
  "pattern": "**/*.cs"
}
```

---

## Step 6: Morning Review — Morning Report

Script `scripts/New-MorningReport.ps1` generates:

```markdown
# Morning Report — 2026-02-09

## Summary
- Tasks completed: 5/8
- Tasks failed: 2 (T005, T007)
- Tasks skipped: 1 (T008 — depends on T007)
- Build status: ✅ passing
- Test coverage: 87% (+3%)
- Security issues: 0 critical, 1 medium
- Draft PR: https://github.com/org/repo/pull/42

## Git Changes
- Files changed: 23
- Lines added: +847
- Lines removed: -12
- Commits: 3 (Phase 2, Phase 3, Phase 4 partial)

## Completed ✅
- [x] T001 [BACKEND] UserFeature slice — build ✅, 12 tests pass
- [x] T002 [BACKEND] UserEndpoints — build ✅, 8 tests pass
- [x] T003 [TEST-UNIT] UserService tests — 15 tests written, all red ✅
- [x] T004 [FRONTEND] UserProfile component — build ✅, lint ✅
- [x] T006 [TEST-E2E] Playwright tests — 3 scenarios pass

## Failed ❌
- [ ] T005 [BACKEND] UserService — ❌ Build error: missing dependency
  - Log: logs/T005.log
  - Retried: 1x (same error)
  - Suggestion: Add FluentValidation NuGet package
- [ ] T007 [SECURITY] — ⚠️ Rate limit hit after 2 retries
  - Retry during day with premium model

## Skipped ⏭️
- [ ] T008 [A11Y] — Depends on T007 (security review)

## Budget & Metrics
- Total Copilot CLI calls: 12
- Average task duration: 4m 32s
- Models used: gpt-4.1-mini (10x), claude-sonnet (2x)
- Premium requests consumed: 14 / 100 budget
- Estimated cost: ~$0.85 / $5.00 budget
- Total runtime: 38m 15s
```

---

## Step 7: Files to Create (summary)

### Instructions (custom)

| File | Type | Purpose |
|------|------|---------|
| `vertical-slice-dotnet.instructions.md` | Instruction | Features/ architecture for .NET 10 |
| `griffel-fluent-ui.instructions.md` | Instruction | Griffel CSS-in-JS + Zen Garden principles (replaces PCF instruction) |
| `tunit-testing.instructions.md` | Instruction | TUnit conventions (primary), xUnit (fallback) |

### Agents (custom)

| File | Type | Purpose |
|------|------|---------|
| `fullstack-dotnet-react.agent.md` | Agent | Composite agent for daily work + `[FULLSTACK]` tasks |
| `overnight-orchestrator.agent.md` | Agent | Task dispatch from tasks.md |

### Scripts

| File | Type | Purpose |
|------|------|---------|
| `scripts/Invoke-OvernightRun.ps1` | PowerShell 7+ | Overnight run orchestrator (worktree + task dispatch + build gates) |
| `scripts/Add-PathHints.ps1` | PowerShell 7+ | Auto-append `[PATH:...]` hints in tasks.md |
| `scripts/ConvertFrom-TasksFile.ps1` | PowerShell 7+ | Parser tasks.md → structured data |
| `scripts/New-MorningReport.ps1` | PowerShell 7+ | Morning report generator |
| `scripts/Register-Feature.ps1` | PowerShell 7+ | Helper to add a feature to overnight-config.json |

### Configuration

| File | Type | Purpose |
|------|------|---------|
| `overnight-config.json` | JSON | Timeout, budget, rate limits, model mapping, retry policy |

Example `overnight-config.json`:

```json
{
  "features": [
    {
      "specDir": "specs/001-user-profile",
      "branch": "feature/001-user-profile"
    }
  ],
  "parallelFeatures": false,
  "parallelTasksEnabled": false,
  "maxParallelTasks": 2,
  "parallelTaskGuard": "category-path-matrix",
  "parallelTaskMatrix": {
    "BACKEND": {
      "allowedCategories": ["TEST-UNIT", "DOCS"],
      "pathRoots": ["src/Features", "src/Infrastructure", "src/Shared"]
    },
    "FRONTEND": {
      "allowedCategories": ["TEST-UNIT", "DOCS"],
      "pathRoots": ["src/app", "src/components"]
    },
    "TEST-UNIT": {
      "allowedCategories": ["BACKEND", "FRONTEND"],
      "pathRoots": ["tests/Features", "tests/Unit"]
    },
    "DOCS": {
      "allowedCategories": ["BACKEND", "FRONTEND"],
      "pathRoots": ["docs", "README.md"]
    }
  },
  "taskBranchesEnabled": false,
  "taskBranchPrefix": "task/",
  "taskBranchMergeStrategy": "squash",
  "taskBranchCleanup": true,
  "taskTimeoutMinutes": 10,
  "phaseTimeoutMinutes": 45,
  "totalBudgetDollars": 5.00,
  "maxPremiumRequests": 100,
  "retryOnFailure": true,
  "retryWithBetterModel": false,
  "worktreeDir": ".worktrees",
  "logsDir": "logs",
  "createDraftPR": true,
  "commitAfterPhase": true,
  "denyTools": ["shell(rm)", "shell(curl)", "shell(wget)", "shell(git push)"],
  "categoryMapping": {
    "BACKEND": {
      "agent": ".github/agents/CSharpExpert.agent.md",
      "overnightModel": "gpt-4.1-mini",
      "daytimeModel": "claude-sonnet-4-5"
    },
    "FRONTEND": {
      "agent": ".github/agents/expert-react-frontend-engineer.agent.md",
      "overnightModel": "gpt-4.1-mini",
      "daytimeModel": "claude-sonnet-4-5"
    },
    "FULLSTACK": {
      "agent": ".github/agents/fullstack-dotnet-react.agent.md",
      "overnightModel": "gpt-4.1-mini",
      "daytimeModel": "claude-sonnet-4-5"
    },
    "TEST-UNIT": {
      "agent": ".github/agents/tdd-red.agent.md",
      "overnightModel": "gpt-4.1-mini",
      "daytimeModel": "gpt-5"
    },
    "TEST-E2E": {
      "agent": ".github/agents/playwright-tester.agent.md",
      "overnightModel": "gpt-4.1-mini",
      "daytimeModel": "gpt-5"
    },
    "SECURITY": {
      "agent": ".github/agents/se-security-reviewer.agent.md",
      "overnightModel": "claude-sonnet",
      "daytimeModel": "gpt-5"
    },
    "A11Y": {
      "agent": ".github/agents/accessibility.agent.md",
      "overnightModel": "gpt-4.1-mini",
      "daytimeModel": "gpt-5"
    },
    "DEVOPS": {
      "agent": ".github/agents/devops-expert.agent.md",
      "overnightModel": "gpt-4.1-mini",
      "daytimeModel": "claude-sonnet-4-5"
    },
    "DOCS": {
      "agent": ".github/agents/se-technical-writer.agent.md",
      "overnightModel": "gpt-4.1-mini",
      "daytimeModel": "gpt-4.1"
    }
  },
  "modelMultipliers": {
    "gpt-4.1-mini": 0.25,
    "gpt-4.1": 1,
    "gpt-5": 2,
    "claude-sonnet": 1,
    "claude-sonnet-4-5": 1
  }
}
```

### Collection

| File | Type | Purpose |
|------|------|---------|
| `dotnet-react-fullstack.collection.yml` | Collection | Bundle of all resources for the full stack |

---

## Key Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| **Workflow engine** | SpecKit (over Structured Autonomy) | More structured templates, dependency tracking, phasing |
| **CLI engine** | Copilot CLI (primary), Codex CLI (fallback) | Programmatic mode, custom instructions, hooks, model selection |
| **Architecture** | Features/ (1 project) vertical slices | Minimal number of `.csproj` files, feature isolation |
| **CSS approach** | Griffel CSS-in-JS (Fluent UI v9) | Zen Garden principle via design tokens + `makeStyles()` |
| **Test framework** | TUnit (primary), xUnit (fallback) | Modern, parallel-first, source-generated |
| **Task categorization** | Custom `[CATEGORY]` tags in tasks.md | Dispatch to specialized agents |
| **Model tiering** | Expensive LLM (day) → cheap (night) | Cost optimization, plan=quality, implement=speed |
| **Git strategy** | 1 feature = 1 branch = 1 worktree | Isolation from daytime work, parallel overnight runs, clean discard |
| **Parallelism** | Guarded `[P]` tasks only | Prevent file collisions, retain deterministic builds |
| **Task isolation** | Optional task branches | Safe rollback for risky tasks without extra worktrees |
| **API contracts** | OpenAPI spec generation → TypeScript client | Type safety across stack boundary without manual duplication |
| **Overnight safety** | Budget caps + timeouts + deny-tool | Prevent runaway costs, exfiltration, and destructive commands |
| **Scripting** | PowerShell 7+ (Windows 11) | Native Windows dev machine, cross-platform via pwsh |

---

## Validation Checklist

- [ ] Install Copilot CLI and Codex CLI
- [ ] Run `specify init . --ai copilot` in target project
- [ ] Copy selected instructions to `.github/instructions/`
- [ ] Copy selected agents to `.github/agents/`
- [ ] Create 3 custom instructions (vertical slices, Griffel, TUnit)
- [ ] Create 2 custom agents (fullstack, orchestrator)
- [ ] Create `overnight-config.json`
- [ ] Create orchestration scripts
- [ ] Open `.cs` and `.tsx` files → verify instruction loading
- [ ] Verify `playwright-dotnet.instructions.md` does NOT apply to non-test `.cs` files
- [ ] Test: `copilot` interactive → `@CSharpExpert` on a sample task
- [ ] Test: SpecKit E2E cycle on a single feature
- [ ] Test: `git worktree add` → verify isolated workspace for one feature
- [ ] Test: `Register-Feature.ps1` → verify feature added to overnight-config.json
- [ ] Test: `Invoke-OvernightRun.ps1 -DryRun` → verify all tasks for feature are discovered
- [ ] Test: Overnight run on a single feature with 3-5 tasks
- [ ] Test: `[P]` tasks obey `maxParallelTasks` and guard rules
- [ ] Test: task branch creation/merge when `taskBranchesEnabled: true`
- [ ] Verify draft PR creation and morning-report.md
- [ ] Verify model tiering (billing/usage)
- [ ] Verify budget cap and timeout enforcement
