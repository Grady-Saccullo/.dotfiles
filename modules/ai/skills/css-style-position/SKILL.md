---
name: css-style-position
description: Enforces style-vs-position CSS methodology for component-scoped styles. Use when writing, editing, or reviewing CSS/SCSS, component stylesheets, layout, spacing, flex/grid, or when the user mentions style/position separation, portable components, or "The Miseducation of CSS".
---

# CSS Style vs Position

Based on [The Miseducation of CSS](https://365jsthings.tech/blog/the-miseducation-of-css).

## Core rules

1. **Components style themselves; parents position their immediate children.**
2. **Style** = properties affecting the border-box **inward** (padding, border, color, background, typography, `box-sizing`, inner shadows, etc.).
3. **Position** = everything else (margin, width/height, flex/grid on the parent, alignment of children, `position`, `top`/`left`, `z-index`, gap between siblings, etc.).
4. **Do not add layout wrapper components** in HTML/TSX/templates just to arrange children. Put layout on the parent component's stylesheet using direct-child selectors.

## When editing styles

1. Classify each property as **style** or **position** (see [property-reference.md](property-reference.md) if unsure).
2. **Style rules** → on the element/component that owns the appearance (`:host`, root BEM block, or component class).
3. **Position rules** → on the **parent**, targeting **only direct children** with `>`.
4. Prefer `> ` over descendant selectors for layout so nested components stay portable.
5. Remove positioning assumptions from reusable/shared components (margins, `align-self`, expected parent `display`, fixed widths that only make sense in one page).

## Selector pattern

```scss
// Parent component (owns layout)
.card {
  display: flex;
  flex-direction: column;
  gap: 1rem;

  > .card-title {
    // position: how this child sits among siblings
    align-self: start;
    margin: 0;
  }

  > .card-body {
    flex: 1;
  }
}

// Child component (owns appearance only)
.card-title {
  padding: 0.5rem 0;
  font-size: 1.25rem;
  color: var(--text-primary);
  // no margin, no align-self, no width unless intrinsic to the part itself
}
```

## `display` nuance

| Value                                                 | Treat as                | Reason                         |
| ----------------------------------------------------- | ----------------------- | ------------------------------ |
| `flex`, `grid`, `inline-flex`, `inline-grid`          | Style on self           | Lays out **own** children      |
| `block`, `inline`, `inline-block`, `none`, `contents` | Position (parent's job) | Affects sibling flow in parent |

## Angular

- **`:host`** — style the component shell; avoid margins that assume a specific parent layout.
- **`:host > *`** or **`.root-class > .part`** — position immediate children from the host.
- **`::ng-deep`** — use sparingly; when piercing encapsulation for third-party (e.g. Material), still prefer `> ` for children you control.
- **Reusable components** (`app-*`, `ui-*`, shared widgets) must not encode page-specific margins, widths, or alignment.
- **Page/feature components** own layout of their template children.

## Review checklist

Flag and fix:

- [ ] Margin on a reusable component root (`:host` or top-level class)
- [ ] `width` / `max-width` / `min-width` on a shared widget that only fits one screen
- [ ] `align-self`, `justify-self`, or `order` on a child instead of parent flex/grid rules
- [ ] Descendant selectors (`.parent .child`) used for layout where `> .child` suffices
- [ ] Extra wrapper `div`s added only for flex/grid (move rules to parent `> child`)
- [ ] Deep nesting styling grandchildren for spacing the parent should own

## Output when reviewing

```markdown
## Style/position review

### Violations

- `path/file.scss:12` — `margin-bottom` on `.contact-form` (position → move to parent `> .contact-form`)

### OK / intentional

- `.header { display: grid; gap: 1em; }` — flex/grid on self laying out own children

### Suggested fix

[minimal diff or snippet]
```

## Additional resources

- Property classification: [property-reference.md](property-reference.md)
- Before/after patterns: [examples.md](examples.md)
