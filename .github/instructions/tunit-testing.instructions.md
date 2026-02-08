---
description: 'TUnit testing conventions — parallel-first, source-generated assertions, modern .NET testing patterns; fallback to xUnit for edge cases'
applyTo: '**/tests/**/*.cs'
---

# TUnit Testing Conventions

## Overview

TUnit is the primary test framework for this project. It is modern, parallel-first, and source-generated — designed for .NET 8+ with better performance and diagnostics than xUnit/NUnit.

Use **xUnit** only as a fallback when TUnit lacks a specific integration (e.g., ASP.NET `WebApplicationFactory` test servers) or when third-party libraries require xUnit.

## Test Structure

### File & Class Naming

- Test files mirror the production code structure under `tests/Features/{Feature}/`.
- Test class name: `{ClassUnderTest}Tests` (e.g., `CreateUserHandlerTests`).
- Test file name matches class name: `CreateUserHandlerTests.cs`.

### Test Method Naming

Use descriptive names with `Should_` prefix:

```csharp
[Test]
public async Task Should_CreateUser_WhenValidCommand()

[Test]
public async Task Should_ReturnNotFound_WhenUserDoesNotExist()

[Test]
public async Task Should_ThrowValidationException_WhenEmailIsEmpty()
```

## TUnit Attributes

### Basic Test

```csharp
using TUnit.Core;

public class UserServiceTests
{
    [Test]
    public async Task Should_ReturnUser_WhenIdExists()
    {
        // Arrange
        var service = new UserService(CreateMockDb());

        // Act
        var result = await service.GetByIdAsync(Guid.Parse("..."));

        // Assert
        await Assert.That(result).IsNotNull();
        await Assert.That(result!.Name).IsEqualTo("Alice");
    }
}
```

### Parameterized Tests with `[Arguments]`

```csharp
[Test]
[Arguments("", false)]
[Arguments("alice@example.com", true)]
[Arguments("not-an-email", false)]
public async Task Should_ValidateEmail(string email, bool expectedValid)
{
    var validator = new CreateUserValidator();
    var result = await validator.ValidateAsync(new CreateUserCommand("Alice", email));

    await Assert.That(result.IsValid).IsEqualTo(expectedValid);
}
```

### Data-Driven Tests with `[MethodDataSource]`

```csharp
[Test]
[MethodDataSource(nameof(GetInvalidCommands))]
public async Task Should_FailValidation_ForInvalidCommands(CreateUserCommand command, string expectedError)
{
    var validator = new CreateUserValidator();
    var result = await validator.ValidateAsync(command);

    await Assert.That(result.IsValid).IsFalse();
    await Assert.That(result.Errors).Contains(e => e.ErrorMessage == expectedError);
}

public static IEnumerable<(CreateUserCommand, string)> GetInvalidCommands()
{
    yield return (new("", "a@b.com"), "Name is required");
    yield return (new("Alice", ""), "Email is required");
}
```

## TUnit Assertions

TUnit uses **source-generated, fluent, and async assertions**:

```csharp
// Equality
await Assert.That(actual).IsEqualTo(expected);
await Assert.That(actual).IsNotEqualTo(other);

// Null checks
await Assert.That(result).IsNull();
await Assert.That(result).IsNotNull();

// Boolean
await Assert.That(condition).IsTrue();
await Assert.That(condition).IsFalse();

// String
await Assert.That(text).Contains("expected");
await Assert.That(text).StartsWith("prefix");
await Assert.That(text).IsEmpty();

// Collections
await Assert.That(list).HasCount(3);
await Assert.That(list).Contains(item);
await Assert.That(list).IsEmpty();

// Exceptions
await Assert.That(() => service.DoSomething()).ThrowsException()
    .OfType<ArgumentException>()
    .WithMessage("Invalid argument");

// Type checking
await Assert.That(result).IsTypeOf<UserResponse>();
```

**Key difference from xUnit**: All TUnit assertions are `await`-based (async). Never use `Assert.Equal()` (xUnit) or `Assert.AreEqual()` (NUnit).

## Lifecycle & Hooks

### Setup and Teardown

```csharp
public class UserServiceTests
{
    private AppDbContext _db = null!;

    [Before(Test)]
    public async Task Setup()
    {
        _db = await CreateTestDbAsync();
    }

    [After(Test)]
    public async Task Teardown()
    {
        await _db.DisposeAsync();
    }
}
```

### Class-Level Hooks

```csharp
[Before(Class)]
public static async Task ClassSetup(ClassHookContext context)
{
    // Runs once before all tests in the class
}

[After(Class)]
public static async Task ClassTeardown(ClassHookContext context)
{
    // Runs once after all tests in the class
}
```

### Assembly-Level Hooks

```csharp
[Before(Assembly)]
public static async Task AssemblySetup(AssemblyHookContext context)
{
    // Runs once before all tests in the assembly
}
```

## Parallelization

TUnit runs tests in **parallel by default** — design tests accordingly:

- **Each test MUST be independent** — no shared mutable state between tests.
- Use `[NotInParallel]` attribute only when tests truly cannot run concurrently (e.g., file system tests, shared database).
- Prefer in-memory databases or per-test database instances over shared test databases.

```csharp
[Test, NotInParallel("DatabaseTests")]
public async Task Should_MigrateDatabase()
{
    // This test needs exclusive database access
}
```

## Test Organization

### Arrange-Act-Assert

Every test follows the AAA pattern with clear section markers:

```csharp
[Test]
public async Task Should_CreateOrder_WithValidItems()
{
    // Arrange
    var service = new OrderService(CreateMockDb());
    var command = new CreateOrderCommand(UserId: testUserId, Items: [item1, item2]);

    // Act
    var result = await service.CreateAsync(command);

    // Assert
    await Assert.That(result.Id).IsNotEqualTo(Guid.Empty);
    await Assert.That(result.Items).HasCount(2);
    await Assert.That(result.Status).IsEqualTo(OrderStatus.Pending);
}
```

### Mocking

- Use **NSubstitute** for mocking (preferred) or **Moq** if already established in the project.
- Mock only external dependencies — never mock the class under test.

## xUnit Fallback

Use xUnit only for:

- `WebApplicationFactory<T>` integration tests (until TUnit has equivalent support)
- Libraries that require xUnit (e.g., certain test infrastructure packages)
- Mark xUnit tests clearly with a comment: `// xUnit fallback — reason: ...`

## Anti-patterns to Avoid

- ❌ `Assert.Equal()` or `Assert.AreEqual()` — use TUnit's `await Assert.That(...).IsEqualTo(...)`
- ❌ Shared mutable state between tests
- ❌ Testing implementation details (private methods, internal state)
- ❌ Tests that depend on execution order
- ❌ Catch-all `try/catch` in tests — let exceptions propagate to TUnit
- ❌ `Thread.Sleep()` — use `Task.Delay()` or better, use assertions with timeouts
