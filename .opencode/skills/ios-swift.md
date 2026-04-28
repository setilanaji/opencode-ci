# iOS & macOS / Swift Skill

## Naming — Swift API Design Guidelines
- **Clarity at the point of use** is the primary goal. Prefer `removeBoxes(at: indices)` over `remove(indices)`.
- Omit needless words: `allViews.removeElement(view)` → `allViews.remove(view)`.
- Name functions by their side-effects: mutating verbs (`sort`, `append`), non-mutating nouns or past participles (`sorted`, `appending`).
- Boolean properties and parameters read as assertions: `isEmpty`, `isEnabled`, `hasPrefix`.
- Protocol names: capabilities end in `-able`/`-ible`/`-ing` (`Equatable`, `Sendable`); types/roles use nouns (`Collection`, `Iterator`).
- Avoid abbreviations not in common use. `URL`, `ID`, `HTTP` are fine; `mgr`, `vc`, `btn` are not.
- Label every parameter unless the role is obvious at the call site (`min(x, y)` is fine; `dismiss(true)` is not).

## Swift Fundamentals
- Prefer `struct` for value semantics; use `class` only when identity, inheritance, or reference semantics are required.
- Prefer `let` over `var`; flag any `var` that is never mutated.
- Use `guard` for early exits instead of deeply nested `if` blocks.
- Never force-unwrap (`!`) in production code. Use `guard let`, `if let`, or provide a safe default.
- Never use `try!` or `as!` in production code.
- Prefer `switch` with exhaustive matching over chains of `if-else` on enums.
- Avoid `@discardableResult` on functions whose return value is meaningful.
- Use `typealias` to clarify complex types; name them at the use-site.

## Error Handling
- Define domain-specific `Error` enums with associated values; never throw `NSError` from pure Swift code.
- Propagate errors with `throws`; only use `Result<T, E>` when the call site must handle both branches simultaneously.
- Swift 6: use typed throws (`throws(MyError)`) when the error type is known and stable.
- Never silence errors with empty `catch {}`. Log or rethrow.
- Use `defer` for cleanup that must run regardless of throw path.

## Concurrency — Swift Structured Concurrency
- Prefer `async`/`await` over completion handlers, NotificationCenter callbacks, and Combine pipelines for new code.
- Use `async let` for independent parallel work; use `TaskGroup` for dynamic parallelism.
- Isolate shared mutable state behind an `actor`; never use a class with a `DispatchQueue` lock for new code.
- Mark all UI-touching code `@MainActor`. Annotate entire `ViewController`/`View` types, not individual methods.
- Avoid `Task.detached` unless you explicitly need to escape structured scope — and document why.
- Mark types crossing concurrency boundaries as `Sendable`; use `@unchecked Sendable` only with a comment explaining the manual synchronization.
- Enable Swift 6 complete concurrency checking (`SWIFT_STRICT_CONCURRENCY = complete`) and fix all warnings before they become errors.
- Cancel tasks when the owning object is deallocated; store `Task` handles and call `.cancel()` in `deinit` or `onDisappear`.

## SwiftUI
- Keep `body` under ~30 lines; extract named subviews or `ViewBuilder` functions.
- Swift 5.9+: use `@Observable` (the Observation framework macro) for view models instead of `ObservableObject`/`@Published`.
- Legacy code: `@StateObject` for view-owned models, `@ObservedObject` for injected models, never `@ObservedObject` for models created inside the view.
- Pass values down via the environment (`@Environment`, `@EnvironmentObject`) only for truly cross-cutting concerns (theme, locale, auth state).
- Always supply stable, unique `id` values in `ForEach`; never use index-based identity on mutable lists.
- Use `ViewModifier` to encapsulate reusable style/behavior; avoid copy-pasting modifier chains.
- Prefer `List` and `LazyVStack`/`LazyHStack` over `ScrollView + VStack` for large data sets.
- Animate with `.animation(_:value:)` (value-driven) rather than the deprecated implicit `.animation(_:)`.
- Use `PreferenceKey` for child-to-parent communication, not callbacks through closures stored in view state.
- `.task { }` for async work tied to a view's lifetime — it is automatically cancelled on disappear.

## AppKit / macOS
- Respect the macOS Human Interface Guidelines: use standard controls (`NSButton`, `NSTextField`) before building custom ones.
- Use `NSWindowController` + `NSViewController` pairs; keep window management out of app delegates.
- Implement `NSUserInterfaceValidations` for menu item and toolbar item enable/disable logic.
- Provide full keyboard navigation; every interactive control must be reachable via Tab and have a key equivalent where appropriate.
- Support Dark Mode: use semantic colors (`NSColor.labelColor`, `NSColor.controlBackgroundColor`) and asset catalog color sets; never hardcode hex.
- Support Dynamic Type / large text by using system fonts (`NSFont.preferredFont(forTextStyle:)`) and auto-layout.
- App Sandbox: declare only the entitlements your app actually uses; request file access via `NSOpenPanel`/`NSSavePanel` rather than bookmarking all paths.
- For background daemons or helpers, use `SMAppService` (macOS 13+) instead of the deprecated Launch Services API.

## UIKit / iOS
- Prefer `UIViewController` composition (child view controllers) over massive single controllers.
- Use `UIContentConfiguration` for custom `UICollectionView`/`UITableView` cells (iOS 14+).
- Adopt `UISheetPresentationController` for bottom sheets (iOS 15+) instead of third-party libraries.
- Scene-based lifecycle (`UIWindowSceneDelegate`) for multi-window iPad support.
- Use `UIMenu` and `UIAction` for context menus and toolbar items; avoid custom gesture recogniser–driven menus.

## Memory Management
- Capture lists in closures: use `[weak self]` when the closure outlives the current scope; use `[unowned self]` only when you can guarantee the object lives at least as long as the closure.
- Instruments → Leaks and Allocations: run before every major release; fix all leaked objects.
- Large objects (images, data buffers): load lazily, cache with `NSCache` (auto-evicting), and release on memory warnings (`applicationDidReceiveMemoryWarning` / `.onReceive(NotificationCenter...)`).
- Avoid `@escaping` closures storing `self` strongly in long-lived objects (coordinators, singletons).

## Security
- Store credentials, tokens, and keys in the **Keychain** (`SecItemAdd`/`SecItemCopyMatching`); never in `UserDefaults`, plists, or source code.
- Never log sensitive data (tokens, PII). Use `os_log` with `%{private}` format specifiers where needed.
- App Transport Security (ATS): do not add `NSAllowsArbitraryLoads` without a documented exception approved by your security team.
- Validate and sanitize all data received from the network before use; never trust server-provided type strings to drive `NSClassFromString`.
- Use `CryptoKit` for hashing and encryption; avoid CommonCrypto directly in new code.
- Request only the permissions your feature actually needs; request them contextually (just-in-time), not at launch.
- Enable Hardened Runtime for macOS apps distributed outside the App Store.
- **Data protection at rest**: set `FileProtectionType.completeUnlessOpen` (minimum) on files containing PII or credentials; use `.complete` for files not needed while the device is locked. Apply via `FileManager` attributes or `URLResourceValues.fileProtection`.
- **Deep links and URL schemes**: always validate the host, path, and parameters of incoming URLs before acting on them. Prefer Universal Links (HTTPS-backed) over custom URL schemes — they cannot be hijacked by other apps. Never execute arbitrary actions based solely on URL parameters without authentication checks.
- **WKWebView**: disable JavaScript (`preferences.javaScriptEnabled = false`) in web views that display static content. Use `WKContentRuleList` to block mixed content. Never inject user-controlled strings into `evaluateJavaScript`.
- **Biometric authentication**: use `LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` for sensitive actions; always provide a fallback and handle `LAError.userFallback`. Store the protected credential in the Keychain with `SecAccessControlCreateWithFlags` bound to biometric presence, not in memory.
- **App Attest / DeviceCheck**: use `DCAppAttestService` (iOS 14+) to verify device integrity server-side before issuing high-value tokens or capabilities.
- **Pasteboard**: avoid writing sensitive data to `UIPasteboard.general`; use a custom pasteboard with `withUniqueName()` and set an expiry time if cross-app sharing is needed.

## Accessibility
- Every interactive element must have an `accessibilityLabel`; image-only buttons require explicit labels.
- Support Dynamic Type: use `UIFont.preferredFont(forTextStyle:)` / `.font(.body)` in SwiftUI; test at the largest accessibility size.
- Provide `accessibilityHint` for actions that are not self-evident from the label.
- Group related elements with `accessibilityElement(children: .combine)` or `AccessibilityGroup`.
- Test with VoiceOver on device before every release; automated `XCUIAccessibilityAudit` in Xcode 15+ catches common issues.
- Minimum tap target: 44×44 pt (Apple HIG).

## Privacy
- **Privacy Manifest** (`PrivacyInfo.xcprivacy`): required for all App Store submissions since May 2024. Declare every privacy-sensitive API your app (and its third-party SDKs) uses, the reason for each use, and whether data is collected and linked to the user. Missing or incomplete manifests result in App Store rejection.
- Collect the minimum data necessary. Do not track data your feature does not need.
- Required Reason APIs: `UserDefaults`, `FileTimestamp`, `SystemBootTime`, `DiskSpace`, and `ActiveKeyboards` APIs require a declared reason in the manifest; flag any use of these APIs in a PR that lacks a corresponding manifest entry.
- On-device processing preferred: perform sensitive computation (face detection, document scanning) with Apple frameworks (`Vision`, `VisionKit`) rather than uploading raw data to a server.
- Location: use `CLLocationUpdate.liveUpdates()` (iOS 17+) or `requestWhenInUseAuthorization` with the minimum accuracy needed (`reducedAccuracy` where precise location is not required). Never request `Always` authorization unless the core feature demands background location.

## Localization
- All user-facing strings via `String(localized:)` (Swift 5.7+) or `NSLocalizedString`; zero hardcoded English in UI code.
- Use String Catalogs (`.xcstrings`, Xcode 15+) for centralized translation management.
- Format dates, numbers, and currencies with `Date.FormatStyle`, `NumberFormatter`, or `Measurement`; never construct locale-sensitive strings manually.
- Test with pseudolanguages (Double-Length, Accented) and RTL (Arabic) before release.

## Testing
- Unit test business logic and model layer with **Swift Testing** (Xcode 16+, `import Testing`); use `@Test`, `#expect`, `#require`.
- Integration and UI tests with `XCTest` + `XCUIApplication`.
- Mock networking with `URLProtocol` subclasses or protocol-based abstractions; never hit real endpoints in unit tests.
- Snapshot test critical UI components with a snapshot library; commit reference images and review diffs in PRs.
- Aim for deterministic tests: inject `Clock` / `Date` / `UUID` dependencies rather than using `Date()` or `UUID()` directly.

## Architecture
- Separate concerns: UI layer (SwiftUI/UIKit), domain/business logic, and data/network layers must not bleed into each other.
- Use dependency injection (initialiser injection preferred); avoid service locators and implicit singletons.
- Coordinators or `NavigationStack` path bindings for navigation; views must not push/present themselves.
- Model types are `Sendable` value types (`struct` or `enum`); mutable shared state lives in actors.
- Keep view models free of `import UIKit`/`import SwiftUI`; they should be testable without a simulator.

## Performance
- Profile with **Instruments** (Time Profiler, Allocations, Hangs) before optimizing; do not guess.
- Main thread: zero synchronous I/O, zero blocking network calls, zero heavy computation.
- Use `lazy var` for expensive properties initialized once; use `@MainActor lazy` in SwiftUI view models where appropriate.
- Image assets: use asset catalogs with appropriate scale variants; use `AsyncImage` or `URLSession`-backed caching for remote images.
- Avoid creating `DateFormatter`, `NumberFormatter`, or `JSONDecoder` instances inside loops; they are expensive to instantiate.
- Swift 5.9+ `consume` and `borrow` ownership annotations in hot paths to eliminate unnecessary copies.

### App Launch Time
- `application(_:didFinishLaunchingWithOptions:)` and `scene(_:willConnectTo:)` must complete in under 400 ms (hard watchdog limit is ~20 s but perceived slowness kicks in far earlier). Flag any synchronous network call, database migration, or heavy initializer in the launch path.
- Defer non-critical setup (analytics init, feature flag fetch, non-visible view construction) to after first frame render using `Task { }` on `@MainActor` or `DispatchQueue.main.async`.
- Minimize static initializers (`static let` with closures, `+initialize`) — they run before `main()` and cannot be deferred.
- Use `os_signpost` to instrument custom launch phases; measure with Instruments → App Launch template.

### Core Data
- Always perform writes on a background `NSManagedObjectContext` (`newBackgroundContext()` or `performBackgroundTask`); never write on `viewContext`.
- Use `NSBatchInsertRequest` and `NSBatchUpdateRequest` for bulk operations — they bypass the context and are orders of magnitude faster.
- Fetch only what you display: set `fetchBatchSize` (typically 20–50) on `NSFetchRequest` to fault objects in pages rather than loading the full result set.
- Use `NSFetchedResultsController` for table/collection views driven by Core Data; it handles incremental updates without manual diffing.
- Lightweight migrations only unless a custom mapping model is required; always test migration on a copy of production data before shipping.

### Energy Efficiency
- Use `BGTaskScheduler` (`BGAppRefreshTask`, `BGProcessingTask`) for all background work (iOS 13+); never rely on `beginBackgroundTask` for periodic jobs.
- Location: use significant-location change monitoring (`startMonitoringSignificantLocationChanges`) for coarse tracking; continuous GPS drains battery within hours.
- Batch network requests where possible; avoid polling — use push notifications or server-sent events.
- Coalesce `UserDefaults` writes; `synchronize()` is a no-op since iOS 12 but frequent individual writes still cause I/O. Batch updates with a debounce if the value changes at high frequency.
- Flag any `Timer` with an interval under 1 second running in the background — use tolerance (`timer.tolerance`) to allow OS coalescing.
