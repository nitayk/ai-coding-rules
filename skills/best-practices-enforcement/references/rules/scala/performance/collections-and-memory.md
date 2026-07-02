# Scala Collections and Memory Performance

Choose the right collections for your access patterns. Avoid unnecessary allocations and optimize memory usage.

---

## Choose Collections Based on Access Patterns

**Select collections based on your access patterns:**

```scala
// Good: Vector for random access
def getItem(items: Vector[Item], index: Int): Option[Item] = {
  items.lift(index)  // O(log32(n)) - efficient random access
}

// Good: List for prepend operations
def prependItems(newItems: List[Item], existing: List[Item]): List[Item] = {
  newItems ::: existing  // O(1) prepend
}

// Good: ArrayBuffer for mutable indexed collections
def buildMutableList(size: Int): ArrayBuffer[Item] = {
  val buffer = ArrayBuffer.empty[Item]
  buffer.sizeHint(size)  // Preallocate
  // ... add items
  buffer
}

// Bad: Wrong collection for access pattern
def getItem(items: List[Item], index: Int): Option[Item] = {
  items.lift(index)  // O(n) - slow for random access!
}
```

---

## Use Views to Avoid Intermediate Allocations

**Use `.view` for chained operations:**

```scala
// Good: View avoids intermediate collections
def processLargeDataset(items: List[Item]): List[ProcessedItem] = {
  items.view
    .filter(_.isActive)
    .map(transform)
    .filter(_.isValid)
    .toList  // Materialize only at the end
}

// Bad: Creates intermediate collections
def processLargeDataset(items: List[Item]): List[ProcessedItem] = {
  items
    .filter(_.isActive)      // New List
    .map(transform)          // New List
    .filter(_.isValid)      // New List
    .toList                  // Final List
}
```

---

## Preallocate Capacity for Builders

**Use builders or mutable buffers for repeated appends:**

```scala
// Good: Builder for efficient construction
def buildLargeList(items: Seq[Item]): List[ProcessedItem] = {
  val builder = List.newBuilder[ProcessedItem]
  builder.sizeHint(items.size)  // Preallocate
  
  items.foreach { item =>
    builder += processItem(item)
  }
  
  builder.result()
}

// Good: ArrayBuffer for mutable collection
def buildMutableCollection(items: Seq[Item]): ArrayBuffer[ProcessedItem] = {
  val buffer = ArrayBuffer.empty[ProcessedItem]
  buffer.sizeHint(items.size)
  
  items.foreach { item =>
    buffer += processItem(item)
  }
  
  buffer
}

// Bad: Repeated concatenation
def buildLargeList(items: Seq[Item]): List[ProcessedItem] = {
  var result = List.empty[ProcessedItem]
  items.foreach { item =>
    result = result :+ processItem(item)  // O(n) each time!
  }
  result
}
```

---

## Avoid Boxing with Specialized Types

**Use `@specialized` or avoid generic collections for primitives:**

```scala
// Good: Specialized for primitives
class SpecializedProcessor[@specialized(Int, Long) T] {
  def process(items: Array[T]): Array[T] = {
    // No boxing overhead
    items.map(transform)
  }
}

// Good: Use Array for primitives
def processInts(ints: Array[Int]): Array[Int] = {
  ints.map(_ * 2)  // No boxing
}

// Bad: Generic collection causes boxing
def processInts(ints: List[Int]): List[Int] = {
  ints.map(_ * 2)  // Boxing/unboxing overhead
}
```

---

## Use LazyList for Large Sequences

**Use `LazyList` for memory-efficient sequences:**

```scala
// Good: LazyList for large sequences
def generateLargeSequence: LazyList[Int] = {
  LazyList.from(1).map(expensiveComputation)
}

// Can take first N without computing all
val first100 = generateLargeSequence.take(100).toList

// Good: Lazy evaluation with view
def processLargeDataset(items: List[Item]): LazyList[ProcessedItem] = {
  items.to(LazyList)
    .map(transform)
    .filter(_.isValid)
}

// Bad: Eager evaluation loads everything
def processLargeDataset(items: List[Item]): List[ProcessedItem] = {
  items
    .map(transform)      // Computes all immediately
    .filter(_.isValid)
}
```

---

## Reuse Buffers When Possible

**Reuse mutable buffers to reduce allocations:**

```scala
// Good: Reusable buffer
class DataProcessor {
  private val buffer = ArrayBuffer.empty[Item]
  
  def processBatch(items: Seq[Item]): Seq[ProcessedItem] = {
    buffer.clear()
    buffer.sizeHint(items.size)
    
    items.foreach { item =>
      buffer += processItem(item)
    }
    
    buffer.toSeq
  }
}

// Bad: New buffer every time
def processBatch(items: Seq[Item]): Seq[ProcessedItem] = {
  val buffer = ArrayBuffer.empty[Item]  // New allocation
  items.foreach { item =>
    buffer += processItem(item)
  }
  buffer.toSeq
}
```

---

## Avoid Retaining Large Structures

**Don't hold references to large structures longer than needed:**

```scala
// Good: Process and release
def processLargeDataset(data: LargeDataset): ProcessedResult = {
  val processed = transform(data)
  // data can be GC'd after this point
  aggregate(processed)
}

// Good: Use local scope
def processData(): Unit = {
  val largeData = loadLargeDataset()
  val result = processLargeDataset(largeData)
  saveResult(result)
  // largeData goes out of scope
}

// Bad: Holding reference unnecessarily
class DataProcessor {
  private var largeData: Option[LargeDataset] = None  // Held in memory!
  
  def process(): Unit = {
    largeData = Some(loadLargeDataset())
    // Large data stays in memory even after processing
  }
}
```

---

## Use Parallel Collections Appropriately

**Use parallel collections only when overhead is justified:**

```scala
// Good: Parallel collection for large dataset
def processLargeDataset(items: Vector[Item]): Vector[ProcessedItem] = {
  if (items.size > 10000) {
    items.par.map(processItem).seq  // Parallel for large collections
  } else {
    items.map(processItem)  // Sequential for small collections
  }
}

// Bad: Parallel for small collections
def processSmallDataset(items: Vector[Item]): Vector[ProcessedItem] = {
  items.par.map(processItem).seq  // Overhead > benefit for small collections
}
```

---

## Related Rules

**Universal Principles:**
- [Generic Performance Principles](../../../../generic/performance/core-principles.md) - Universal performance principles (algorithm complexity, memory management, batching)

**Scala-Specific:**
- [Lazy Evaluation and Productivity](../language/lazy-evaluation-and-productivity.md) - LazyList patterns
- [Performance Conscious FP](performance-conscious-fp.md) - FP optimization
- [Iterator Safety](../language/iterator-safety.md) - Iterator patterns

---

## References

- [Scala 2.13 Collections — Performance Characteristics](https://docs.scala-lang.org/overviews/collections-2.13/performance-characteristics.html) - canonical Big-O table for the current collection hierarchy
- [Scala Collections Performance (legacy 2.8–2.12)](https://docs.scala-lang.org/overviews/collections/performance-characteristics.html) - kept for old codebases; flagged "Outdated" upstream
- [Li Haoyi - Benchmarking Scala Collections](https://www.lihaoyi.com/post/BenchmarkingScalaCollections.html) - 2016 baseline; numbers shifted on later JVMs but relative ranking holds

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
