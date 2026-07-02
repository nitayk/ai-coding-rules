# Blocks and Grand Central Dispatch

Use GCD for concurrency. Never block the main thread. Use weak-strong dance when blocks capture self.

---

## Never Block the Main Thread

**Offload heavy work to background queues:**

```objc
// Good: Background work, main queue for UI
- (void)loadUserData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [self fetchDataFromNetwork];
        NSDictionary *parsed = [self parseJSON:data];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUIWithData:parsed];
        });
    });
}

// Bad: Blocking main thread
- (void)loadUserData {
    NSData *data = [self fetchDataFromNetwork];  // Blocks UI!
    [self updateUIWithData:[self parseJSON:data]];
}
```

---

## Use Weak-Strong Dance in Blocks

**Blocks capture variables by reference. Use weak-strong pattern to avoid retain cycles:**

```objc
// Good: Weak-strong dance
- (void)loadDataWithCompletion:(void (^)(NSArray *, NSError *))completion {
    __weak typeof(self) weakSelf = self;
    [self.apiService fetchWithCompletion:^(NSArray *data, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        [strongSelf processData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(data, error);
        });
    }];
}

// Bad: Strong self capture creates retain cycle
- (void)loadDataWithCompletion:(void (^)(NSArray *, NSError *))completion {
    [self.apiService fetchWithCompletion:^(NSArray *data, NSError *error) {
        [self processData:data];  // Retain cycle: self -> apiService -> block -> self
        completion(data, error);
    }];
}
```

---

## Prefer dispatch_async Over dispatch_sync on Main Queue

**Avoid deadlocks from sync dispatch to current queue:**

```objc
// Good: Async to main queue
dispatch_async(dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
});

// Bad: Sync from main to main - deadlock if already on main
dispatch_sync(dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
});
```

---

## Use Serial Queues for Shared Mutable State

**Protect shared state with a serial queue:**

```objc
// Good: Serial queue for thread-safe access
@interface DataCache : NSObject
@property (nonatomic, strong) dispatch_queue_t syncQueue;
@property (nonatomic, strong) NSMutableDictionary *cache;
@end

@implementation DataCache
- (instancetype)init {
    if (self = [super init]) {
        _syncQueue = dispatch_queue_create("com.app.datacache", DISPATCH_QUEUE_SERIAL);
        _cache = [NSMutableDictionary new];
    }
    return self;
}

- (void)setObject:(id)obj forKey:(id)key {
    dispatch_async(self.syncQueue, ^{
        self.cache[key] = obj;
    });
}

- (id)objectForKey:(id)key {
    __block id result;
    dispatch_sync(self.syncQueue, ^{
        result = self.cache[key];
    });
    return result;
}
@end
```

---

## Use @autoreleasepool in Loops with Many Allocations

**Prevent memory buildup in tight loops:**

```objc
// Good: Autorelease pool per iteration
for (NSDictionary *item in largeArray) {
    @autoreleasepool {
        NSString *processed = [self processItem:item];
        [self save:processed];
    }
}
```

---

## Related Rules

- [ARC Memory Management](arc-memory-management.md) - Weak references, retain cycles
- [iOS Best Practices](../ios/ios-best-practices.md) - UIKit main-thread requirements

---

## References

- [Apple: Working with Blocks](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html)
- [Apple: Concurrency Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
