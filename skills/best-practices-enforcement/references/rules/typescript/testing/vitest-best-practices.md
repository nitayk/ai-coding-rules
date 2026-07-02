# Vitest Best Practices

## 1. Structure
- **Describe Blocks**: Use `describe` to group related tests (e.g., per component or function).
- **Test Names**: Use readable sentences for test names (`it('should return null when input is empty', ...)`).

## 2. Mocking
- **vi.fn()**: Use `vi.fn()` for simple function mocks.
- **vi.spyOn()**: Use `vi.spyOn()` to observe existing object methods without replacing them entirely (unless `.mockImplementation` is used).
- **Resetting**: Use `afterEach(() => { vi.clearAllMocks() })` to prevent state leakage between tests.

## 3. Assertions
- Use strict assertions (`expect(a).toBe(b)` for primitives, `expect(obj).toEqual(expected)` for objects).
- Avoid `toBeTruthy()`/`toBeFalsy()` when specific values are expected (e.g., use `toBe(true)`).

## 4. Async Testing
- Always await promises.
- Use `async/await` syntax over `.then()`.
- For timers, use `vi.useFakeTimers()` and `vi.advanceTimersByTime()`.

## 5. Vue Components (if applicable)
- Use `@vue/test-utils`.
- Mount components using `mount` (full) or `shallowMount` (stubbing children).
- Test user interactions (clicks, inputs) using `await trigger()`.

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
