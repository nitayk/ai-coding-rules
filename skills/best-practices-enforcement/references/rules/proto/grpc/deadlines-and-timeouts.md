# gRPC Deadlines and Timeouts

The single most important client-side discipline in gRPC: **every outbound RPC has a deadline**. The single most important server-side discipline: **honor and propagate the incoming deadline**. A service that does neither will, under load, hold goroutines and connections open until the OS reaps them — by which time the cascade has already taken out downstream systems.

Source: [gRPC Deadlines Guide](https://grpc.io/docs/guides/deadlines/).

---

## Client side: always set a deadline

`context.Background()` has no deadline. A gRPC call made with it can wait forever — which under network partition or a hung downstream service means your client thread / goroutine / browser tab is gone too.

```go
// ✅ Good: explicit per-call deadline
ctx, cancel := context.WithTimeout(ctx, 200*time.Millisecond)
defer cancel()

resp, err := client.GetValuation(ctx, req)
if errors.Is(err, context.DeadlineExceeded) || status.Code(err) == codes.DeadlineExceeded {
    // both forms can surface, depending on where the deadline fired
    return nil, fmt.Errorf("valuation: %w", err)
}
```

```go
// ❌ Bad: unbounded — under network partition this blocks indefinitely
resp, err := client.GetValuation(context.Background(), req)
```

**Always pair `context.WithTimeout` with `defer cancel()`** — even when the timeout fires, the underlying timer goroutine isn't released until cancel runs. `go vet`'s `lostcancel` checker catches this.

---

## Pick the deadline from the SLO, not from a default

Use the SLO the **caller** has promised its caller. A request-response service serving a user-facing API at p99=300ms cannot afford to give a downstream call a 5-second timeout — that's the cascading-failure default.

A rough mental model:

| Caller SLO (p99) | Per-hop budget | Notes |
|---|---|---|
| 200 ms | 50–80 ms | Fanning out to 2–3 downstreams in parallel |
| 1 s | 200–400 ms | Typical backend-to-backend |
| 5 s | 1–2 s | Background / batch |
| Stream / pipeline | minutes | Use streaming RPC, not a giant unary deadline |

Don't pick a deadline just because "5 seconds feels safe." Pick one that gives you headroom over the downstream's actual p99 and that fits within your own budget.

---

## Server side: honor the incoming context

The deadline travels on the wire as part of the gRPC headers and is materialised into the server's `ctx`. Every blocking call inside the handler must accept and respect that `ctx` — otherwise the handler keeps working long after the client gave up.

```go
// ✅ Good: ctx flows into every downstream call
func (s *Server) GetValuation(ctx context.Context, req *pb.GetValuationRequest) (*pb.GetValuationResponse, error) {
    profile, err := s.profiles.Get(ctx, req.GamerId)       // honors ctx
    if err != nil {
        return nil, err
    }
    valuation, err := s.valuator.Score(ctx, profile)       // honors ctx
    if err != nil {
        return nil, err
    }
    return &pb.GetValuationResponse{Valuation: valuation}, nil
}
```

```go
// ❌ Bad: ignores the deadline — handler runs to completion even after client gives up
func (s *Server) GetValuation(ctx context.Context, req *pb.GetValuationRequest) (*pb.GetValuationResponse, error) {
    profile, err := s.profiles.Get(context.Background(), req.GamerId)   // detached!
    if err != nil {
        return nil, err
    }
    return &pb.GetValuationResponse{Valuation: s.valuator.Score(context.Background(), profile)}, nil
}
```

Detached `context.Background()` in a server handler is the most common cause of `goroutine` leaks in Go gRPC services. Lint for it (e.g. `gocritic`'s context-related checks, or a custom semgrep rule that flags `context.Background()` inside any function whose first parameter is `ctx context.Context`).

---

## Propagate, don't re-set, the deadline downstream

When your handler calls another gRPC service, pass `ctx` straight through. gRPC will encode the remaining deadline into the outbound headers automatically. Do not call `context.WithTimeout` again unless you want to **shorten** the budget — never to lengthen it.

```go
// ✅ Good: downstream inherits the remaining deadline
func (s *Server) GetAd(ctx context.Context, req *pb.GetAdRequest) (*pb.GetAdResponse, error) {
    val, err := s.valuationClient.GetValuation(ctx, &pb.GetValuationRequest{GamerId: req.GamerId})
    if err != nil {
        return nil, err
    }
    ...
}
```

```go
// ✅ Also good: shorten the budget for a downstream that has a tighter SLO
ctx, cancel := context.WithTimeout(ctx, 50*time.Millisecond)
defer cancel()
val, err := s.valuationClient.GetValuation(ctx, ...)
```

```go
// ❌ Bad: brand-new 5-second deadline overrides the inherited one
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
val, err := s.valuationClient.GetValuation(ctx, ...)
```

The bad form is dangerous: a fast-failing service upstream now waits 5 seconds on a downstream the caller already gave up on. Multiply that across a fan-out and you have a thread / goroutine / connection-pool exhaustion bug.

---

## On `DEADLINE_EXCEEDED`: don't blindly retry

`DEADLINE_EXCEEDED` means the **deadline elapsed**, not that the operation failed. The server may have completed the work and not been able to ship the response in time, or it may still be running. Retrying is allowed but:

1. Only retry if the operation is idempotent (or if you have an idempotency key — see AIP-155).
2. Only retry if you have budget left in the parent deadline. Otherwise you just burn the parent.
3. Add exponential backoff and a retry cap. Two retries is usually plenty.

---

## Streaming RPCs: per-message timeouts, not a single big deadline

A streaming RPC that's supposed to run for hours can't have a 5-second deadline. Use per-message timeouts inside the loop, or rely on application-level keepalives:

```go
// ✅ Good: per-message budget; the stream itself has no deadline
for {
    msgCtx, cancel := context.WithTimeout(stream.Context(), 5*time.Second)
    msg, err := readNext(msgCtx)
    cancel()
    if err != nil { return err }
    if err := stream.Send(msg); err != nil { return err }
}
```

For long-lived streams, configure gRPC keepalive (`KEEPALIVE_TIME_MS`, `KEEPALIVE_TIMEOUT_MS`) so a dead peer is detected even when no application traffic is flowing.

---

## Related Rules

- [Status Codes and Errors](status-codes-and-errors.md) — `DEADLINE_EXCEEDED` semantics
- [Long-Running Operations](long-running-operations.md) — AIP-151 for operations that don't fit a deadline
- Go `context-patterns.md` in `../../go/language/` — context propagation discipline

---

## References

- [gRPC Deadlines Guide](https://grpc.io/docs/guides/deadlines/)
- [gRPC Official Documentation](https://grpc.io/docs/)
- [AIP-154 — Resource freshness validation](https://google.aip.dev/154)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
