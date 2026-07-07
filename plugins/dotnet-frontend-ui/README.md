# .NET Frontend UI Plugin

Guidance for building React frontends with Fluent UI v9 and Griffel, with strong accessibility expectations and consistent component behavior.

## Installation

```bash
# Using Copilot CLI with your configured marketplace
copilot plugin install dotnet-frontend-ui@<marketplace-name>
```

## What's Included

### Skills

| Skill | Description |
|-------|-------------|
| `dotnet-frontend-ui` | Applies React + Fluent UI v9 + Griffel patterns for accessible, consistent, token-driven UI components. |

## Focus Areas

- **Fluent UI v9 first**: compose with Fluent primitives and design tokens before custom wrappers.
- **Griffel discipline**: use `makeStyles` + `mergeClasses`, semantic slot naming, and no inline styles.
- **Accessibility by default**: keyboard support, visible focus, proper labeling, and robust loading/error states.
- **Component consistency**: shared spacing/typography scale, predictable state handling, and className forwarding.

## License

MIT
