# Objective-C Testing

Use XCTest for unit tests. Use OCMock for mocking. Inject dependencies to enable testing.

---

## Use XCTestCase for Test Classes

**Organize tests in XCTestCase subclasses:**

```objc
// Good: Standard XCTest structure
@interface UserServiceTests : XCTestCase
@property (nonatomic, strong) UserService *sut;
@property (nonatomic, strong) id<APIClient> mockAPIClient;
@end

@implementation UserServiceTests

- (void)setUp {
    [super setUp];
    self.mockAPIClient = OCMProtocolMock(@protocol(APIClient));
    self.sut = [[UserService alloc] initWithAPIClient:self.mockAPIClient];
}

- (void)tearDown {
    self.sut = nil;
    self.mockAPIClient = nil;
    [super tearDown];
}

- (void)testFetchUser_CallsAPIClient {
    OCMExpect([self.mockAPIClient fetchUserWithId:@"123" completion:[OCMArg any]]);
    [self.sut loadUserWithId:@"123" completion:^(User *user, NSError *error) {}];
    OCMVerifyAll(self.mockAPIClient);
}
@end
```

---

## Use Dependency Injection for Testability

**Pass dependencies via initializer or property:**

```objc
// Good: Injectable dependency
@interface UserService : NSObject
- (instancetype)initWithAPIClient:(id<APIClient>)client;
@end

// In test: inject mock
UserService *sut = [[UserService alloc] initWithAPIClient:mockClient];

// Bad: Hard-coded dependency - cannot mock
@implementation UserService
- (void)loadUser {
    [[APIClient sharedInstance] fetchUser...];  // Cannot test in isolation
}
@end
```

---

## Stub External Dependencies with OCMock

**Stub network, file system, and system APIs:**

```objc
// Good: Stub return value
OCMStub([self.mockAPIClient fetchUserWithId:@"123" completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        void (^completion)(User *, NSError *);
        [invocation getArgument:&completion atIndex:3];
        User *user = [[User alloc] initWithId:@"123" name:@"Test"];
        completion(user, nil);
    });

// Good: Stub to return error
OCMStub([self.mockAPIClient fetchUserWithId:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        void (^completion)(User *, NSError *);
        [invocation getArgument:&completion atIndex:3];
        completion(nil, [NSError errorWithDomain:@"Test" code:500 userInfo:nil]);
    });
```

---

## Verify Method Calls with OCMVerify

**Assert expected interactions:**

```objc
// Good: Verify call occurred
OCMExpect([self.mockAPIClient fetchUserWithId:@"123" completion:[OCMArg any]]);
[self.sut loadUserWithId:@"123" completion:^(User *u, NSError *e) {}];
OCMVerifyAll(self.mockAPIClient);

// Good: Verify with matcher
OCMVerify([self.mockAPIClient fetchUserWithId:[OCMArg any] completion:[OCMArg any]]);
```

---

## Use Shared Test Superclass for Common Setup

**Extract repeated setup into a base class:**

```objc
// Good: Shared superclass
@interface BaseTestCase : XCTestCase
@property (nonatomic, strong) NSManagedObjectContext *testContext;
@end

@implementation BaseTestCase
- (void)setUp {
    [super setUp];
    self.testContext = [self createInMemoryContext];
}
@end

@interface UserServiceTests : BaseTestCase
@end
```

---

## Related Rules

- [ARC Memory Management](../language/arc-memory-management.md) - Weak references in test fixtures
- [Style Guide](../language/style-guide.md) - Naming test methods

---

## References

- [Apple: XCTest](https://developer.apple.com/documentation/xctest)
- [OCMock Reference](https://ocmock.org/reference)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
