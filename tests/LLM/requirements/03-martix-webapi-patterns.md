# Requirement Pack: MartiX.WebApi Pattern Reuse

When applicable, align implementation with reusable MartiX.WebApi patterns:

- Guards (`Guard.Against...`) for input validation and invariants.
- Result/response patterns (`Result`, `Result<T>`, validation result style).
- Specification-oriented query abstractions when query logic grows.
- Smart enum usage for rich domain state values.
- Shared kernel conventions for cross-cutting domain primitives and events.

If a pattern is not used, briefly justify within generated docs/plans artifacts.
Avoid fake dependencies; provide interfaces or extension points where concrete libraries are not available.
