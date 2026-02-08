---
description: 'Rules for vertical slice architecture in .NET 10 — each feature is self-contained in src/Features/{Feature}/'
applyTo: '**/*.cs, **/*.csproj'
---

# Vertical Slice Architecture — .NET 10

## Directory Structure

Organize code by **feature**, not by technical layer. Each feature slice lives under `src/Features/{Feature}/` and contains everything needed for that capability:

```
src/
├── Features/
│   ├── Users/
│   │   ├── UserEndpoints.cs          # Minimal API endpoint definitions
│   │   ├── CreateUser/
│   │   │   ├── CreateUserCommand.cs  # Request/command record
│   │   │   ├── CreateUserHandler.cs  # Business logic handler
│   │   │   ├── CreateUserValidator.cs # FluentValidation rules
│   │   │   └── CreateUserResponse.cs # Response DTO
│   │   ├── GetUser/
│   │   │   ├── GetUserQuery.cs
│   │   │   ├── GetUserHandler.cs
│   │   │   └── GetUserResponse.cs
│   │   ├── Models/
│   │   │   └── User.cs              # Domain entity
│   │   └── UserServiceRegistration.cs # DI registration for this feature
│   ├── Orders/
│   │   └── ...
│   └── Shared/                       # Shared kernel — cross-cutting concerns only
│       ├── Behaviors/
│       │   ├── ValidationBehavior.cs
│       │   └── LoggingBehavior.cs
│       ├── Middleware/
│       └── Extensions/
├── Program.cs
└── appsettings.json
```

## Core Rules

### Feature Isolation

- **Each feature MUST be self-contained** — endpoint, handler, validator, model, and response in one folder.
- **NO cross-feature dependencies** — features must not reference types from other features directly.
- **Shared code goes to `Features/Shared/`** — only truly cross-cutting concerns (validation pipeline, logging, middleware).
- If two features need the same data, use a shared domain event or a query, never a direct reference.

### Minimal Project Count

- **Prefer a single project** (`src/`) for the application code.
- Add separate projects ONLY for clearly independent concerns:
  - `tests/` — test projects (unit, integration, e2e)
  - `src/Infrastructure/` — only if persistence/external service adapters need isolation
- **Do NOT create** projects per feature, per layer (Application, Domain, Infrastructure), or per pattern.

### Endpoint Organization

- Use **Minimal API** with `MapGroup()` to organize endpoints by feature:

```csharp
// src/Features/Users/UserEndpoints.cs
public static class UserEndpoints
{
    public static RouteGroupBuilder MapUserEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/users")
            .WithTags("Users")
            .WithOpenApi();

        group.MapPost("/", CreateUser.Handle)
            .WithName("CreateUser")
            .Produces<CreateUserResponse>(StatusCodes.Status201Created)
            .ProducesValidationProblem();

        group.MapGet("/{id:guid}", GetUser.Handle)
            .WithName("GetUser")
            .Produces<GetUserResponse>();

        return group;
    }
}
```

### Handler Pattern

- Handlers are **static classes with a static `Handle` method** — no unnecessary abstractions.
- Use MediatR ONLY if you need pipeline behaviors (validation, logging); otherwise call handlers directly.
- Keep handlers focused: one handler = one use case.

```csharp
// src/Features/Users/CreateUser/CreateUserHandler.cs
public static class CreateUser
{
    public record Command(string Name, string Email);
    public record Response(Guid Id, string Name);

    public static async Task<IResult> Handle(
        Command command,
        AppDbContext db,
        CancellationToken ct)
    {
        var user = new User { Name = command.Name, Email = command.Email };
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);
        return TypedResults.Created($"/api/users/{user.Id}", new Response(user.Id, user.Name));
    }
}
```

### DI Registration

- Each feature registers its own services in a `{Feature}ServiceRegistration.cs` file:

```csharp
public static class UserServiceRegistration
{
    public static IServiceCollection AddUserFeature(this IServiceCollection services)
    {
        // Register feature-specific services
        return services;
    }
}
```

- `Program.cs` calls each feature's registration method — no giant DI configuration file.

### Validation

- Use **FluentValidation** with validator classes co-located in the feature folder.
- Validation runs as a pipeline behavior or inline in the handler — NOT in the endpoint definition.

### Testing Co-location

- Unit tests mirror the feature structure under `tests/`:

```
tests/
├── Features/
│   ├── Users/
│   │   ├── CreateUser/
│   │   │   └── CreateUserHandlerTests.cs
│   │   └── GetUser/
│   │       └── GetUserHandlerTests.cs
│   └── Orders/
│       └── ...
```

## Anti-patterns to Avoid

- ❌ Creating `Application/`, `Domain/`, `Infrastructure/` projects per Clean Architecture dogma
- ❌ Generic repository wrappers over Entity Framework Core
- ❌ Interfaces for every service when only one implementation exists
- ❌ Shared DTOs across features — each feature defines its own request/response types
- ❌ Fat controllers or God endpoints that handle multiple use cases
- ❌ Feature folders importing types from other feature folders
