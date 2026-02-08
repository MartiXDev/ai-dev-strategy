---
description: 'Griffel CSS-in-JS styling rules for Fluent UI v9 — makeStyles, design tokens, Zen Garden separation of content and presentation'
applyTo: '**/*.{ts,tsx}'
---

# Griffel CSS-in-JS + Fluent UI v9

## Core Philosophy — Zen Garden Principle

Separate **content** (semantic HTML, component logic) from **presentation** (styles, themes, visual effects). Components should be fully functional and accessible without any styles applied. Styles are a layer on top — like CSS Zen Garden.

## Griffel `makeStyles()` Rules

### Always Use `makeStyles()`

- **NEVER use inline styles** (`style={{ ... }}`) — they bypass Griffel's atomic CSS optimization.
- **NEVER use CSS modules or external CSS files** — Griffel handles all styling.
- **NEVER use Tailwind, styled-components, or Emotion** — they conflict with Griffel's runtime.

```tsx
// ✅ Correct — Griffel makeStyles
import { makeStyles, tokens } from '@fluentui/react-components';

const useStyles = makeStyles({
  root: {
    display: 'flex',
    flexDirection: 'column',
    gap: tokens.spacingVerticalM,
    padding: tokens.spacingHorizontalL,
  },
  title: {
    fontSize: tokens.fontSizeBase500,
    fontWeight: tokens.fontWeightSemibold,
    color: tokens.colorNeutralForeground1,
  },
});
```

```tsx
// ❌ Wrong — inline styles
<div style={{ display: 'flex', gap: '8px' }}>
```

### Style Naming Convention

- Name style slots after their **semantic role**, not visual appearance:
  - ✅ `root`, `header`, `content`, `actions`, `errorMessage`
  - ❌ `redText`, `bigBox`, `leftColumn`

### `mergeClasses()` for Conditional Styles

- Use `mergeClasses()` to compose Griffel styles — never string concatenation:

```tsx
import { mergeClasses } from '@fluentui/react-components';

const MyComponent: React.FC<Props> = ({ isActive, className }) => {
  const styles = useStyles();
  return (
    <div className={mergeClasses(
      styles.root,
      isActive && styles.active,
      className  // Always forward className prop for composability
    )}>
      {/* ... */}
    </div>
  );
};
```

### Always Forward `className`

- Every component MUST accept and forward a `className` prop to its root element via `mergeClasses()`. This enables parent components to override styles — a key Zen Garden principle.

## Design Tokens

### Always Use Tokens Over Hard-coded Values

- **Colors**: `tokens.colorNeutralForeground1`, `tokens.colorBrandBackground`, etc.
- **Spacing**: `tokens.spacingVerticalS`, `tokens.spacingHorizontalM`, etc.
- **Typography**: `tokens.fontSizeBase300`, `tokens.fontWeightRegular`, etc.
- **Border radius**: `tokens.borderRadiusMedium`, etc.
- **Shadows**: `tokens.shadow4`, `tokens.shadow16`, etc.
- **Duration/easing**: `tokens.durationNormal`, `tokens.curveEasyEase`, etc.

```tsx
// ✅ Correct — design tokens
const useStyles = makeStyles({
  card: {
    backgroundColor: tokens.colorNeutralBackground1,
    borderRadius: tokens.borderRadiusMedium,
    boxShadow: tokens.shadow4,
    padding: tokens.spacingHorizontalL,
  },
});
```

```tsx
// ❌ Wrong — hardcoded values
const useStyles = makeStyles({
  card: {
    backgroundColor: '#ffffff',
    borderRadius: '8px',
    boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
    padding: '16px',
  },
});
```

### Token Hierarchy

1. **Use semantic tokens first** — `colorNeutralForeground1` (adapts to light/dark theme)
2. **Use alias tokens if needed** — `colorBrandBackground` (brand-specific)
3. **NEVER use raw color values** — always go through the token system

## Responsive Design

### Breakpoint Strategy

Use Griffel's media query support inside `makeStyles()`:

```tsx
const useStyles = makeStyles({
  container: {
    display: 'grid',
    gridTemplateColumns: '1fr',
    gap: tokens.spacingHorizontalM,
    '@media (min-width: 640px)': {
      gridTemplateColumns: '1fr 1fr',
    },
    '@media (min-width: 1024px)': {
      gridTemplateColumns: '1fr 1fr 1fr',
    },
  },
});
```

### Standard Breakpoints

Follow these consistent breakpoints throughout the application:

- **Small**: `@media (min-width: 640px)` — tablet portrait
- **Medium**: `@media (min-width: 1024px)` — tablet landscape / small desktop
- **Large**: `@media (min-width: 1440px)` — large desktop

## Component Patterns

### Fluent UI v9 Primitives First

- **Always compose from Fluent UI primitives** before creating custom components:
  - Layout: `<Flex>` (via `makeStyles` flexbox), `<Card>`, `<Divider>`
  - Text: `<Text>`, `<Title1>`–`<Title3>`, `<Subtitle1>`, `<Body1>`, `<Caption1>`
  - Input: `<Input>`, `<Textarea>`, `<Select>`, `<Combobox>`, `<DatePicker>`
  - Feedback: `<Toast>`, `<MessageBar>`, `<Spinner>`, `<ProgressBar>`
  - Navigation: `<TabList>`, `<Breadcrumb>`, `<NavDrawer>`
  - Data: `<DataGrid>`, `<Table>`, `<Tree>`

### Theme Provider

- Wrap the application root with `<FluentProvider>` and a theme:

```tsx
import { FluentProvider, webLightTheme, webDarkTheme } from '@fluentui/react-components';

<FluentProvider theme={prefersDark ? webDarkTheme : webLightTheme}>
  <App />
</FluentProvider>
```

### Custom Theme Tokens

- Extend the theme via `createLightTheme()` / `createDarkTheme()` with brand color ramp — never override CSS variables directly.

## Anti-patterns to Avoid

- ❌ `style={{ ... }}` on any element
- ❌ CSS modules (`*.module.css`), global CSS files, or `<style>` tags
- ❌ Tailwind CSS classes or utility-first CSS frameworks
- ❌ Hardcoded color values, font sizes, or spacing
- ❌ Using `!important` — fix specificity via `mergeClasses()` ordering
- ❌ Creating custom components when a Fluent UI primitive exists
- ❌ `className="some-string"` without going through `makeStyles()` / `mergeClasses()`
