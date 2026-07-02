# Objective-C Style Guide

## Naming

- **Prefixes**: Use 2-3 letter prefix for classes, protocols, global constants (e.g., `ISMyClass`, `IS_MAX_COUNT`).
- **Methods**: camelCase. First argument should form readable sentence with method name: `- (void)loadUserWithId:(NSString *)userId`.
- **Properties**: camelCase.

## Formatting

- **Indentation**: 4 spaces.
- **Braces**: Opening brace on end of line (K&R style).
- **Asterisks**: `NSString *text` (space before asterisk).

## Use Literals

```objc
// Good: Literals
NSArray *items = @[@"a", @"b", @"c"];
NSDictionary *map = @{@"key": @"value"};
NSNumber *count = @42;

// Bad: Verbose creation
NSArray *items = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
NSDictionary *map = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
```

## Use #pragma mark for Organization

```objc
// Good: Sections in Xcode navigator
@implementation UserViewController

#pragma mark - Lifecycle

- (void)viewDidLoad { ... }
- (void)viewWillAppear:(BOOL)animated { ... }

#pragma mark - Actions

- (void)handleTap:(UITapGestureRecognizer *)sender { ... }

#pragma mark - Private

- (void)refreshData { ... }

@end
```

## Use Categories for Extensions

**Extend classes without subclassing. See [Categories](categories.md) for prefixes and pitfalls.**

## Properties

- **Strings and blocks**: Use `copy` to ensure immutability: `@property (nonatomic, copy) NSString *string;`
- **Constants**: Use `static const` instead of `#define` for typed constants: `static const NSTimeInterval kTimeout = 30.0;`

## Related Rules

- [Nullability and Swift Interop](nullability-swift-interop.md) - Swift interoperability
- [ARC Memory Management](arc-memory-management.md) - Weak self in blocks
- [Categories](categories.md) - Category design and method prefixes

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
