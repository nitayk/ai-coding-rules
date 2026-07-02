# Categories

Use categories to extend classes without subclassing. Prefix category methods to avoid collisions. Never override methods in categories.

---

## Prefix Category Methods

**Avoid name collisions when multiple categories add similar methods:**

```objc
// Good: Prefixed with 2-3 letter prefix (e.g., app_, IS_)
@interface NSString (AppValidation)
- (BOOL)app_isValidEmail;
- (BOOL)app_isValidPhoneNumber;
@end

// Bad: Unprefixed - collision risk if another category adds isValidEmail
@interface NSString (Validation)
- (BOOL)isValidEmail;
@end
```

---

## Never Override Methods in Categories

**Overriding existing methods in categories causes undefined behavior:**

```objc
// Bad: Overriding - undefined which implementation runs
@interface NSString (BadCategory)
- (NSUInteger)length;  // Overrides NSObject/NSString - DO NOT
@end

// Good: Add new methods only
@interface NSString (Helpers)
- (NSString *)app_trimmed;
@end
```

---

## Use Categories for Organization

**Split large implementations into logical categories:**

```objc
// Good: Category for grouping related methods
@interface UserViewController (Private)
- (void)refreshData;
- (void)setupUI;
@end

@implementation UserViewController (Private)
- (void)refreshData { ... }
- (void)setupUI { ... }
@end
```

---

## Use Categories for Utility Extensions

**Extend framework classes with app-specific helpers:**

```objc
// Good: Utility extension
@interface NSDate (Formatter)
- (NSString *)app_relativeString;  // "2 hours ago"
@end

@interface NSArray (SafeAccess)
- (id)app_objectOrNilAtIndex:(NSUInteger)index;
@end
```

---

## Declare Category in Header for Public Use

**Keep private categories in implementation file:**

```objc
// Public: In .h file
@interface NSString (Validation)
- (BOOL)app_isValidEmail;
@end

// Private: In .m file only
@interface UserService ()
@property (nonatomic, strong) NSURLSession *session;
@end
```

---

## Related Rules

- [Style Guide](style-guide.md) - Naming and header organization
- [Nullability and Swift Interop](nullability-swift-interop.md) - Annotate category headers for Swift

---

## References

- [Apple: Customizing Existing Classes](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/CustomizingExistingClasses/CustomizingExistingClasses.html)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
