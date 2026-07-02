# Pattern matching for switch

Pattern matching for `switch` went **GA in JDK 21** via [JEP 441](https://openjdk.org/jeps/441). Combined with **sealed types** (JDK 17, JEP 409), it lets you express closed algebraic data types with compiler-checked exhaustiveness — replacing visitor-pattern boilerplate and brittle `instanceof` chains.

---

## Sealed + switch = exhaustive

Mark the hierarchy `sealed` and `permits` the known subtypes. The compiler then **requires** the `switch` to cover all permitted types, or you'll get a compile error — not a `default:` you forgot to update.

✅ Good

```java
public sealed interface Shape permits Circle, Square, Triangle {}
public record Circle(double radius) implements Shape {}
public record Square(double side) implements Shape {}
public record Triangle(double base, double height) implements Shape {}

public static double area(Shape s) {
    return switch (s) {                  // compiler checks exhaustiveness
        case Circle c   -> Math.PI * c.radius() * c.radius();
        case Square sq  -> sq.side() * sq.side();
        case Triangle t -> 0.5 * t.base() * t.height();
    };
}
```

Adding a new permitted type (e.g. `Hexagon`) **fails the compile** at every `switch` that didn't update — exactly what you want.

❌ Bad: open hierarchy + `default` swallows new types

```java
public abstract class Shape {}              // anyone can extend
public class Hexagon extends Shape {}

public static double area(Shape s) {
    if (s instanceof Circle c)      return Math.PI * c.radius() * c.radius();
    else if (s instanceof Square sq) return sq.side() * sq.side();
    else return 0;                          // Hexagon silently returns 0
}
```

---

## Deconstruction patterns (record patterns)

Switch patterns can destructure records inline — no intermediate `var` + accessor calls.

✅ Good

```java
return switch (event) {
    case OrderPlaced(var id, var total)       -> bill(id, total);
    case OrderShipped(var id, var address)    -> notify(id, address);
    case OrderCancelled(var id, var reason)   -> refund(id, reason);
};
```

Nested deconstruction also works:

```java
case Pair(Point(var x1, var y1), Point(var x2, var y2)) -> distance(x1, y1, x2, y2);
```

---

## Guarded patterns (`when` clauses)

Add a boolean guard with `when` for finer dispatch — keeps the type check and the predicate together.

✅ Good

```java
String describe(Object o) {
    return switch (o) {
        case Integer i when i < 0  -> "negative int";
        case Integer i when i == 0 -> "zero";
        case Integer i             -> "positive int";
        case String s when s.isBlank() -> "blank string";
        case String s              -> "string: " + s;
        case null                  -> "null";
        default                    -> "other";
    };
}
```

Note `case null` is explicit — a pattern switch on `Object` will NPE without it (this is **better** than the silent NPE in classic switch, but you need to handle it).

---

## When NOT to use pattern matching

- **Single-type dispatch**: a regular method on the type is still better (polymorphism beats external dispatch when behavior belongs to the object).
- **Open hierarchies** without `sealed`: you lose exhaustiveness and the value collapses to "fancier `instanceof`".
- **Cross-cutting operations that mutate state**: a visitor with a stateful accumulator may read more clearly.

Rule of thumb: **closed data + open operations → sealed + switch. Open data + closed operations → polymorphism.**

---

## Replacing the visitor pattern

The visitor pattern (double dispatch via `accept(Visitor v)`) exists because pre-JDK-21 Java couldn't switch on type safely. Sealed + pattern switch removes the need for boilerplate `Visitor` interfaces, `accept()` methods, and per-subtype `visitXxx` handlers.

✅ Good (sealed + switch)

```java
public sealed interface Json permits JsonNull, JsonBool, JsonNum, JsonStr, JsonArr, JsonObj {}

String render(Json j) {
    return switch (j) {
        case JsonNull n          -> "null";
        case JsonBool(var b)     -> Boolean.toString(b);
        case JsonNum(var n)      -> Double.toString(n);
        case JsonStr(var s)      -> "\"" + s + "\"";
        case JsonArr(var items)  -> items.stream().map(this::render).collect(joining(",", "[", "]"));
        case JsonObj(var fields) -> fields.entrySet().stream()
                                        .map(e -> "\"" + e.getKey() + "\":" + render(e.getValue()))
                                        .collect(joining(",", "{", "}"));
    };
}
```

Equivalent visitor would require a `JsonVisitor<R>` interface, an `accept()` method on every subtype, and a separate visitor class per operation. The switch version is roughly half the lines and exhaustiveness is compiler-checked.

---

## Related rules

- [Records as DTOs](records-as-dtos.md) — record patterns work hand-in-hand with sealed hierarchies
- [Modern Java patterns](modern-java-patterns.md) — broader Java 17+ overview (sealed classes intro)

---

## References

- [JEP 441: Pattern Matching for switch (Final, JDK 21)](https://openjdk.org/jeps/441) — normative spec
- [JEP 440: Record Patterns (Final, JDK 21)](https://openjdk.org/jeps/440) — deconstruction patterns
- [dev.java/learn — Pattern Matching](https://dev.java/learn/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
