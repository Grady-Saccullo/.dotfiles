---
name: test-quality
description: >
  Use this skill whenever the user asks you to write, review, or fix tests — especially
  when they mention test quality, test design, observable behavior, implementation details,
  black-box testing, or want tests that won't break during refactors. This skill enforces
  a discipline: tests should only control inputs (events, props, context, MSW handlers) and
  only assert on observable outputs (rendered text, accessibility roles, return values,
  navigation URLs). If the user is writing a test file or asking you to review one, use
  this skill. If you're about to write a test that spies on an internal function or asserts
  on state that the user can't see, use this skill first.
---

# Test Quality: Inputs and Outputs Only

Good tests document behavior from the outside. They control exactly what a user or caller can
control, and they assert on exactly what a user or caller can observe. This makes them
resilient to refactors: if you rename a state variable, extract a hook, or swap out an
implementation — tests that only care about visible behavior keep passing.

## The Core Discipline

**Allowed inputs** — things a test may manipulate:
- User interaction events (`fireEvent`, `userEvent.press`, `userEvent.type`, etc.)
- Props passed to the component under test
- Context state, injected via a sibling component (see "State Injection" pattern) or preferably as a `value` prop on the provider
- MSW handler responses (`testState` overrides)
- The passage of time (`jest.useFakeTimers`, `act`)

**Allowed assertions** — things a test may assert on:
- Text visible in the rendered output (`getByText`, `findByText`, `queryByText`)
- Accessibility roles and names (`getByRole`, `findByRole` with `name` option)
- Display values of inputs (`getByDisplayValue`)
- ARIA labels (`getByLabelText`)
- Placeholder text (`getByPlaceholderText`) — only when no better query exists
- Navigation URL (`navigation.currentUrl` from the `render()` result)
- Return values of pure functions or custom hooks
- Whether an element is present or absent after async work settles

## Violations to Flag

When reviewing or writing tests, flag the following patterns and explain why they're
problematic — then suggest a fix.

### 1. Asserting a spy was called instead of observing a side effect

```tsx
// Violation
expect(onSave).toHaveBeenCalledWith({ name: "Alice" });

// Why it's a problem: "onSave was called" is an implementation detail.
// The user can't see whether onSave was invoked — they see what happens after.

// Fix: assert on the visible outcome
await findByText("Saved successfully");
// or assert navigation happened:
await waitFor(() => expect(navigation.currentUrl).toBe("/notes"));
```

**Exception**: spying is acceptable when the side effect is genuinely invisible to the
component tree — e.g., `jest.spyOn(Alert, "alert")` for React Native Alert dialogs that
do not render into the tree, or `jest.spyOn(console, "error")` to suppress noise.
When in doubt, ask: "Could a real user observe this?" If not, use a spy. If yes, assert on what they'd see.

### 2. Using `getByTestId` when a semantic query would work

```tsx
// Violation
fireEvent.press(getByTestId("save-btn"));

// Fix: query by role and name
fireEvent.press(getByRole("button", { name: "Save" }));
```

If there is no accessible role, label, or visible text, it is appropriate to ask the user if they would like for one to be added.

**Exception**: `getByTestId` is acceptable when no accessible role, label, or visible text
is present AND adding one would be semantically wrong. Note the exception with a comment.

### 3. Asserting on component state or refs directly

```tsx
// Violation — internalDraft is private
expect(result.current.internalDraft).toEqual("hello");

// Fix: assert on the observable state exposed through the UI
expect(getByDisplayValue("hello")).toBeTruthy();
```

### 4. Asserting on styles or class names

```tsx
// Violation
expect(getByText("Error")).toHaveStyle({ color: "#FF0000" });

// Fix: assert on the content or accessibility state
expect(getByText("Please fill in this field")).toBeTruthy();
```

### 5. `toBeTruthy()` on a query that already throws on failure

```tsx
// Unnecessary — getBy* throws if absent, so .toBeTruthy() adds no signal
expect(getByText("Hello")).toBeTruthy();

// Fix: the query is the assertion
await findByText("Hello"); // sufficient
```

### 6. `waitFor` + `expect` + `getBy*` when `findBy*` is available

```tsx
// Verbose
await waitFor(() => expect(getByText("Saved")).toBeTruthy());

// Fix
await findByText("Saved");
```

### 7. Asserting navigation via a router mock

```tsx
// Violation
expect(mockNavigate).toHaveBeenCalledWith("/notes/42");

// Why: mockNavigate is an internal detail.
// Fix: use the navigation object from render():
const { navigation } = render(<MyComponent />);
// ... interact ...
await waitFor(() => expect(navigation.currentUrl).toBe("/notes/42"));
```

### 8. Checking internal function calls to verify behavior

```tsx
// Violation — mocking the module prevents real async flow from running
const mockMutate = jest.fn();
jest.mock("../useCreateNote", () => ({ mutate: mockMutate }));
expect(mockMutate).toHaveBeenCalled();

// Fix: let MSW handle the network, assert on what the user sees
await findByText("Note saved");
```

### 9. Mocking a third-party library when the real implementation can run

```tsx
// Violation — replacing a working library with a mock loses real integration coverage
// and creates a maintenance burden: the mock can drift silently from the real API
jest.mock("some-library");

// Why it's a problem: if the library updates its API or behavior, mocked tests
// keep passing while the real app breaks. You're also testing against a fake
// that you wrote — not the code your users will actually run.

// Fix: remove the mock and let the library execute normally.
// If the library produces a side effect you need to control, use a targeted
// alternative: MSW for network calls, jest.useFakeTimers() for time,
// or testState overrides for server responses.
```

**Exception**: mocking is appropriate when a library requires a native runtime unavailable in Jest (e.g., camera, Bluetooth, biometrics) or triggers uncontrollable external side effects that cannot be intercepted another way (e.g., firing real analytics events to a live service). When you do need to mock, mock only the specific export you need — not the entire module.

### 10. render helpers

```tsx

// Violation - creating a render helper in the test that is reused across tests.
const renderComponent = (props = {}) => render(
  <SomeComponent {...props} />
);

it('tests something', () => {
  renderComponent()
})

it('tests something else', () => {
  renderComponent()
})

// Fix: Render components directly in the test. Don't use ad hoc abstractions
it('tests something', () => {
  render(<SomeComponent {...props} />)
})

it('tests something else', () => {
  render(<SomeComponent {...props} />)
})

```

## Query Priority

1. `getByRole` / `findByRole` with `name` — most semantic, survives restructuring
2. `getByLabelText` / `getByDisplayValue` — for form inputs
3. `getByText` / `findByText` — for static content
4. `getByPlaceholderText` — when no label is set
5. `getByTestId` — last resort only

## How to Review a Test File

1. **Identify each assertion** — classify as "observable output" or "implementation detail"
2. **Identify each query** — flag `getByTestId` uses; check if a semantic query exists
3. **Identify each spy/mock** — ask: "Is the side effect invisible to the component tree?"
4. **Flag violations** — quote the exact line, name the pattern, explain the risk
5. **Suggest a fix** — show the corrected code

Be specific: say _why_ a violation would break under a legitimate refactor and what observable
behavior it should assert on instead.

## How to Write a Test

- Start from the user's perspective: "what would a person do, and what would they see?"
- Reach for `findByRole` or `findByText` before anything else
- Only use `jest.fn()` for props the parent component controls (e.g., `onPress`, `onChange`)
- If you want to assert on a mock call, ask: "what does the user see as a result?" Assert on that instead
- Prefer MSW handlers over mocking modules — it keeps more real code running
