# Swift Package Manager (canonical dependency manager)

Swift Package Manager (SPM) is the official dependency and build tool for Swift, integrated into both `swift` CLI and Xcode 11+. For all new code SPM is the default; CocoaPods and Carthage are legacy and should only be used when a specific dependency hasn't published an SPM manifest (an increasingly rare case).

Source: [Swift Package Manager docs](https://www.swift.org/documentation/package-manager/) · [Apple — Swift Packages in Xcode](https://developer.apple.com/documentation/xcode/swift-packages).

---

## Package.swift is the manifest

A SwiftPM package is any directory with a `Package.swift` at its root. The manifest declares products (libraries/executables), targets, dependencies, and per-target settings.

```swift
// ✅ Good: minimal modern manifest — explicit swift-tools-version, platforms,
// products, and per-target swiftSettings for Swift 6 features.
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeedKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FeedKit", targets: ["FeedKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "FeedKit",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FeedKitTests",
            dependencies: ["FeedKit"]
        ),
    ]
)
```

```swift
// ❌ Bad: missing platforms, missing swift-tools-version comment,
// wildcard dependency that breaks reproducibility
import PackageDescription

let package = Package(
    name: "FeedKit",
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", branch: "main"),
    ],
    targets: [.target(name: "FeedKit")]
)
```

The `// swift-tools-version:` comment on the **first line** is mandatory — SwiftPM uses it to pick the manifest API version.

---

## Version requirements: pin with care

SPM uses semantic version ranges. Use the most conservative form that compiles:

```swift
// ✅ Good: `from:` allows minor + patch updates (1.x), blocks breaking 2.0
.package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),

// ✅ Good: exact pin for libraries with unreliable SemVer
.package(url: "https://github.com/example/quirky-lib", exact: "0.9.2"),

// ✅ Good: range when you need an upper bound below the next major
.package(url: "https://github.com/example/lib", "1.5.0"..<"1.10.0"),
```

```swift
// ❌ Bad: branch dependency — non-reproducible, breaks every push to main
.package(url: "https://github.com/example/lib", branch: "main"),

// ❌ Bad: revision pin without comment — future maintainers can't tell why
.package(url: "https://github.com/example/lib", revision: "a1b2c3d4"),
```

**`Package.resolved` must be committed** for executable targets and apps — it locks the exact resolved versions. Libraries traditionally `.gitignore` it (consumer apps resolve their own), but Apple now recommends committing it for libraries too so CI builds are reproducible.

---

## Multi-target layout for app modularization

The single biggest leverage SPM provides over CocoaPods is **first-class local modularization**. Split your app into a workspace + local packages:

```
MyApp/
├── MyApp.xcodeproj           # thin app shell
├── MyApp/                    # AppDelegate / entry point only
└── Packages/
    ├── FeedFeature/Package.swift
    ├── ProfileFeature/Package.swift
    ├── Networking/Package.swift
    └── DesignSystem/Package.swift
```

```swift
// ✅ Good: feature module depends on lower-level modules, never on the app
let package = Package(
    name: "FeedFeature",
    platforms: [.iOS(.v17)],
    products: [.library(name: "FeedFeature", targets: ["FeedFeature"])],
    dependencies: [
        .package(path: "../Networking"),
        .package(path: "../DesignSystem"),
    ],
    targets: [
        .target(name: "FeedFeature", dependencies: ["Networking", "DesignSystem"]),
        .testTarget(name: "FeedFeatureTests", dependencies: ["FeedFeature"]),
    ]
)
```

Local packages give you:
- Fast incremental builds (each module compiles independently)
- Clear dependency direction (compiler enforces the graph)
- Per-module Swift settings — e.g. enable Swift 6 language mode in clean modules first
- A natural unit for unit tests (`.testTarget` lives next to the code)

---

## Per-target swiftSettings for incremental Swift 6 adoption

`swiftSettings:` is the per-target lever for upcoming features and language mode — essential for the Swift 6 strict-concurrency migration (see `strict-concurrency-migration.md`).

```swift
.target(
    name: "Networking",
    swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),  // Phase 1: warnings
    ]
),
.target(
    name: "Models",
    swiftSettings: [
        .swiftLanguageMode(.v6),                          // Phase 2: errors for this module
    ]
),
```

The mix-and-match is the point: enable strict concurrency on one module at a time without breaking the whole package.

---

## When CocoaPods or Carthage is still required

Reach for legacy tooling only when:

| Situation | Why |
|---|---|
| A vendor SDK only ships a `.podspec` (no `Package.swift`) | No alternative — file an issue upstream |
| Pre-built binary XCFramework distribution | SPM supports `.binaryTarget`, but some vendors haven't migrated their CDN URLs |
| Existing project with hundreds of pods | Migration cost; do it incrementally |

For a fresh project, assume **SPM-only** and only add a Podfile if you hit one of the above. Most Apple-platform OSS libraries (Alamofire, SnapKit, Lottie, etc.) ship native SPM support.

---

## Common commands

```bash
swift package init --type library      # scaffold a new package
swift build                            # build all targets
swift test                             # run all tests
swift package resolve                  # update Package.resolved
swift package update                   # update within version constraints
swift package show-dependencies        # graph the dep tree (use --format dot for visualization)
swift package describe --type json     # inspect the resolved package model
```

In Xcode: **File → Add Package Dependencies…** for remote URLs; drag a local package directory into the workspace navigator to add a local package.

---

## Related rules

- [Strict-Concurrency Migration](../language/strict-concurrency-migration.md) — uses per-target `swiftSettings`
- [swift-format + SwiftLint](swift-format-and-swiftlint.md) — both run as SPM plugins

---

## References

- [Swift Package Manager docs](https://www.swift.org/documentation/package-manager/)
- [Apple — Swift Packages in Xcode](https://developer.apple.com/documentation/xcode/swift-packages)
- [PackageDescription API](https://developer.apple.com/documentation/packagedescription)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
