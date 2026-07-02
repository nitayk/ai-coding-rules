# Nullability and Swift Interoperability

Annotate headers with nullability so Swift imports proper optionals. Use NS_ASSUME_NONNULL_BEGIN for headers exposed to Swift.

---

## Use NS_ASSUME_NONNULL_BEGIN in Headers

**Default to nonnull; mark only nullable explicitly:**

```objc
// Good: Nonnull by default
NS_ASSUME_NONNULL_BEGIN

@interface UserService : NSObject
- (User *)userWithId:(NSString *)userId;  // Nonnull return
- (nullable User *)cachedUserForId:(NSString *)userId;  // Explicit nullable
@property (nonatomic, copy) NSString *name;  // Nonnull
@property (nonatomic, copy, nullable) NSString *nickname;  // Nullable
@end

NS_ASSUME_NONNULL_END

// Bad: Unannotated - Swift imports as implicitly unwrapped (NSString!)
@interface UserService : NSObject
- (User *)userWithId:(NSString *)userId;  // Swift: User! - crash risk
@end
```

---

## Mark Nullable Parameters and Returns Explicitly

**Clarify nil semantics for Swift callers:**

```objc
// Good: Explicit nullability
- (nullable NSString *)displayNameForUser:(User *)user;
- (void)loadWithCompletion:(void (^)(NSArray * _Nullable items, NSError * _Nullable error))completion;

// Block parameters: use _Nullable for pointer types
typedef void (^CompletionHandler)(NSData * _Nullable data, NSError * _Nullable error);
```

---

## Use NS_SWIFT_NAME for Cleaner Swift API

**Rename methods for Swift naming conventions:**

```objc
// Good: Swift-friendly names
- (void)loadUserWithId:(NSString *)userId completion:(void (^)(User * _Nullable, NSError * _Nullable))completion
    NS_SWIFT_NAME(loadUser(id:completion:));

// In Swift: userService.loadUser(id: "123") { user, error in ... }

// Good: Hide verbose Obj-C selector in Swift
- (instancetype)initWithUserId:(NSString *)userId
    NS_SWIFT_NAME(init(userId:));
```

---

## Use NS_ENUM and NS_OPTIONS for Enums

**Enums map to Swift enums with proper typing:**

```objc
// Good: NS_ENUM for Swift enum
typedef NS_ENUM(NSInteger, ConnectionState) {
    ConnectionStateDisconnected,
    ConnectionStateConnecting,
    ConnectionStateConnected
};

// Good: NS_OPTIONS for option sets
typedef NS_OPTIONS(NSUInteger, CacheOptions) {
    CacheOptionMemory = 1 << 0,
    CacheOptionDisk = 1 << 1,
};
```

---

## Use null_resettable for Resettable Properties

**Setter accepts nil, getter never returns nil:**

```objc
// Good: UITextField.tintColor - set nil to reset to default
@property (nonatomic, strong, null_resettable) UIColor *tintColor;
```

---

## Related Rules

- [Style Guide](style-guide.md) - Naming and header organization
- [iOS Best Practices](../ios/ios-best-practices.md) - Swift bridging headers

---

## References

- [Apple: Improving Objective-C API Declarations for Swift](https://developer.apple.com/documentation/swift/improving-objective-c-api-declarations-for-swift)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
