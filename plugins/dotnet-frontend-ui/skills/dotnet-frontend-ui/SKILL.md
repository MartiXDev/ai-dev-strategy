---
name: dotnet-frontend-ui
description: 'Build React UI features with Fluent UI v9 and Griffel using accessible, token-based, and consistency-first component patterns.'
license: MIT
---

# .NET Frontend UI

Use this skill to keep React frontends consistent, accessible, and maintainable when using Fluent UI v9 and Griffel.

## When to Use

- Building new React UI screens or components in .NET frontend projects.
- Refactoring mixed styling approaches to Fluent UI v9 + Griffel.
- Reviewing pull requests for accessibility and visual consistency.
- Standardizing component APIs and layout behavior across teams.

## Core Patterns

### 1) React Component Contracts

- Keep components focused and composable; avoid monolithic UI components.
- Accept and forward `className` to the root element with `mergeClasses(...)`.
- Keep prop names semantic and predictable (`title`, `actions`, `isLoading`, `onSubmit`).
- Ensure all interactive props have keyboard-equivalent behavior.

### 2) Fluent UI v9 First

- Prefer Fluent UI primitives (`Button`, `Input`, `Dialog`, `Card`, `Text`, `DataGrid`) before creating custom wrappers.
- Use design tokens for color, spacing, typography, border radius, and shadows.
- Do not hardcode color or spacing values when a token exists.
- Keep component behavior aligned with Fluent UI defaults unless there is a clear product requirement.

### 3) Griffel Styling Discipline

- Use `makeStyles()` for all component styling.
- Use semantic slot names (`root`, `header`, `content`, `actions`, `errorMessage`).
- Compose class names via `mergeClasses(...)` and avoid string concatenation.
- Avoid inline styles, CSS modules, and global CSS for component-scoped styling.

### 4) Accessibility Expectations

- Use semantic HTML and Fluent components that preserve accessible roles.
- Verify tab order, keyboard navigation, and escape/enter behavior for dialogs and menus.
- Ensure text alternatives (`aria-label`, `aria-labelledby`, helper text) are present where required.
- Keep focus visible and restore focus after dismissing overlays.
- Validate color contrast and avoid conveying state with color alone.

### 5) Component Consistency Rules

- Always implement and test loading, empty, success, and error states.
- Use consistent spacing and typography token scale across pages.
- Keep form validation messaging clear, specific, and screen-reader friendly.
- Reuse established patterns for action placement, status messaging, and page layout.

## Definition of Done

- Uses Fluent UI v9 primitives and token-based styling.
- Uses Griffel `makeStyles` and `mergeClasses` correctly.
- Meets keyboard, labeling, and focus-management accessibility expectations.
- Provides consistent component states and predictable interactions.
