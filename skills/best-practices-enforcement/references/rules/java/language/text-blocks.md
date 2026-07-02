# Text blocks

Text blocks went GA in JDK 15. They eliminate the noise of `\n` line joins, escaped quotes, and string concatenation that plagued multi-line literals — and they make embedded SQL, JSON, GraphQL, and HTML readable inline.

A text block is opened by `"""` followed by a newline. Indentation is normalized against the **least-indented non-blank line** (the "incidental whitespace" rule from the [Java Language Specification §3.10.6](https://docs.oracle.com/javase/specs/)).

---

## Use for embedded SQL

✅ Good

```java
String sql = """
    SELECT u.id, u.email, COUNT(o.id) AS order_count
    FROM users u
    LEFT JOIN orders o ON o.user_id = u.id
    WHERE u.active = true
    GROUP BY u.id, u.email
    ORDER BY order_count DESC
    """;
```

❌ Bad

```java
String sql = "SELECT u.id, u.email, COUNT(o.id) AS order_count "
    + "FROM users u "
    + "LEFT JOIN orders o ON o.user_id = u.id "
    + "WHERE u.active = true "
    + "GROUP BY u.id, u.email "
    + "ORDER BY order_count DESC";
```

Still use **parameterized queries** for any user input — text blocks don't change SQL-injection rules (see [production patterns § Validate and Sanitize Input at Boundaries](../meta/java-production-patterns.md)). The text block holds the static query shape; `?` placeholders carry the values.

---

## Use for embedded JSON

✅ Good — readable, no quote escaping

```java
String payload = """
    {
      "event": "order.placed",
      "order_id": "%s",
      "total_cents": %d
    }
    """.formatted(orderId, totalCents);
```

❌ Bad — escape-heavy and error-prone

```java
String payload = "{\"event\":\"order.placed\",\"order_id\":\""
    + orderId + "\",\"total_cents\":" + totalCents + "}";
```

For anything non-trivial, prefer a proper JSON library (`ObjectMapper.writeValueAsString(...)`) over hand-formatted text. Text blocks shine for **small, fixed-shape templates** (test fixtures, single-shot HTTP bodies, deterministic snippets).

---

## Use for GraphQL queries

✅ Good

```java
String query = """
    query userOrders($userId: ID!) {
      user(id: $userId) {
        email
        orders(last: 10) { id total placedAt }
      }
    }
    """;
```

---

## Indentation rules — surprises to know

The compiler strips the common leading whitespace shared by **all non-blank lines**, including the closing `"""`. The position of the **closing delimiter** influences indentation:

```java
// Closing """ flush-left → strips all common leading whitespace.
String a = """
    line one
    line two
    """;
// a == "line one\nline two\n"

// Closing """ indented by 2 → keeps 2 leading spaces on each line.
String b = """
    line one
    line two
  """;
// b == "  line one\n  line two\n"
```

Rule of thumb: **put the closing `"""` at the column where you want the left margin to land.** Most styles place it flush with the opening `"""` indent (which yields no leading whitespace on content lines).

---

## Trailing newline

A text block always **ends with a newline** unless you suppress it with `\` at the end of the last line:

```java
String oneLine = """
    just one line\
    """;
// oneLine == "just one line"  (no trailing newline)
```

This matters when concatenating text blocks or feeding them to APIs that are newline-sensitive.

---

## Don't use text blocks for

- **Single-line strings** — regular string literals are cleaner.
- **Programmatic string building with many interpolations** — use `String.format`, `MessageFormat`, or a templating library; jamming `%s` into a long block hurts more than concatenation.
- **User-facing copy** — use i18n resource bundles, not source-embedded blocks.
- **Anything that should be in a real file** — large HTML emails, long SQL migrations, schema definitions: keep those as resources on the classpath, not source literals.

---

## `formatted()` is the modern interpolation

Records and text blocks pair well with the `String.formatted` instance method (JDK 15+):

```java
String greeting = """
    Hi %s,
    Your order %s is on its way.
    """.formatted(user.name(), order.id());
```

This reads better than `String.format("...", a, b)` when the template itself is the focus.

---

## Related rules

- [Style guide](style-guide.md) — formatting, line length
- [Production patterns](../meta/java-production-patterns.md) — parameterized queries still required

---

## References

- [Java Language Specification §3.10.6 — Text Blocks](https://docs.oracle.com/javase/specs/)
- [dev.java/learn — Text Blocks](https://dev.java/learn/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
