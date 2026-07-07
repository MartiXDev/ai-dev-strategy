# Test Prompt 04: Spec-Driven Overnight Feature Implementation

## Prompt ID

`04-spec-driven-feature-overnight`

## Category

Spec-Driven Development, Vertical Slice Architecture, Overnight Automation

## Description

Simulate a real feature delivery workflow where planning artifacts are prepared first and implementation is executed overnight with strict output structure and reusable-pattern alignment.

## Prompt Text

You are implementing a feature in an overnight autonomous run.

Build a C# 14 / .NET 10 Web API feature for **Project Tasks Management** with:

- Task entity: Id, Title, Description, Status, Priority, Assignee, DueDate, CreatedAt, UpdatedAt
- CRUD endpoints + status transitions + query filtering by status/priority/assignee
- Validation and robust error handling
- Vertical slice organization with feature isolation

### Delivery workflow requirements

1. Produce planning artifacts before code:
   - `docs/specification.md`
   - `plans/technical-plan.md`
   - `plans/tasks.md`
2. Then provide implementation artifacts under `code/`.
3. Make implementation traceable to tasks in `plans/tasks.md`.

### Architecture and quality requirements

- Use Fast Endpoints (https://fast-endpoints.com/docs) for feature isolation and consistent request/response handling.
- Organize features as vertical slices with dedicated Endpoint classes per use case.
- Keep feature and shared concerns separated via Fast Endpoints modularity.
- Use async/await, logging, and consistent response patterns through Fast Endpoints middleware and validators.
- Include XML documentation where meaningful.
- Apply nullable reference types.

### Reuse-oriented requirements

When relevant, align with reusable patterns similar to:

- Guards
- Result/response pattern
- Specification-style query composition
- Smart enum for status/priority modeling
- Shared kernel conventions

If a pattern is skipped, explain briefly in docs.

Return all files in multi-file format with explicit file paths.
