---
name: dotnet-api-quality
description: 'Raise ASP.NET Core API quality with validation, ProblemDetails, OpenAPI, robust error handling, and contract consistency.'
---

# .NET API Quality

Use this skill to make ASP.NET Core APIs predictable, documented, and production-ready.

## Focus Areas

### 1) Validation

- Validate body, route, and query inputs consistently.
- Prefer FluentValidation or clear data annotations on request DTOs.
- Return RFC 9457-compatible validation responses (`ValidationProblemDetails`) instead of custom ad-hoc formats.

### 2) Problem Details and Error Handling

- Register and use centralized Problem Details support.
- Use global exception handling middleware/filters to map known exceptions to stable HTTP status codes.
- Ensure unexpected errors return safe, non-sensitive `ProblemDetails` payloads with trace correlation metadata where available.

### 3) OpenAPI Completeness

- Add accurate request/response metadata for each endpoint.
- Document success and error responses (`Produces`, `ProducesProblem`, validation errors).
- Use clear operation names, summaries, and tags so generated docs remain consistent and discoverable.

### 4) Response Consistency

- Keep response shapes stable across endpoints for similar outcomes.
- Use typed results (`TypedResults` / `Results<T...>`) and avoid ambiguous return contracts.
- Standardize pagination, error fields, and common headers across the API surface.

### 5) API Design Hygiene

- Organize endpoints by feature and route group.
- Keep handlers focused on one use case and avoid mixed concerns.
- Apply consistent versioning, naming, and status code semantics.

## Definition of Done

- Inputs are validated consistently.
- Errors are emitted through Problem Details.
- OpenAPI accurately describes behavior and failure modes.
- Endpoint contracts are consistent and predictable for clients.
