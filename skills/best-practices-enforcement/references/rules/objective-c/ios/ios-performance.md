# iOS Performance (Objective-C)

Profile before optimizing. Use Instruments to find bottlenecks. Never block the main thread.

---

## Profile Before Optimizing

**Use Instruments to find actual bottlenecks:**

```objc
// Profile critical paths with Instruments:
// - Time Profiler: CPU hotspots
// - Allocations: Memory usage over time
// - Leaks: Retain cycles and leaks
// - Allocations (Generation): Object lifetimes

// Good: Profile first, then optimize
// 1. Run Time Profiler during slow operation
// 2. Identify hot methods
// 3. Optimize only those paths

// Bad: Optimizing without data
- (void)processItems:(NSArray *)items {
    for (id item in items) {
        [self processItem:item];  // Maybe not the bottleneck
    }
}
```

---

## Never Block the Main Thread

**UIKit must be used on main thread only. Offload work to background:**

```objc
// Good: Background for heavy work
- (void)loadHeavyData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *data = [self fetchAndParseData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

// Bad: Blocking main thread
- (void)loadHeavyData {
    NSArray *data = [self fetchAndParseData];  // Blocks UI
    [self.tableView reloadData];
}
```

---

## Use @autoreleasepool in Loops

**Prevent memory buildup when creating many temporary objects:**

```objc
// Good: Autorelease pool per iteration
- (void)processLargeDataset:(NSArray *)items {
    for (NSDictionary *item in items) {
        @autoreleasepool {
            NSString *processed = [self processItem:item];
            [self saveProcessed:processed];
        }
    }
}

// Bad: Accumulates until run loop drains
- (void)processLargeDataset:(NSArray *)items {
    for (NSDictionary *item in items) {
        NSString *processed = [self processItem:item];
        [self saveProcessed:processed];
    }
}
```

---

## Reuse Table View Cells

**Use `dequeueReusableCellWithIdentifier:forIndexPath:`:**

```objc
// Good: Cell reuse
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                                            forIndexPath:indexPath];
    cell.textLabel.text = self.items[indexPath.row];
    return cell;
}
```

---

## Avoid Expensive Operations in drawRect:

**Keep drawing fast; defer heavy work:**

```objc
// Good: Minimal work in drawRect
- (void)drawRect:(CGRect)rect {
    [self.image drawInRect:rect];  // Cached image
}

// Bad: Heavy work in drawRect
- (void)drawRect:(CGRect)rect {
    UIImage *image = [self loadAndProcessImage];  // Called every frame!
    [image drawInRect:rect];
}
```

---

## Related Rules

- [Blocks and GCD](../language/blocks-gcd.md) - Async patterns
- [ARC Memory Management](../language/arc-memory-management.md) - Retain cycles

---

## References

- [Apple: Instruments User Guide](https://developer.apple.com/documentation/xcode/instruments)
- [Apple: Performance Overview](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
