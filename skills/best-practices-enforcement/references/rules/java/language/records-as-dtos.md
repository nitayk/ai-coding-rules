# Records as DTOs and value objects

Records (JDK 16+, [JEP 395](https://openjdk.org/jeps/395)) are the canonical Java way to declare **transparent, immutable carriers of data**. They give you final fields, a canonical constructor, accessors, `equals`/`hashCode`/`toString`, and serialization support — for free, in one line.

For broader immutability and "use records for data" guidance, see [modern-java-patterns.md § Use Records for Data Holders](modern-java-patterns.md). This file focuses on the **decisions** around using records vs alternatives.

---

## When records are the right answer

✅ Use a record when:

- The class is a pure data carrier (no significant behavior, no identity beyond its fields).
- All fields can be `final` and the object should be immutable.
- `equals`/`hashCode` should be **value-based** (two instances with the same fields are equal).
- It's an API DTO, an event payload, a query result row, or a tuple-like return value.

```java
public record CreateUserRequest(String name, String email, int age) {}

public record QueryResult<T>(List<T> rows, int totalCount, String nextPageToken) {}

public record Coordinates(double lat, double lon) {}
```

---

## Validate in the compact constructor

Records support a **compact constructor** for invariants. Validate eagerly so an invalid record can never exist.

✅ Good

```java
public record Email(String value) {
    public Email {                                  // compact constructor — no parameter list
        if (value == null || !value.contains("@")) {
            throw new IllegalArgumentException("invalid email: " + value);
        }
    }
}

public record Range(int low, int high) {
    public Range {
        if (low > high) throw new IllegalArgumentException("low > high");
    }
}
```

The compact constructor runs **before** field assignment; assignments are implicit.

---

## When records are NOT enough

Records are shallowly immutable. The **reference** is final, but mutable components (arrays, mutable collections, mutable objects) can still be modified through the accessor.

### Defensive copies for mutable components

❌ Bad: leaks internal state

```java
public record Batch(List<Item> items) {}     // caller can do batch.items().add(...)
```

✅ Good: copy on construction AND on read

```java
public record Batch(List<Item> items) {
    public Batch {
        items = List.copyOf(items);          // immutable snapshot at construction
    }
    // accessor returns the immutable list directly — safe
}
```

For mutable types you can't make immutable (e.g. `byte[]`), copy in both the canonical constructor and the accessor:

```java
public record Payload(byte[] bytes) {
    public Payload {
        bytes = bytes.clone();
    }
    public byte[] bytes() {
        return bytes.clone();
    }
}
```

Note: cloning in the accessor breaks the auto-generated `equals` semantics (you compare references, not contents). If equality matters, override `equals` and `hashCode` to use `Arrays.equals` / `Arrays.hashCode`.

### Other "use a class instead" signals

- **Cyclic references** between value types (records cannot self-reference cleanly).
- **Inheritance is required** (records are implicitly `final`; they can implement interfaces but not extend classes).
- **You need setters** (you don't — but if you truly do, you're modeling state, not a value).
- **Lifecycle hooks** beyond construction (post-construct init, etc.).

---

## Records vs Lombok `@Value`

Once you target JDK 16+, records replace `@Value` for **most** data-class use cases with zero dependencies and full IDE/compiler/debugger support.

| Concern | Record | Lombok `@Value` |
|---|---|---|
| Build dependency | None (language feature) | Lombok + IDE plugin + annotation processor |
| Compile-time generation | Native | Annotation-processor magic |
| Accessor style | `name()` | `getName()` |
| Inheritance | Implements interfaces only | Implements interfaces only |
| Compact constructor validation | Built-in | Use `@Builder` + custom code |
| Builder / wither | Manual or external lib | Built-in `@Builder`, `@With` |
| Debugger / refactoring | First-class | Depends on plugin |

**Migrate `@Value` → record when possible.** Keep Lombok only for `@Builder` / `@With` if a record alone is too verbose. Don't mix `@Data` (mutable!) with records.

---

## Records in serialization (Jackson, Gson, JDBI)

Modern Jackson (≥2.12), Gson (≥2.10), and most JDBC mappers handle records natively via the canonical constructor and accessor names. No annotations needed for simple cases.

```java
// Jackson, with default config:
record Order(String id, BigDecimal total, Instant placedAt) {}
Order o = mapper.readValue(json, Order.class);   // works
```

For renaming fields, use `@JsonProperty` on the record component:

```java
public record Order(@JsonProperty("order_id") String id, BigDecimal total) {}
```

---

## Related rules

- [Modern Java patterns](modern-java-patterns.md) — immutability, records as data holders (overview)
- [Pattern matching for switch](pattern-matching-switch.md) — record deconstruction patterns
- [Production patterns](../meta/java-production-patterns.md) — bean validation on record DTOs

---

## References

- [JEP 395: Records (Final, JDK 16)](https://openjdk.org/jeps/395) — normative spec
- [dev.java/learn — Records](https://dev.java/learn/records/) — Oracle tutorial

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
