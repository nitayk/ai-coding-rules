# Long-Running Operations (AIP-151)

If an RPC can't reasonably complete within a synchronous deadline (~30 seconds is a soft ceiling; pick lower per `deadlines-and-timeouts.md`), don't extend the deadline — model it as a Long-Running Operation. The LRO pattern returns a handle the client can poll, cancel, or wait on, while the real work runs in the background.

Source: [AIP-151 — Long-running operations](https://google.aip.dev/151).

---

## When to reach for LRO

Choose LRO if any of the following are true:

- The work can take more than ~30 seconds in the worst case.
- The work involves coordination with external systems (data warehouse export, model training, large file processing).
- The client needs to survive disconnect / restart without losing the handle.
- Progress updates are meaningful (percent complete, "items processed").

Stick with synchronous RPC if:

- p99 latency comfortably fits the caller's deadline budget.
- The result is small and immediately useful.
- There is no need for cancel / poll / resume.

A streaming RPC is a different tool — use streaming for an ongoing flow of small messages (server-streaming events, bidirectional chat). LRO is for a single eventual result.

---

## The Operation message

`google.longrunning.Operation` is the standard envelope. Your RPC returns it; clients call `GetOperation` / `CancelOperation` / `DeleteOperation` to manage it.

```proto
import "google/longrunning/operations.proto";
import "google/rpc/status.proto";

service ExportService {
  // Returns immediately with an Operation; the real work runs in the background.
  rpc ExportCampaigns(ExportCampaignsRequest) returns (google.longrunning.Operation) {
    option (google.longrunning.operation_info) = {
      response_type: "ExportCampaignsResponse"
      metadata_type: "ExportCampaignsMetadata"
    };
  }
}

message ExportCampaignsRequest {
  string parent = 1;
  string destination_uri = 2;   // e.g. gs://bucket/path
}

// What you get when the operation finishes successfully.
message ExportCampaignsResponse {
  string export_uri = 1;
  int64 exported_count = 2;
}

// Progress info you can stream back via Operation.metadata while it's running.
message ExportCampaignsMetadata {
  google.protobuf.Timestamp create_time = 1;
  google.protobuf.Timestamp update_time = 2;
  int64 processed_count = 3;
  int64 total_count = 4;
  string stage = 5;             // e.g. "QUERYING", "WRITING", "VERIFYING"
}
```

The `operation_info` annotation is required: it tells generated code which messages to expect inside the `Operation`'s `response` and `metadata` Any fields.

---

## The Operation lifecycle

```
Client                    Server
   |                         |
   |--- ExportCampaigns ---->|
   |     (returns Operation, |
   |      done = false)      |
   |                         |---> spawn background worker
   |<--- Operation handle ---|
   |                         |
   |--- GetOperation ------->|
   |<--- Operation (running, |
   |     metadata progress)  |
   |                         |
   |    ... (poll loop) ...  |
   |                         |
   |<--- Operation (done,    |
   |     response = result)  |
```

```proto
message Operation {
  string name = 1;                         // operations/{operation_id}
  google.protobuf.Any metadata = 2;        // ExportCampaignsMetadata
  bool done = 3;
  oneof result {
    google.rpc.Status error = 4;           // populated when done && failed
    google.protobuf.Any response = 5;      // populated when done && success
  }
}
```

---

## Always include `Operations` as a sibling service

Implement the three standard management methods alongside your business service. Without them, clients can't poll or cancel.

```proto
import "google/longrunning/operations.proto";

service Operations {
  rpc GetOperation(google.longrunning.GetOperationRequest) returns (google.longrunning.Operation);
  rpc ListOperations(google.longrunning.ListOperationsRequest) returns (google.longrunning.ListOperationsResponse);
  rpc CancelOperation(google.longrunning.CancelOperationRequest) returns (google.protobuf.Empty);
  rpc DeleteOperation(google.longrunning.DeleteOperationRequest) returns (google.protobuf.Empty);
  rpc WaitOperation(google.longrunning.WaitOperationRequest) returns (google.longrunning.Operation);
}
```

`WaitOperation` is a server-side long-poll that returns when the operation completes or a deadline elapses — it lets clients avoid tight polling loops.

---

## Server-side: persist operations, don't keep them in memory

Operation handles must survive server restarts. Persist them to durable storage (Postgres / Spanner / a dedicated `operations` table). On poll, look the operation up and return the latest snapshot.

```go
// ✅ Good: persisted, restartable
func (s *Server) ExportCampaigns(ctx context.Context, req *pb.ExportCampaignsRequest) (*lropb.Operation, error) {
    op := s.operations.Create(ctx, &OperationRecord{
        Name:        "operations/" + uuid.New().String(),
        RequestType: "ExportCampaigns",
        RequestBlob: mustMarshal(req),
        State:       OpStateRunning,
    })
    go s.runExport(context.Background(), op.Name, req)   // detached on purpose; LROs outlive inbound deadline
    return s.operations.ToProto(op), nil
}
```

```go
// ❌ Bad: in-memory map dies on every restart
var ops = map[string]*lropb.Operation{}

func (s *Server) ExportCampaigns(...) (*lropb.Operation, error) {
    op := &lropb.Operation{Name: "operations/" + uuid.New().String()}
    ops[op.Name] = op
    go runExport(op)
    return op, nil
}
```

Note the deliberate use of `context.Background()` for the spawned worker: an LRO must outlive the inbound request's deadline. This is **the** exception to the "always honor ctx" rule from `deadlines-and-timeouts.md`.

---

## Cancel must actually cancel

`CancelOperation` is best-effort but must at minimum:

1. Mark the operation `done = true` with `error.code = CANCELLED`.
2. Signal the worker (e.g. close a per-operation context) so it stops doing more work.
3. Run any cleanup (delete partial exports, release locks).

```go
func (s *Server) CancelOperation(ctx context.Context, req *lropb.CancelOperationRequest) (*emptypb.Empty, error) {
    if err := s.operations.Cancel(ctx, req.Name); err != nil {
        return nil, err
    }
    s.signalWorker(req.Name)
    return &emptypb.Empty{}, nil
}
```

---

## Don't invent your own "operation status" enum

The Operation message already tells you everything: `done`, `error`, `response`. Adding a parallel `status` field (`STARTED` / `IN_PROGRESS` / `FAILED`) is redundant and creates two sources of truth. Per-stage progress belongs in your `metadata` message.

---

## LROs do not replace pagination or streaming

- Returning a million results? **Paginate**, not LRO.
- Server pushing a continuous event feed? **Stream**, not LRO.
- One-shot computation that takes minutes-to-hours? **LRO**.

---

## Related Rules

- [Deadlines and Timeouts](deadlines-and-timeouts.md) — when a deadline isn't enough, switch to LRO
- [Resource Naming](resource-naming-aip.md) — Operation names are `operations/{operation_id}`
- [Status Codes and Errors](status-codes-and-errors.md) — operation `error` uses the canonical Status

---

## References

- [AIP-151 — Long-running operations](https://google.aip.dev/151)
- [google/longrunning/operations.proto](https://github.com/googleapis/googleapis/blob/master/google/longrunning/operations.proto)
- [Google API Improvement Proposals](https://google.aip.dev/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
