# iOS Objective-C Best Practices

## 1. Interoperability
- **Headers**: Expose only necessary methods/properties in `.h` files. Keep implementation details in `.m` extensions.
- **Swift Bridging**:
  - Use `NS_SWIFT_NAME` to rename Objective-C methods for cleaner Swift syntax.
  - Use `NS_ENUM` and `NS_OPTIONS` macros for better Swift enum mapping.

## 2. Legacy Maintenance
- **Refactoring**: When touching legacy Obj-C code, consider if a partial migration to Swift is feasible.
- **Modernization**: Use modern Objective-C syntax (literals, lightweight generics `NSArray<NSString *> *`) even in old files.

## 3. Delegates
- Always declare delegate properties as `weak` to avoid retain cycles: `@property (nonatomic, weak) id<MyDelegate> delegate;`.

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
