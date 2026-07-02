- **Use companion object `apply` methods** for pure functional construction:  
  ```scala
  // Good: Pure functional constructor
  object DatabaseConfig {
    def apply(host: String, port: Int): DatabaseConfig = {
      DatabaseConfig(host, port, timeout = 30.seconds, pool = 10)
    }
  }
  
  // Bad: Imperative builder pattern
  class DatabaseConfigBuilder {
    var host: String = _
    var port: Int = _
    def build(): DatabaseConfig = ???
  }
  ```

- **Use case class `copy` for immutable modifications** (prefer for configuration, avoid in hot paths):  
  ```scala
  // Good: Configuration building (done once at startup)
  val baseConfig = DatabaseConfig("localhost", 5432)
  val prodConfig = baseConfig.copy(host = "prod.db.com", pool = 50)
  
  // NOTE: Performance consideration: In hot paths, consider mutable builders
  // if you're creating many objects and allocation is a bottleneck
  class MutableConfigBuilder {
    private var host: String = "localhost"
    private var port: Int = 5432
    def setHost(h: String): this.type = { host = h; this }
    def setPort(p: Int): this.type = { port = p; this }
    def build(): DatabaseConfig = DatabaseConfig(host, port)
  }
  ```

- **Compose configurations functionally** using pure functions:  
  ```scala
  def withLogging(config: ServiceConfig): ServiceConfig = 
    config.copy(logging = true)
    
  def withRetries(retries: Int)(config: ServiceConfig): ServiceConfig =
    config.copy(retryPolicy = Some(RetryPolicy(retries)))
  
  // Usage: Function composition
  val finalConfig = baseConfig
    .pipe(withLogging)
    .pipe(withRetries(3))
  ```

- **Use `empty` and `default` values** for pure construction:  
  ```scala
  object SparkConfig {
    val empty: SparkConfig = SparkConfig(cores = 1, memory = "1g")
    val default: SparkConfig = SparkConfig(cores = 4, memory = "8g")
    
    def minimal: SparkConfig = empty
    def recommended: SparkConfig = default.copy(cores = 8, memory = "16g")
  }
  ```

- **Avoid mutable builders** - use functional composition instead:  
  ```scala
  // Good: Functional composition
  val config = BaseConfig.empty
    .withDatabase("localhost", 5432)
    .withTimeout(30.seconds)
    .withRetries(3)
  
  // Bad: Mutable builder
  val builder = new ConfigBuilder()
  builder.setHost("localhost")
  builder.setPort(5432)
  val config = builder.build()
  ```

- **Use smart constructors for validation**:  
  ```scala
  object UserId {
    def fromString(s: String): Either[ValidationError, UserId] = {
      if (s.nonEmpty && s.length <= 50) Right(UserId(s))
      else Left(ValidationError("Invalid user ID"))
    }
  }
  ```

- **Prefer factory methods that return `Either` for fallible construction**:  
  ```scala
  object DatabaseConnection {
    def create(config: DbConfig): Either[ConnectionError, DatabaseConnection] = {
      Try {
        new DatabaseConnection(config.url, config.credentials)
      }.toEither.left.map(e => ConnectionError(e.getMessage))
    }
  }
```

---

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../../../generic/code-quality/core-principles.md) - Universal principles (pure functions, immutability, make illegal states unrepresentable)

**Scala-Specific:**
- This file provides Scala-specific functional construction patterns (companion object apply, case class copy, smart constructors)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
