# Style vs position — examples

## Button in a toolbar

**Before** (button assumes container):

```scss
.app-button {
  margin-right: 8px;
  align-self: center;
}
```

**After**:

```scss
// button.component.scss — style only
.app-button {
  padding: 0.5rem 1rem;
  border-radius: 4px;
  background: var(--btn-bg);
}

// toolbar.component.scss — position children
.toolbar {
  display: flex;
  align-items: center;
  gap: 8px;

  > .app-button {
    // gap handles spacing; no margin on button
  }
}
```

## Card with title and body

**Before** (descendant layout leaks):

```scss
.card {
  .card-title {
    margin-bottom: 12px;
  }
  .card-body {
    flex: 1;
  }
}
```

**After**:

```scss
.card {
  display: flex;
  flex-direction: column;

  > .card-title {
    margin-bottom: 12px;
  }

  > .card-body {
    flex: 1;
  }
}

.card-title {
  font-size: 1.25rem;
  font-weight: 600;
}
```

## Page-specific width on a reusable form

**Before** (from shared form — couples to one layout):

```scss
.contact-form {
  margin-bottom: 60px;
  max-width: 500px;
  min-width: 500px;
}
```

**After**:

```scss
// contact-form.component.scss — appearance
.contact-form {
  padding: 1em 0;
  // typography, borders, internal grid for .header children, etc.
}

// parent drawer/page — position the form in the layout
.side-drawer {
  > .contact-form {
    margin-bottom: 60px;
    max-width: 500px;
    min-width: 500px;
  }
}
```

## Angular host

```scss
:host {
  display: block; // OK: establishes formatting context for projected content
  padding: 1rem; // OK: styles the host box
  // margin: 2rem;  // BAD if this is a shared component
}

:host(.compact) {
  padding: 0.5rem;
}

:host > .actions {
  display: flex;
  gap: 0.5rem;
  justify-content: flex-end;
}
```

## What not to do — layout components

**Avoid** adding HTML only for layout:

```html
<div class="flex-row">
  <app-button />
  <app-button />
</div>
```

**Prefer** semantic structure + parent SCSS:

```html
<footer class="dialog-footer">
  <app-button />
  <app-button />
</footer>
```

```scss
.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;

  > app-button,
  > .app-button {
    // per-child position overrides if needed
  }
}
```
