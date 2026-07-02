# Java Testing Patterns

Design for testability. Use dependency injection. Follow Arrange-Act-Assert. Write tests that document behavior.

---

## Design for Testability with Dependency Injection

**Inject dependencies via constructor.** Avoid `new` inside classes under test. Enables mock substitution.

```java
// ✅ Good: Constructor injection - testable
public class OrderService {
    private final OrderRepository repository;
    private final PaymentGateway paymentGateway;
    
    public OrderService(OrderRepository repository, PaymentGateway paymentGateway) {
        this.repository = repository;
        this.paymentGateway = paymentGateway;
    }
    
    public Order placeOrder(OrderRequest request) {
        Order order = repository.save(new Order(request));
        paymentGateway.charge(order.getTotal());
        return order;
    }
}

// Test: inject mocks
@Test
void placeOrder_chargesPayment() {
    var repo = mock(OrderRepository.class);
    var gateway = mock(PaymentGateway.class);
    var service = new OrderService(repo, gateway);
    
    when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
    
    service.placeOrder(new OrderRequest(100));
    
    verify(gateway).charge(100);
}

// ❌ Bad: Hard-coded dependencies - untestable
public class OrderService {
    private final OrderRepository repository = new JdbcOrderRepository();
    private final PaymentGateway gateway = new StripeGateway();
}
```

---

## Use Arrange-Act-Assert (AAA)

**Structure tests in three clear phases.** Improves readability and catches missing setup or assertions.

```java
// ✅ Good: AAA structure
@Test
void calculateTotal_withDiscount_appliesDiscount() {
    // Arrange
    var cart = new Cart();
    cart.addItem(new Item("A", 100));
    cart.addItem(new Item("B", 50));
    var calculator = new PriceCalculator(0.1);  // 10% discount
    
    // Act
    var total = calculator.calculateTotal(cart);
    
    // Assert
    assertThat(total).isEqualTo(135);  // 150 - 10%
}

// ❌ Bad: Mixed setup, action, and assertion
@Test
void test1() {
    var cart = new Cart();
    cart.addItem(new Item("A", 100));
    var total = new PriceCalculator(0.1).calculateTotal(cart);
    assertThat(total).isEqualTo(90);
    cart.addItem(new Item("B", 50));  // Setup mixed with assert
    total = new PriceCalculator(0.1).calculateTotal(cart);
    assertThat(total).isEqualTo(135);
}
```

---

## Use Descriptive Test Names

**Names should describe behavior and expectations.** Avoid generic names like `testCalculate`.

```java
// ✅ Good: Describes scenario and expected outcome
@Test
void findUser_whenUserExists_returnsUser() { }

@Test
void findUser_whenUserNotFound_throwsUserNotFoundException() { }

@Test
void calculateArea_withLargeRadius_returnsInfinity() { }

// ❌ Bad: Generic names
@Test
void testFindUser() { }

@Test
void test1() { }
```

---

## Avoid Testability Anti-Patterns

**These make code hard or impossible to test:**

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| `new` inside constructor | Tight coupling | Constructor injection |
| Static methods for business logic | Cannot substitute | Instance methods, inject dependency |
| Logic in constructors | Hard to test in isolation | Factory or builder |
| Complex private methods | Cannot test directly | Extract to testable component |
| God objects | Too many responsibilities | Split, single responsibility |

```java
// ❌ Bad: Static dependency
public class ReportGenerator {
    public Report generate() {
        return Database.getConnection().query(...);  // Cannot mock Database
    }
}

// ✅ Good: Injected dependency
public class ReportGenerator {
    private final DataSource dataSource;
    
    public ReportGenerator(DataSource dataSource) {
        this.dataSource = dataSource;
    }
    
    public Report generate() {
        return dataSource.query(...);
    }
}
```

---

## Prefer Composition Over Inheritance for Testability

**Favor composition.** Inheritance can make tests brittle and force testing through superclass behavior.

```java
// ✅ Good: Composition - inject strategy
public class OrderProcessor {
    private final ValidationStrategy validator;
    
    public OrderProcessor(ValidationStrategy validator) {
        this.validator = validator;
    }
    
    public void process(Order order) {
        if (validator.isValid(order)) {
            // ...
        }
    }
}

// ❌ Bad: Inheritance - hard to test in isolation
public class OrderProcessor extends BaseProcessor {
    @Override
    public void process(Order order) {
        if (validateOrder(order)) {  // Calls superclass, complex setup
            // ...
        }
    }
}
```

---

## Keep Tests in src/test with Mirrored Packages

**Mirror production package structure.** Tests live in `src/test/java` with same package as source.

```
src/main/java/com/example/service/OrderService.java
src/test/java/com/example/service/OrderServiceTest.java
```

---

## Use Testcontainers for Integration Tests

**Prefer real dependencies in throwaway containers over hand-rolled mocks for integration tests.** [Testcontainers](https://java.testcontainers.org/) spins up disposable Docker containers (Postgres, Kafka, Redis, etc.) per test class — your tests run against the real software, not a fake.

```java
@Testcontainers
class OrderRepositoryIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void saveAndLoadOrder() {
        var ds = pgDataSource(postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword());
        var repo = new OrderRepository(ds);
        var id = repo.save(new Order(BigDecimal.valueOf(100)));
        assertThat(repo.findById(id)).isPresent();
    }
}
```

Keep Testcontainers for the **integration** tier — unit tests should remain in-memory and fast.

---

## Use AssertJ or JUnit 5 Assertions

**Prefer fluent assertions for readability.**

```java
// ✅ Good: AssertJ fluent assertions
assertThat(result).isNotNull();
assertThat(list).hasSize(3).containsExactly("a", "b", "c");
assertThat(exception).hasMessageContaining("not found");

// ✅ Good: JUnit 5 assertions
assertEquals(3, list.size());
assertThrows(UserNotFoundException.class, () -> service.findUser("missing"));
```

---

## Related Rules

**Java-Specific:**
- [Modern Java Patterns](../language/modern-java-patterns.md) - Immutability, records
- [Production Patterns](../meta/java-production-patterns.md) - Resource management

**Universal:**
- [Generic Testing Principles](../../../generic/testing/core-principles.md) - Universal testing principles

---

## References

- [JUnit 5 User Guide](https://docs.junit.org/current/user-guide/) — canonical (the old `junit.org/junit5/...` URL 301-redirects here)
- [AssertJ](https://assertj.github.io/doc/)
- [Testcontainers for Java](https://java.testcontainers.org/) — integration-test standard
- [Design for Testability (Jenkov)](https://jenkov.com/tutorials/java-unit-testing/design-for-testability.html)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
