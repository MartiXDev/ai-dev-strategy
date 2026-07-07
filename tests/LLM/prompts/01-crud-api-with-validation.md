# Test Prompt 01: CRUD API with Validation

## Prompt ID

`01-crud-api-with-validation`

## Category

Web API, CRUD Operations, Validation

## Description

Generate a complete CRUD Web API for managing Product entities with proper validation, error handling, and best practices.

## Prompt Text

Generate a complete ASP.NET Core Web API controller in C# 14 and .NET 10 for managing Products with the following requirements:

**Entity Requirements:**

- Product entity with these properties:
  - Id (Guid)
  - Name (string, required, max 200 characters)
  - Description (string, optional, max 1000 characters)
  - Price (decimal, required, must be > 0)
  - Category (string, required, max 100 characters)
  - StockQuantity (int, required, must be >= 0)
  - CreatedAt (DateTime, auto-set)
  - UpdatedAt (DateTime, auto-set)

**API Requirements:**

1. Implement full CRUD operations (Create, Read, ReadAll, Update, Delete)
2. Use proper HTTP verbs and status codes
3. Implement input validation using FluentValidation or Data Annotations
4. Use proper async/await patterns
5. Implement global exception handling
6. Use Result/Response pattern for consistent API responses
7. Include XML documentation comments
8. Follow REST best practices
9. Use vertical slice architecture pattern
10. Include proper logging using ILogger
11. Implement proper dependency injection
12. Use nullable reference types correctly
13. Follow latest C# 14 and .NET 10 best practices

**Code Quality Requirements:**

- Clean, readable code with proper naming conventions
- Proper separation of concerns
- No code duplication
- Thread-safe operations
- Performance-optimized
- Security best practices (input sanitization, etc.)

Generate the complete implementation including:

1. Product entity/model
2. DTOs (Create, Update, Response)
3. Validator classes
4. Controller with all CRUD endpoints
5. Response/Result wrapper class
6. Any necessary interfaces

Do not include database implementation (repository/DbContext) - focus on the API layer only.
