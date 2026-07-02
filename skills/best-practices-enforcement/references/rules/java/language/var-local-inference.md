# `var` — local-variable type inference

`var` (JDK 10, [JEP 286](https://openjdk.org/jeps/286)) lets the compiler infer the type of a **local variable** from its initializer. It is a readability tool, not a typing shortcut — used well, it removes redundancy; used badly, it obscures the type the reader needs to understand the code.

The [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html) allows `var` **conditionally** — its single rule is: **use `var` only when it makes the code clearer than the explicit type.**

---

## When `var` helps

### 1. Type appears on the right-hand side already

✅ Good — type is visible from the constructor

```java
var users = new ArrayList<User>();
var cache = new ConcurrentHashMap<String, Config>();
var executor = Executors.newVirtualThreadPerTaskExecutor();
```

❌ Redundant

```java
ArrayList<User> users = new ArrayList<User>();          // diamond operator at minimum
ConcurrentHashMap<String, Config> cache = new ConcurrentHashMap<String, Config>();
```

### 2. Type is long and adds no information

✅ Good

```java
var entry = Map.entry("key", new BigDecimal("123.45"));      // Map.Entry<String, BigDecimal>
var stream = orders.stream().filter(Order::isPaid);          // Stream<Order>
```

The right-hand side already tells the reader everything; spelling out `Map.Entry<String, BigDecimal>` doesn't help.

### 3. Try-with-resources

✅ Good

```java
try (var stmt = conn.prepareStatement(sql);
     var rs   = stmt.executeQuery()) {
    return mapResults(rs);
}
```

---

## When `var` hurts

### 1. RHS is a method call returning a non-obvious type

❌ Bad — what is `result`?

```java
var result = processor.handle(request);
```

✅ Better — readers don't have to jump to `handle()`'s signature

```java
ProcessingOutcome result = processor.handle(request);
```

### 2. Numeric literals

❌ Bad — easy to misread the inferred type

```java
var count = 100;             // int — but the reader has to know that
var ratio = 1.0;             // double
var bigCount = 100_000_000L; // long — easy to miss the L
```

✅ Better — explicit types prevent silent widening / wrong overload selection

```java
long count = 100;
double ratio = 1.0;
```

### 3. The variable is used far from its declaration

If the variable lives across many lines or branches, the type should be visible at the declaration. `var` forces the reader to scroll back to the initializer to recover the type.

### 4. Diamond would lose target-typing info

❌ Bad — infers `ArrayList<Object>`, not `ArrayList<User>`

```java
var users = new ArrayList<>();
```

✅ Good

```java
var users = new ArrayList<User>();
// or
List<User> users = new ArrayList<>();
```

### 5. Lambda or method-reference initializer

`var` requires an initializer with a denotable type — lambdas and method refs don't have one:

```java
var f = (String s) -> s.length();   // compile error — lambda has no standalone type
```

✅ Good

```java
Function<String, Integer> f = String::length;
```

---

## Don't use `var` for fields, parameters, or return types

`var` is **only** legal on local variables, indices in `for` loops, and resources in try-with-resources. Fields and method signatures are part of the **API surface** — explicit types are required by the language, and they help readers reason about the contract.

```java
public class Service {
    var dependency = new Dep();          // compile error
    public var compute(var input) { }    // compile error
}
```

---

## Heuristic

Ask: **"If I delete the right-hand side, can a reasonable reader still guess the type?"**

- Yes (e.g. `var u = new User(...)`, `var entry = Map.entry(...)`) → `var` is fine, often better.
- No (e.g. `var x = service.fetch()`) → write the type.

When in doubt, write the type. `var` is an optimization for the obvious case; it is not a default.

---

## Related rules

- [Style guide](style-guide.md) — Google Java Style baseline
- [Modern Java patterns](modern-java-patterns.md) — broader idiom guidance

---

## References

- [JEP 286: Local-Variable Type Inference (JDK 10)](https://openjdk.org/jeps/286)
- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html) — section on `var`

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
