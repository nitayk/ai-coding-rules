# Schema Contract Tests

A `.proto` file has no runtime behaviour, so it has no "unit tests" in the usual sense. What it has is a **contract** with every consumer: parse my bytes, regenerate my code, see the same shape. Three test layers cover that contract — `buf breaking` for the schema contract, golden samples for the wire-format contract, and consumer-driven tests for the behavioural contract.

Sources: [Buf Breaking Change Rules](https://buf.build/docs/breaking/rules/), [Buf Docs](https://buf.build/docs/).

---

## Layer 1: `buf breaking` is the schema contract test

This is the only contract test most repos need. It guarantees: "the schema in this PR is wire- and source-compatible with `main`."

Already covered in detail in `../governance/buf-breaking-against-main.md`. The short version: run it on every PR, against `main`, at the `FILE` tier. That single CI step is the schema's contract test.

You do **not** need a separate "test suite for the proto" — `buf breaking` IS the test suite. Resisting that temptation saves a lot of accidental complexity.

---

## Layer 2: golden samples for wire-format determinism

For messages where the exact wire bytes matter (Kafka payloads stored long-term, snapshots replayed in disaster recovery, cross-language deserialisation contracts), add a golden-sample test: serialise a known message to a `.golden.bin` file, commit it, and on every test run re-encode the same message and compare.

```go
// ✅ Good: golden-sample test
//go:embed testdata/ad_request.v1.golden.bin
var goldenAdRequestV1 []byte

func TestAdRequest_Golden(t *testing.T) {
    msg := &pb.AdRequest{
        AdUnitId:  "unit-1",
        RequestId: "11111111-1111-1111-1111-111111111111",
        Targeting: &pb.AdRequest_Targeting{
            SegmentIds: []string{"seg-a", "seg-b"},
        },
    }

    // Use deterministic marshaling — proto map iteration is non-deterministic by default
    encoded, err := proto.MarshalOptions{Deterministic: true}.Marshal(msg)
    if err != nil { t.Fatal(err) }

    if !bytes.Equal(encoded, goldenAdRequestV1) {
        t.Errorf("wire format changed; if intentional, regenerate the golden:\n  got:    %x\n  golden: %x", encoded, goldenAdRequestV1)
    }
}
```

Regenerating the golden is a deliberate, reviewer-visible step:

```bash
# Regenerate on a behavior change you've audited
GOLDEN_UPDATE=1 go test ./...   # if your harness supports it
# or
go test -run TestAdRequest_Golden -update
```

When this test fails, it's telling you that **bytes that used to be valid for this message no longer are.** That's either a real bug (you changed a field number / type unintentionally) or an intentional change you need to coordinate with every consumer holding old persisted bytes.

---

## When to add a golden sample

Yes:

- Messages persisted long-term in Kafka or a data store.
- Messages crossing org boundaries (you don't control all consumers).
- Messages used in disaster-recovery replay (the recovery is worthless if the bytes don't decode the same).
- Messages with non-trivial field ordering, map iteration, or `oneof` semantics that you want to lock down.

No (skip):

- RPC request/response messages that are encoded fresh per call.
- Internal-only messages with one consumer.
- Anything where you'd happily regenerate the golden on every field addition.

A handful of goldens per repo for the truly critical messages is the right scope. Goldens for every message is busywork.

---

## Layer 3: consumer-driven contract tests (optional, high-leverage when applicable)

For a schema repo with multiple distinct consumers, consumer-driven contract testing (Pact, or a homegrown equivalent) flips the question: instead of asking "does my schema still satisfy `buf breaking`?", consumers publish the subset of the schema they actually depend on, and your CI fails if you break any of that subset.

The mechanics:

1. Each consumer publishes a `.pact` (or similar) file listing the messages and fields it reads/writes.
2. The schema repo's CI loads every published pact and verifies that the new schema still satisfies each one.
3. A consumer that doesn't publish is assumed to depend on everything (the `buf breaking` default).

This is heavyweight to set up but invaluable when you have ~10+ consumers and want to know **which specific consumer** a breaking change will affect. For a single-schema-repo setup with in-org consumers, it's overkill — `buf breaking` at the FILE tier already gives you most of the benefit. Revisit if cross-org consumers appear.

---

## What you don't need

- **A "validate that the .proto compiles" test.** `buf build` (run by `buf lint` and `buf breaking`) already covers this.
- **A "validate that codegen produces valid Go" test.** The CI `buf generate` + diff check (see `../validation/codegen-toolchain.md`) covers this.
- **A "test that every field has a documentation comment" test.** Use `buf lint`'s `COMMENTS` category instead.
- **Roundtrip tests for marshal/unmarshal.** The protobuf library itself is well-tested; you don't need to re-prove it.

Stay away from these unless you have a specific bug they'd catch — they're easy to write and add maintenance weight without protecting against anything `buf` doesn't already cover.

---

## Test what's actually breakable

A useful exercise during PR review: ask "what test would have caught this if it went wrong?" For a `.proto` change, the answer is almost always one of:

| Concern | Test |
|---|---|
| Wire-compat (renumber, type swap, deletion) | `buf breaking` |
| Source-compat (rename, file move) | `buf breaking` at FILE tier |
| Style / convention | `buf lint` |
| Exact wire bytes for a persisted message | Golden sample |
| Cross-consumer impact | Consumer-driven contract (if applicable) |
| Validation correctness | Server-side `protovalidate` tests |
| Generated-code drift | CI `buf generate` + diff check |

If your "test" doesn't fall into one of these buckets, you probably don't need it.

---

## Related Rules

- [buf breaking against main](../governance/buf-breaking-against-main.md) — the foundational schema contract test
- [Codegen Toolchain](../validation/codegen-toolchain.md) — generated-code drift check
- [Backward Compatibility Checklist](../governance/backward-compatibility-checklist.md) — what counts as breaking

---

## References

- [Buf Docs](https://buf.build/docs/)
- [Buf Breaking Change Rules](https://buf.build/docs/breaking/rules/)
- [google.golang.org/protobuf — proto package](https://pkg.go.dev/google.golang.org/protobuf/proto)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
