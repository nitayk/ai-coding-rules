# Protocols and Delegates

Use weak for delegate properties. Name protocols after the delegating class. Use optional methods for delegates.

---

## Declare Delegate Properties as Weak

**Avoid retain cycles:**

```objc
// Good: Weak delegate
@protocol MyViewControllerDelegate <NSObject>
@optional
- (void)viewControllerDidFinish:(MyViewController *)controller;
@end

@interface MyViewController : UIViewController
@property (nonatomic, weak) id<MyViewControllerDelegate> delegate;
@end

// Bad: Strong delegate creates retain cycle
@property (nonatomic, strong) id<MyViewControllerDelegate> delegate;
```

---

## Use @optional for Delegate Methods

**Delegates implement only what they need:**

```objc
// Good: Optional methods
@protocol TableViewDelegate <NSObject>
@optional
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath;
@end

// Data source can have @required for essential methods
@protocol TableViewDataSource <NSObject>
@required
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end
```

---

## Name Protocols and Methods Correctly

**Protocol naming: ClassName + Delegate or DataSource. Method naming: Include delegating object as first parameter.**

```objc
// Good: Protocol name matches class
@protocol UserServiceDelegate <NSObject>
@optional
- (void)userService:(UserService *)service didLoadUser:(User *)user;
- (void)userService:(UserService *)service didFailWithError:(NSError *)error;
@end

// Good: Method names form readable sentence
- (void)userService:(UserService *)service didLoadUser:(User *)user;
- (BOOL)userService:(UserService *)service shouldRetryWithError:(NSError *)error;
```

---

## Check Delegate Responds Before Calling

**Use respondsToSelector: for optional methods:**

```objc
// Good: Check before optional delegate call
if ([self.delegate respondsToSelector:@selector(viewControllerDidFinish:)]) {
    [self.delegate viewControllerDidFinish:self];
}

// Bad: Calling without check - crash if delegate doesn't implement
[self.delegate viewControllerDidFinish:self];
```

---

## Use Conforming-To for Protocol Adoption

**Use NSObject when protocol needs optional method checking:**

```objc
// Good: NSObject base for respondsToSelector
@protocol MyDelegate <NSObject>
@optional
- (void)didComplete;
@end

// Bad: Protocol without NSObject - respondsToSelector may not work
@protocol MyDelegate
@optional
- (void)didComplete;
@end
```

---

## Related Rules

- [ARC Memory Management](arc-memory-management.md) - Weak references
- [iOS Best Practices](../ios/ios-best-practices.md) - Delegate conventions

---

## References

- [Apple: Working with Protocols](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithProtocols/WorkingwithProtocols.html)
- [Apple: Delegates and Data Sources](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/DelegatesandDataSources/DelegatesandDataSources.html)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
