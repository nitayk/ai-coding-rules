# Akka (and Pekko) Actor Patterns

## Triggers

**APPLY WHEN:** Writing or reviewing Akka or Pekko actor code, integrating actors with Futures, or evaluating which library to depend on.
**SKIP WHEN:** Not using actor systems.

---

## Pekko vs Akka — License Reality (read first)

Lightbend relicensed Akka to **Business Source License (BSL) 1.1** starting Akka 2.7 (Sep 2022). Apache **Pekko** is the ASF-governed Apache 2.0 fork of Akka 2.6.x; Pekko 1.0 released Jul 2023, current line **1.6.0** (May 2026). BSL auto-reverts to Apache 2.0 only **3 years after each release** — so most production-relevant Akka versions are still commercial.

**Default for new code: Pekko.** The actor APIs and message patterns in this rule apply identically to both — the difference is the import prefix (`akka.*` → `org.apache.pekko.*`) and the license/cost story. See the dedicated [Akka → Pekko Migration](akka-to-pekko-migration.md) rule for migration mechanics.

```scala
// Pekko equivalents — same API, different package
import org.apache.pekko.actor.{Actor, ActorRef, ActorSystem, Props}
import org.apache.pekko.pattern.{ask, pipe}
```

Source: [Akka BSL FAQ](https://akka.io/bsl-license-faq), [Apache Pekko docs](https://pekko.apache.org/docs/pekko/current/index.html).

---

## Core Directive

**Prefer tell (!), use ask (?) sparingly. Never share mutable state. Never close over actor context in Future callbacks.** Patterns apply equally to Akka and Pekko.

---

## Process

### 1. Prefer Tell Over Ask

**Tell (!)** is fire-and-forget and more performant. **Ask (?)** creates a Future and adds overhead.

```scala
// Good: Tell - no response needed
actorRef ! ProcessMessage(data)

// Acceptable: Ask only when you need a response
val response: Future[Result] = (actorRef ? RequestMessage(id)).mapTo[Result]
```

Use ask only when the caller must wait for a response. Prefer request-reply via tell with a reply-to address.

### 2. Messages Must Be Immutable

Use case classes for messages. Never send mutable state.

```scala
// Good: Immutable message
case class ProcessOrder(orderId: String, items: List[ItemId])

// Bad: Mutable message - can cause race conditions
case class ProcessOrder(orderId: String, items: mutable.ListBuffer[ItemId])
```

### 3. Do Not Close Over Actor Context in Future Callbacks

Never call actor methods or access `sender()` from within `onComplete`, `map`, or `flatMap` on a Future. The actor may have moved on to another message.

```scala
// Bad: Closing over actor context
class MyActor extends Actor {
  def receive: Receive = {
    case Request =>
      val future = fetchData()
      future.onComplete { _ =>
        sender() ! Response(data)  // sender() may be wrong! Actor may be processing another message
      }
  }
}

// Good: Use pipeTo or mapTo with explicit sender capture
class MyActor extends Actor {
  import akka.pattern.pipe
  implicit val ec: ExecutionContext = context.dispatcher

  def receive: Receive = {
    case Request =>
      val replyTo = sender()
      fetchData().map(Response.apply).pipeTo(replyTo)
  }
}
```

### 4. Use context.dispatcher for Futures Inside Actors

Reuse the actor's dispatcher when running Futures. Do not use the default global EC.

```scala
// Good: Use actor's dispatcher
class MyActor extends Actor {
  import context.dispatcher

  def receive: Receive = {
    case Request =>
      Future(blockingCall()).map(Result.apply).pipeTo(sender())
  }
}
```

### 5. Use ActorRef, Not ActorSelection

**ActorRef** is resolved once. **ActorSelection** resolves on every message. Prefer ActorRef when the path is known.

```scala
// Good: ActorRef when path is known
val actorRef: ActorRef = context.actorOf(Props[Worker], "worker")

// Acceptable: ActorSelection only for dynamic paths (e.g., remote)
val selection = context.actorSelection("akka://system@host:2552/user/worker")
```

### 6. Do Not Share Mutable State Among Actors

Each actor owns its state. Never pass mutable collections or objects that multiple actors can modify.

```scala
// Bad: Shared mutable state
val sharedCache = mutable.Map[String, Data]()

class ActorA extends Actor {
  def receive = { case m => sharedCache(m.key) = m.value }  // Race!
}

class ActorB extends Actor {
  def receive = { case m => val x = sharedCache(m.key) }    // Race!
}

// Good: Each actor owns its state
class ActorA extends Actor {
  private val cache = mutable.Map[String, Data]()
  def receive = { case m => cache(m.key) = m.value }
}
```

### 7. Use Bounded Mailboxes for Backpressure

Unbounded mailboxes can cause memory issues under load. Configure bounded mailboxes for actors that receive high volume.

```hocon
bounded-mailbox {
  mailbox-type = "akka.dispatch.BoundedMailbox"
  mailbox-capacity = 1000
}
```

---

## Examples

### Positive Pattern

```scala
class OrderProcessor(replyTo: ActorRef) extends Actor {
  import context.dispatcher
  import akka.pattern.pipe

  def receive: Receive = {
    case ProcessOrder(orderId) =>
      val future = orderService.fetch(orderId)
      future.map(OrderResult).pipeTo(replyTo)
  }
}
```

### Negative Pattern

```scala
// Bad: ask in hot path, closing over sender
class BadActor extends Actor {
  def receive: Receive = {
    case Request =>
      (otherActor ? GetData).onComplete {
        case Success(data) => sender() ! data  // Wrong sender! Race!
        case Failure(_)   => sender() ! Error
      }
  }
}
```

---

## Related Rules

- [Scala Efficient Future Management](scala-efficient-future-management.md) - ExecutionContext, Future composition
- [Future Error Handling Conventions](../language/future-error-handling-conventions.md) - Future[Either[E, A]]
- [Scala Production Patterns](../meta/scala-production-patterns.md) - Timeouts, graceful shutdown

---

## References

- [Apache Pekko Documentation](https://pekko.apache.org/docs/pekko/current/index.html) — preferred for new code (Apache 2.0)
- [Apache Pekko - Futures](https://pekko.apache.org/docs/pekko/current/futures.html)
- [Akka Documentation - Futures](https://doc.akka.io/docs/akka/current/futures.html) — BSL-licensed; commercial for Akka ≥ 2.7
- [Akka BSL License FAQ](https://akka.io/bsl-license-faq) — license terms and 3-year reversion mechanic
- [Akka → Pekko Migration](akka-to-pekko-migration.md) — when and how to move

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
