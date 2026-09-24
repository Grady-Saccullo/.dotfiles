---
paths: ["**/*.go", "**/go.mod"]
---

# Go conventions

- Standard Go: `gofmt`, `go vet`. No linter exceptions without justification.
- Return errors, never panic. Wrap with context on the way up:
  `fmt.Errorf("repo sync %s: %w", name, err)`.
- Take a `context.Context` for cancellation in handlers and long-running operations.
- Table-driven tests. Name test cases descriptively so a failure reads as a sentence.
- Struct tags only where a boundary needs them (config files, wire formats); do not tag
  internal types speculatively.
