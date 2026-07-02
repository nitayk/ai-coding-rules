# Use stdlib `Base64` and `HexFormat`

Kotlin 2.2 promoted `kotlin.io.encoding.Base64` and `kotlin.text.HexFormat` to **stable** ([What's new in Kotlin 2.2](https://kotlinlang.org/docs/whatsnew22.html)). They replace the two most common hand-rolled / Android-only helpers in mobile codebases:

- `android.util.Base64` — Android-only, untestable on the JVM, ergonomically awkward (`Base64.encodeToString(bytes, Base64.NO_WRAP)`).
- Bespoke hex helpers — every codebase has 2-3 copies of `fun ByteArray.toHex(): String = joinToString(""){ "%02x".format(it) }`.

Both are now unnecessary. Use stdlib.

---

## Base64

```kotlin
// ✅ Good: stdlib Base64 (Kotlin 2.2 stable)
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi // still required pre-2.2; remove on 2.2+

val encoded: String = Base64.encode(bytes)
val decoded: ByteArray = Base64.decode(encoded)

// URL-safe variant (no padding)
val urlEncoded = Base64.UrlSafe.encode(bytes)

// MIME (line-wrapped at 76 chars)
val mimeEncoded = Base64.Mime.encode(bytes)
```

```kotlin
// ❌ Bad: android.util.Base64 — Android-only, untestable on JVM unit tests
import android.util.Base64
val encoded = Base64.encodeToString(bytes, Base64.NO_WRAP)
val decoded = Base64.decode(encoded, Base64.NO_WRAP)
```

```kotlin
// ❌ Bad: java.util.Base64 (works but loses multiplatform option, and stdlib is now idiomatic)
val encoded = java.util.Base64.getEncoder().encodeToString(bytes)
```

**Variants** map cleanly onto the existing JDK / Android equivalents:

| Use case | stdlib | Old equivalent |
|----------|--------|----------------|
| Standard | `Base64.encode/decode` | `java.util.Base64.getEncoder()` / `android.util.Base64.DEFAULT` |
| URL-safe, no padding | `Base64.UrlSafe.encode/decode` | `android.util.Base64.URL_SAFE \| NO_PADDING` |
| MIME (76-char wrap) | `Base64.Mime.encode/decode` | `java.util.Base64.getMimeEncoder()` |

---

## HexFormat

```kotlin
// ✅ Good: stdlib HexFormat (Kotlin 2.2 stable)
val hex: String = bytes.toHexString()                       // default lower-case
val upper: String = bytes.toHexString(HexFormat.UpperCase)
val bytes2: ByteArray = "deadbeef".hexToByteArray()

// Custom format: colon-separated, upper-case (e.g. for hex dumps)
val fmt = HexFormat {
    bytes {
        bytesPerGroup = 1
        groupSeparator = ":"
    }
    upperCase = true
}
val mac: String = macAddress.toHexString(fmt) // "DE:AD:BE:EF:00:01"
```

```kotlin
// ❌ Bad: hand-rolled hex (every project has this; 3 copies, all slightly different)
fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it) }
fun String.fromHex(): ByteArray = chunked(2).map { it.toInt(16).toByte() }.toByteArray()
```

The hand-rolled versions allocate a `Formatter` per byte and offer no upper/lower-case or grouping control. The stdlib version is also significantly faster on large inputs.

---

## Migration notes

- The `@OptIn(ExperimentalEncodingApi::class)` opt-in **is no longer needed on Kotlin 2.2+** for `Base64` and `HexFormat` — they're stable. Strip the opt-ins as part of the upgrade.
- For modules still on Kotlin <2.2, you can use the API but must keep the opt-in until the toolchain bumps.
- On Android specifically: there is no reason to keep `android.util.Base64` in new code — stdlib `Base64` works identically and unit-tests cleanly on the JVM.

---

## Related rules

- [Style Guide](style-guide.md) — Idiomatic Kotlin
- [compilerOptions DSL](../android/compiler-options-dsl.md) — Kotlin 2.2 toolchain changes

---

## References

- [What's new in Kotlin 2.2](https://kotlinlang.org/docs/whatsnew22.html) — `Base64` and `HexFormat` stable
- [kotlin.io.encoding.Base64](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io.encoding/-base64/) — stdlib API reference
- [kotlin.text.HexFormat](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/-hex-format/) — stdlib API reference

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
