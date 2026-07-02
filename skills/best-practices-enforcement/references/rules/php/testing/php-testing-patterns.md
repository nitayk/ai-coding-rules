# PHP Testing Patterns

Design for testability. Use dependency injection. Follow Arrange-Act-Assert. Use PHPUnit for unit tests.

---

## Triggers

**APPLY WHEN:** Writing PHPUnit tests, designing testable code, mocking dependencies.
**SKIP WHEN:** Writing production code only, integration tests with real dependencies.

---

## Core Directive

**Inject dependencies via constructor.** Avoid `new` and global state inside classes under test. Use AAA structure.

---

## Design for Testability with Dependency Injection

**Inject dependencies via constructor.** Enables mock substitution in tests.

```php
// Good: Constructor injection - testable
class OrderService
{
    public function __construct(
        private OrderRepository $repository,
        private PaymentGateway $paymentGateway
    ) {
    }

    public function placeOrder(OrderRequest $request): Order
    {
        $order = $this->repository->save(new Order($request));
        $this->paymentGateway->charge($order->getTotal());
        return $order;
    }
}

// Test: inject mocks
public function testPlaceOrderChargesPayment(): void
{
    $repo = $this->createMock(OrderRepository::class);
    $gateway = $this->createMock(PaymentGateway::class);
    $service = new OrderService($repo, $gateway);

    $repo->method('save')->willReturnArgument(0);

    $service->placeOrder(new OrderRequest(100));

    $gateway->expects($this->once())->method('charge')->with(100);
}

// Bad: Hard-coded dependencies - untestable
class OrderService
{
    private OrderRepository $repository = new JdbcOrderRepository();
    private PaymentGateway $gateway = new StripeGateway();
}
```

---

## Use Arrange-Act-Assert (AAA)

**Structure tests in three clear phases.** Improves readability and catches missing setup or assertions.

```php
// Good: AAA structure
public function testCalculateTotalWithDiscountAppliesDiscount(): void
{
    // Arrange
    $cart = new Cart();
    $cart->addItem(new Item('A', 100));
    $cart->addItem(new Item('B', 50));
    $calculator = new PriceCalculator(0.1);

    // Act
    $total = $calculator->calculateTotal($cart);

    // Assert
    $this->assertSame(135.0, $total);
}

// Bad: Mixed setup, action, assertion
public function testCalculator(): void
{
    $cart = new Cart();
    $cart->addItem(new Item('A', 100));
    $total = (new PriceCalculator(0.1))->calculateTotal($cart);
    $cart->addItem(new Item('B', 50));  // Setup after act!
    $this->assertSame(135.0, $total);
}
```

---

## Use PHPUnit Mocking Correctly

**Use `createMock` or `getMockBuilder`.** Configure expectations explicitly. Avoid mocking final, private, or static methods.

```php
// Good: Explicit mock configuration
public function testFindUserThrowsWhenNotFound(): void
{
    $repository = $this->createMock(UserRepository::class);
    $repository->method('findById')
        ->with(999)
        ->willReturn(null);

    $service = new UserService($repository);

    $this->expectException(UserNotFoundException::class);

    $service->findUser(999);
}

// Good: Stub with return value
$logger = $this->createMock(LoggerInterface::class);
$logger->method('info')->willReturn(null);

// Bad: Mocking final class (fails)
$pdo = $this->createMock(PDO::class);  // PDO is final
```

---

## Use @dataProvider for Multiple Cases

**Parameterize tests** to avoid duplication and improve coverage.

```php
// Good: Data provider
/**
 * @dataProvider invalidEmailProvider
 */
public function testCreateUserRejectsInvalidEmail(string $email): void
{
    $service = new UserService($this->createMock(UserRepository::class));

    $this->expectException(InvalidArgumentException::class);

    $service->createUser('John', $email);
}

public static function invalidEmailProvider(): array
{
    return [
        'empty' => [''],
        'no-at' => ['invalid'],
        'no-domain' => ['user@'],
    ];
}

// Bad: Duplicate test methods
public function testCreateUserRejectsEmptyEmail(): void { /* ... */ }
public function testCreateUserRejectsNoAt(): void { /* ... */ }
```

---

## Test Edge Cases and Error Paths

**Cover null returns, exceptions, boundary conditions.** Aim for 70-80% coverage on critical paths.

```php
// Good: Error path tested
public function testFindUserThrowsWhenNotFound(): void
{
    $repo = $this->createMock(UserRepository::class);
    $repo->method('findById')->willReturn(null);

    $service = new UserService($repo);

    $this->expectException(UserNotFoundException::class);

    $service->findUser(999);
}
```

---

## Related Rules

- [Modern PHP Patterns](../language/modern-php-patterns.md) - Type declarations, dependency injection
- [Generic Testing Principles](../../../generic/testing/core-principles.md) - Universal testing principles

---

## References

- [PHPUnit Manual](https://docs.phpunit.de/)
- [PHP The Right Way - Testing](https://phptherightway.com/#testing)
- [Understanding Test Doubles in PHPUnit](https://phpunit.de/manual/current/en/test-doubles.html)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
