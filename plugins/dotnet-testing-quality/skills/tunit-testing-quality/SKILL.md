---
name: tunit-testing-quality
description: TUnit-first testing quality workflow for .NET projects. Use when creating or reviewing tests, enforcing naming patterns, handling integration-test fallback, and applying CI reliability gates.
license: MIT
---

# TUnit Testing Quality

Use this skill to keep .NET test suites fast, deterministic, and maintainable while defaulting to TUnit.

## When to Use

- Adding new unit or component tests in C#/.NET.
- Reviewing pull requests for testing quality.
- Deciding whether integration tests should stay in TUnit or fall back to xUnit.
- Defining CI gates that protect reliability.

## TUnit-First Rules

1. Prefer **TUnit** for all new unit/component tests.
2. Use async TUnit assertions (`await Assert.That(...)`) consistently.
3. Keep tests parallel-safe by default; isolate mutable state per test.
4. Use `[NotInParallel]` only when a shared external resource makes it unavoidable.

### TUnit Naming Pattern

- Test methods should follow: `Should_<ExpectedBehavior>_When_<Condition>()`
- Examples:
  - `Should_CreateUser_When_CommandIsValid()`
  - `Should_ReturnValidationError_When_EmailIsMissing()`

## Integration-Test Fallback Guidance

Use **xUnit fallback** only when integration infrastructure requires it (for example `WebApplicationFactory<TEntryPoint>` or a dependency that is xUnit-bound).

Fallback rules:

1. Keep fallback tests scoped to integration coverage only.
2. Add a reason marker comment in the file header:
   - `// xUnit fallback — reason: WebApplicationFactory integration`
3. Do not convert existing healthy TUnit unit tests to xUnit.
4. Keep naming explicit, using either project-local convention or `MethodName_Condition_ExpectedResult`.

## Reliability Gates (Pre-Merge)

Run all gates before marking testing work complete:

1. **Build Gate**: `dotnet build` succeeds.
2. **TUnit Gate**: TUnit unit/component suite passes.
3. **Integration Gate**: integration fallback tests pass.
4. **Determinism Gate**: no `Thread.Sleep`, no order-dependent tests, no shared mutable fixtures.
5. **Flake Gate**: rerun impacted test set; results must be stable.
6. **Naming Gate**: new tests follow approved naming patterns.

## Minimal Test Quality Checklist

- Test covers happy path + edge/error cases.
- Assertions are specific (no vague "not null only" assertions for critical behavior).
- External dependencies are isolated with test doubles where appropriate.
- Test intent is obvious from method name and setup.
- Failures provide actionable diagnostics.
