# Test Prompt 02: Authentication & Authorization API

## Prompt ID

`02-auth-api`

## Category

Web API, Authentication, Authorization, Security

## Description

Generate a secure authentication API with JWT tokens, role-based authorization, and security best practices.

## Prompt Text

Generate a secure authentication and authorization API in C# 14 and .NET 10 with the following requirements:

**Authentication Requirements:**

1. User registration endpoint
2. User login endpoint (returns JWT token)
3. Token refresh endpoint
4. Password reset request endpoint
5. Email confirmation endpoint

**User Model:**

- Id (Guid)
- Email (string, required, valid email format)
- UserName (string, required, 3-50 characters, alphanumeric)
- PasswordHash (string, hashed using BCrypt or similar)
- Role (enum: User, Admin, Moderator)
- IsEmailConfirmed (bool)
- EmailConfirmationToken (string, nullable)
- PasswordResetToken (string, nullable)
- PasswordResetTokenExpiry (DateTime, nullable)
- CreatedAt (DateTime)
- LastLoginAt (DateTime, nullable)

**DTOs Required:**

- RegisterRequest (Email, UserName, Password, ConfirmPassword)
- LoginRequest (EmailOrUserName, Password)
- LoginResponse (Token, RefreshToken, ExpiresAt, User info)
- RefreshTokenRequest (RefreshToken)
- PasswordResetRequest (Email)
- PasswordResetConfirm (Token, NewPassword, ConfirmPassword)

**Security Requirements:**

1. Use JWT tokens with proper claims (sub, email, role, exp, iat)
2. Implement secure password hashing (BCrypt, Argon2, or PBKDF2)
3. Input validation for all endpoints
4. Rate limiting attributes/filters
5. CORS policy configuration
6. Secure token generation for email confirmation and password reset
7. Token expiration handling
8. Refresh token rotation

**Code Quality:**

- Async/await patterns
- Proper error handling with custom exceptions
- Logging for security events
- XML documentation
- Follow OWASP security guidelines
- Use latest C# 14 and .NET 10 features
- Nullable reference types
- Result/Response pattern

Generate:

1. User entity/model
2. All DTOs
3. JWT configuration class
4. Authentication controller with all endpoints
5. Authorization attribute/filter classes
6. Response wrapper
7. Custom exceptions (InvalidCredentialsException, EmailNotConfirmedException, etc.)
8. Password hasher service interface and implementation
9. Token generator service interface and implementation

Do not include database or email sender implementations - provide interfaces only.
