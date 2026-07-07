# Requirement Pack: Expected Output Structure

The generated implementation must follow this output layout inside the active model directory:

- `code/` for C# source artifacts
- `docs/` for design notes, explanations, and non-code documentation
- `plans/` for technical plans and task breakdowns
- `logs/` for runtime capture artifacts only

For code organization, prefer feature-based folders aligned with vertical slice principles:

- `code/Features/<FeatureName>/...`
- `code/Features/Shared/...` only for true cross-cutting concerns
- `code/Program.cs` for app composition

Do not place generated files outside the model directory and do not use repository-root paths.
