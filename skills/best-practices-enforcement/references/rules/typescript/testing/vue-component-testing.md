# Vue Component Testing

## 1. Setup
- Use `@vue/test-utils` for mounting components.
- Use `vitest` or `jest` as the test runner.

## 2. Mounting Strategy
- **`mount`**: Renders the full component tree. Use for integration tests.
- **`shallowMount`**: Stubs child components. Use for unit tests focusing on the component in isolation.

## 3. Interaction Testing
- Use `trigger` to simulate DOM events (`click`, `submit`, `input`).
- Await the trigger result (`await wrapper.find('button').trigger('click')`) to ensure DOM updates are processed.

## 4. State Testing
- **Props**: Pass props during mounting (`mount(Comp, { props: { ... } })`).
- **Emits**: Assert emitted events (`expect(wrapper.emitted()).toHaveProperty('submit')`).

## 5. Mocking
- Mock global plugins (Vuex, Router) if not testing them explicitly.
- Mock child components if they are heavy or complex.

```typescript
import { mount } from '@vue/test-utils';
import MyComponent from './MyComponent.vue';

test('emits submit on button click', async () => {
  const wrapper = mount(MyComponent);
  await wrapper.find('button').trigger('click');
  expect(wrapper.emitted('submit')).toBeTruthy();
});
```

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
