# Error Handling (NSError)

Use NSError for expected failures. Pass `NSError **` as last parameter. Check return value before inspecting error.

---

## Use NSError ** as Last Parameter

**Standard Cocoa pattern for methods that can fail:**

```objc
// Good: Return indicates success; error populated on failure
- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error {
    if (![self validate]) {
        if (error) {
            *error = [NSError errorWithDomain:@"MyApp" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Invalid state"}];
        }
        return NO;
    }
    return YES;
}

// Caller: Check return first
NSError *err = nil;
if (![object saveToURL:url error:&err]) {
    [self handleError:err];
    return;
}
```

---

## Check Return Value Before Accessing Error

**Only use NSError when method indicates failure:**

```objc
// Good: Check return, then use error
NSError *error = nil;
NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
if (!data) {
    NSLog(@"Failed: %@", error.localizedDescription);
    return;
}
// Use data safely

// Bad: Accessing error without checking return
NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
NSLog(@"Error: %@", error);  // Error may be unset if data succeeded
```

---

## Use Completion Handlers for Async Errors

**Pass NSError in completion block for async operations:**

```objc
// Good: Error in completion
- (void)loadUserWithId:(NSString *)userId completion:(void (^)(User * _Nullable, NSError * _Nullable))completion {
    [self.apiClient fetchWithId:userId completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        User *user = [User userFromJSON:json];
        completion(user, nil);
    }];
}
```

---

## Define Custom Error Domains and Codes

**Use constants for domain and codes:**

```objc
// Good: Centralized error definitions
NSString *const MyAppErrorDomain = @"com.myapp.errors";

typedef NS_ENUM(NSInteger, MyAppErrorCode) {
    MyAppErrorCodeInvalidInput = 1000,
    MyAppErrorCodeNetworkFailure = 1001,
    MyAppErrorCodeParseFailure = 1002
};

- (NSError *)invalidInputError {
    return [NSError errorWithDomain:MyAppErrorDomain
                             code:MyAppErrorCodeInvalidInput
                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid input"}];
}
```

---

## Use NSError for Expected Failures; Exceptions for Programming Errors

**Reserve NSException for truly exceptional cases:**

```objc
// Good: NSError for expected failures (network, parse, validation)
- (BOOL)parseJSON:(NSData *)data error:(NSError **)error { ... }

// Good: Exception for programming errors (assertion failure, precondition)
if (index >= self.items.count) {
    [NSException raise:NSRangeException format:@"Index %lu out of bounds", (unsigned long)index];
}
```

---

## Related Rules

- [Nullability and Swift Interop](nullability-swift-interop.md) - _Nullable in completion blocks
- [Generic Error Handling](references/rules/common/generic/error-handling/universal-patterns.md) - Fail fast, explicit errors

---

## References

- [Apple: Error Handling Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ErrorHandlingCocoa/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
