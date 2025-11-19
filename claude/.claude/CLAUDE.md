# CLAUDE.md - v1.1

## Important rules

1. Always mention at start/load that you loaded this file. Do so by
   mentioning path and version number.
2. Be extremely concise. Sacrifice grammar for the sake of concision.

## Coding Conventions

## Project Setup

### Package Manager

- **Use `bun` instead of `npm`** for all package management
- default to using `bun run test` instead of `bun test`

## General Style

### Functional Programming

- **Always use functional programming style** - no classes
- Use pure functions where possible
- Avoid side effects when practical
- Compose small, reusable functions

### Type Safety

- Always use TypeScript types
- **Never use `any`** - use `unknown` or proper types instead
- **Prefer `type` over `interface`**
- Prefer type inference where types are obvious
- Use explicit types for function parameters and return values

### Naming Conventions

- **Minimum 3 characters** for variable names
- Use clear, meaningful, descriptive names
- Avoid abbreviations unless universally understood
- Use camelCase for variables and functions
- Use PascalCase for types and components
- **Use kebab-case for file names** (e.g., `use-safe-action.ts`, `error-handler.ts`)

Examples:

```typescript
// Good
const userId = 123;
const errorMessage = "Failed to load";
const fetchUserData = async () => {};

// Bad
const id = 123; // too short
const msg = "Failed to load"; // abbreviation
const usr = 123; // unclear
```

### Variable Declarations

- **Prefer `const` over `let`**
- Only use `let` when reassignment is necessary
- Never use `var`

```typescript
// Good
const maxRetries = 3;
let currentAttempt = 0; // needs reassignment

// Bad
let maxRetries = 3; // should be const
var currentAttempt = 0; // never use var
```

- **Use mutable reference pattern to avoid `let`**
- wrap mutable values in objects (like React's `useRef`) to maintain const
  while allowing mutation

```typescript
// Good - mutable reference pattern
const counterRef = useRef(0);
counterRef.current += 1; // mutate .current, ref itself stays const

const stateRef = { current: initialValue }; // plain object ref
stateRef.current = newValue; // mutate .current
```

### Function Declarations

- **Prefer arrow functions** over regular functions
- Exception: Use regular functions when it doesn't make sense (e.g., when
  clearer naming or hoisting is needed)

```typescript
// Good - arrow functions
const calculateTotal = (items: Item[]): number => {
  return items.reduce((sum, item) => sum + item.price, 0);
};

const processData = async (data: Data): Promise<Result> => {
  // async operations
};

// Bad - regular functions (unless necessary)
function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

### Promises

Use async / await and never promise chaining

### Documentation

- **Use JSDoc comments** for all exported functions and complex internal functions
- Document parameters with `@param`
- Document return values with `@returns`
- Include description of what the function does
- Add examples for complex functions using `@example`

```typescript
/**
 * Calculates the total price of items in a cart
 *
 * @param items - Array of items to calculate total for
 * @returns The sum of all item prices
 */
export const calculateTotal = (items: Item[]): number => {
  return items.reduce((sum, item) => sum + item.price, 0);
};

/**
 * Validates user input and returns formatted result
 *
 * @param input - Raw user input string
 * @param options - Validation options
 * @returns Formatted and validated string, or null if invalid
 *
 * @example
 * const result = validateInput('test@email.com', { type: 'email' })
 * // returns 'test@email.com'
 */
export const validateInput = (
  input: string,
  options: ValidationOptions,
): string | null => {
  // implementation
};
```

## Code Organization

### File Structure

- **Use collocation** - keep related files together (e.g., tests in same folder
  as component)
- **Files max 200 lines of code**
- **Functions max 20 lines of code**
- Extract components to their own files for:
  - Reusability across the codebase
  - Keeping files small and focused
  - Better maintainability

### Imports

- Group imports by: external libraries, internal utilities, types
- Use absolute imports where configured

### Functions

- Keep functions small and focused (max 20 LOC)
- One responsibility per function
- Extract complex logic into separate functions
- If a function grows beyond 20 lines, break it down

### Error Handling

- Avoid manual try/catch blocks when possible
- Always provide meaningful error messages

## Svelte-Specific

### Stores

- Use reactive stores for shared state
- Prefix store subscriptions with `$`
- Avoid manual subscribe/unsubscribe (use auto-subscriptions)

### Components

- Prefer composition
- Use TypeScript for component props
- Keep component logic separate from presentation
- **Extract reusable components to separate files**
- Keep component files under 200 LOC
- Provide proper ARIA attributes to provide semantics, but this also makes
  testing via Testing Library easier

## Testing

### Test Structure

- **Use `it` instead of `test`** for test blocks
- Use descriptive test names
- Follow AAA pattern: Arrange, Act, Assert
- Test both happy paths and edge cases
- Mock external dependencies
- **Colocate tests with source files**

### Testing Library Conventions

- **Use Testing Library** for component tests
- **Test as a user would interact** with the component
- **Never use HTML elements or CSS classes** for queries
- **Always use roles, labels, and ARIA attributes** for queries
- Prefer queries in this order:
  1. `getByRole` (most preferred)
  2. `getByLabelText`
  3. `getByPlaceholderText`
  4. `getByText`
  5. `getByTestId` (last resort)

Examples:

```typescript
// Good - using roles and accessible queries
const button = screen.getByRole("button", { name: /submit/i });
const input = screen.getByLabelText(/email address/i);
const heading = screen.getByRole("heading", { name: /welcome/i });

// Bad - using CSS classes or HTML elements
const button = container.querySelector(".submit-button");
const input = container.querySelector("#email-input");
const heading = container.querySelector("h1");
```

### Test Naming

- Use clear, descriptive test descriptions
- Include expected behavior in test name
- Use "should" pattern: "should return null when action throws"
