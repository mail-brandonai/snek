# ADR 0001: Local persistence for Training Arena data

- Date: 2026-09-20
- Status: Drift selected; Sprint 0 runtime validation gates remain open
- Scope: Snek Training Arena records, Soul lineages, profile bindings, and local match history

## Context

The game targets Web and Android. `GameSimulation` owns a 1/60-second fixed step and current gameplay outcomes. `SnekPenStore` currently stores the profile list and selection as one JSON string in `SharedPreferencesAsync`. The app has no durable run recorder or Soul store.

Training data grows over time and needs indexed lookup, chunked writes, schema migration, atomic revision commits, crash recovery, explicit deletion, and async access away from the gameplay update path. Profile appearance and identity also need stable references from Soul bindings and match snapshots.

## Decision

Use **Drift with `drift_flutter` as the selected local database adapter**, behind repository interfaces in the data layer. Store application records in SQLite on Android and use Drift's WebAssembly worker backend on Flutter Web. Keep Flutter, Flame, and Drift types out of the domain and application contracts.

This is the implementation target, not a claim that the platform proof has passed. Sprint 0 remains open until the Web and Android persistence, recovery, and performance probes below pass on the actual supported targets.

Keep `SharedPreferencesAsync` only for small, replaceable preferences such as UI options. Migrate Snek profiles and selection into the database in a versioned migration while preserving IDs, names, colors, and selected profile.

## Why Drift

- The feature needs linked, versioned entities and indexed queries, not one growing preferences value.
- SQL transactions fit atomic run finalization and immutable Soul revision commits.
- Drift supports Android and Web. Its Web implementation runs a database worker and selects a persistent browser backend where available; native setup stores a SQLite file in the app data directory.
- A worker/isolate boundary is a better fit for the frame-time requirement than encoding and persisting full records in the simulation callback.
- `sembast_web` is the comparison candidate. It uses IndexedDB and supports cross-tab-safe transactions, but its documentation says the whole database is loaded into memory. That makes memory use grow with retained run history.
- Shared Preferences is documented for simple key-value data; writes are asynchronous and are not guaranteed durable when the call returns. It is not suitable for authoritative run/Soul artifacts.

Web has specific constraints: Drift requires a WASM module and worker asset. Its implementation can fall back from OPFS/shared-worker storage to IndexedDB or in-memory storage depending on browser features. The selected implementation and missing features must be recorded. A memory-only or unsafe multi-tab mode must never be reported as durable persistence. Test the actual deployment headers and browser matrix before release.

## Data layout

- `snek_profiles`: stable profile ID, name, appearance, create/update metadata.
- `soul_bindings`: Snek ID, Soul ID, pinned revision ID, normalized influence weight.
- `run_headers`: run ID, schema/game-rule versions, mode, seed/config, timebase, status, duration, outcome, timestamps.
- `run_participants`: run/actor IDs, profile snapshot, role, controller source, pinned revision IDs.
- `run_chunks`: run ID, actor ID, monotonic chunk sequence, tick range, codec version, encoded payload, checksum. Unique key is (run ID, actor ID, sequence).
- `soul_lineages` and `soul_revisions`: stable Soul identity; immutable revision ID/parent, trainer and feature versions, weights, confidence, summary, evaluation.
- `soul_revision_sources`: exact, de-duplicated source run IDs for each revision.
- `match_records` and `match_participants`: match setup/result plus participant and pinned controller snapshots.

Use typed immutable domain records and repository ports. Store payload chunks as opaque versioned bytes; select compression and exact sample encoding only after measuring representative runs. Do not persist a full serialized world state per frame.

## Write and recovery protocol

1. Create a run header with `recording` status before gameplay begins.
2. Record actual input at each consumed fixed tick; sample observations on the configured cadence and emit semantic events at their source.
3. Add compact samples to a bounded in-memory buffer. Chunk encoding and repository writes are asynchronous and never run inside `GameSimulation.update`.
4. Persist each chunk with a sequence, tick range, and checksum. Backpressure or storage failure must not stall gameplay; mark the capture incomplete and expose a recoverable error.
5. Finalize in a transaction that verifies the expected chunk sequence and integrity metadata before switching the header to `pendingReview`. A crash before this transaction leaves an incomplete/recoverable record.
6. Soul refinement writes a new immutable revision and source-run links atomically. Run deletion checks references; no Soul or match may silently lose its source data.

## Performance contract

- Preserve simulation rules and the existing fixed-step schedule.
- No database access, synchronous filesystem work, JSON encoding, compression, or feature extraction in the render or simulation update path.
- Compare the same seeded scenario with recording off and on, including the full configured bot population and long bodies.
- Keep the existing provisional target of less than 1 ms p95 added main-thread recorder cost. Measure it on identified reference hardware; this is a budget to verify, not an achieved result.
- Track missed frames, p50/p95 update duration, chunk queue depth, bytes per run, append/finalize/query latency, and memory growth. Storage flushes must remain outside the render-critical path.

## Sprint 0 validation matrix

Run the same contract against Drift and a small Sembast comparison fixture where possible. Use the self-hosted runner for CI; do not add a GitHub-hosted runner.

- Web: build and run in the supported desktop browser; verify the chosen persistent implementation; create, append, finalize, reopen after page reload, query by status/date, and delete.
- Android: build and run on the supported device/emulator; verify app-data persistence across process death; repeat create/append/finalize/reopen/query/delete.
- Recovery: interrupt after the header, during a chunk, after the final chunk but before finalization, and during deletion. Detect incomplete/corrupt chunks and keep finalized runs/Souls intact.
- Integrity: checksums, monotonic chunk sequences, idempotent finalization, atomic revision commit/rollback, and referenced-run deletion rules.
- Performance: record a fixed-length representative run with the same seed and configuration, capture on/off frame-time profiles, storage latency, payload size, queue high-water mark, and memory.
- Web capabilities: capture Drift's selected implementation/missing features. Test page refresh, supported multi-tab behavior, browser storage quota failure, and the production headers used by the actual deployment.

## Current evidence and remaining gate

The Sprint 0 prototype is implemented in draft PR #5 on `sprint-0/storage-adapter-adr`, currently at `db5284843f2af6de822f885d88eadb6b445b026d`. It adds the Drift database and run store, versioned JSON DTOs with schema rejection, a pure-Dart controller boundary, persistence probes, and self-hosted CI coverage. All GitHub Actions jobs use `runs-on: self-hosted`; the workflow does not require `gh`.

Self-hosted workflow runs [#21](https://github.com/mail-brandonai/snek/actions/runs/35541287710) and [#22](https://github.com/mail-brandonai/snek/actions/runs/35541362952) verify code generation, formatting, analysis, unit tests, and the Web release build. They both end as failed checks because this runner lacks Chrome, `adb`, and the Android SDK: the Web probe reports no supported browser, the Android probe cannot find `adb`, and APK build reports no Android SDK. The compile error and analyzer findings from run #20 were fixed and the later analyze/unit-test steps pass.

The persistence probe, when run on a platform, creates a run, writes ordered checksummed chunks, closes and reopens the database in the same process, finalizes idempotently, queries the record, and deletes it. It does not yet prove a page refresh or process-death restart, exhaustive crash/corruption recovery, deployed Web storage capabilities, or quota handling. No recording-on/off frame-time benchmark has been captured, and the provisional less-than-1-ms p95 target remains unmeasured. Do not report it as achieved.

Sprint 0 is still open. Before adopting Drift in Sprint 1, run the probes on a self-hosted runner with Chrome and Android SDK/device support, add restart/recovery coverage, and capture the agreed recording-on/off performance measurements on identified reference hardware.
## References

- Drift Web platform and storage-selection documentation: https://drift.simonbinder.eu/platforms/web/
- Drift Flutter adapter and platform setup: https://pub.dev/packages/drift_flutter
- Sembast Web IndexedDB behavior and memory model: https://pub.dev/packages/sembast_web
- Shared Preferences scope and durability note: https://pub.dev/packages/shared_preferences


## Sprint 0 execution

Implementation and domain-contract work is in draft PR #5. The Drift store validates ordered chunk append, SHA-256 checksums, finalization integrity, idempotent finalization, status/date lookup, and deletion. Versioned run, control, observation, event, Soul revision, and participant DTOs reject unsupported schema versions. A pure-Dart controller interface and fake-controller test establish the simulation boundary.

Latest code checks on self-hosted runner `on-prem-devbox-02` (Debian 12), for commit `db5284843f2af6de822f885d88eadb6b445b026d`:

- Passed: Drift code generation, formatting, analysis, unit tests, Web platform preparation, Drift worker/WASM checksum verification, and Web release build.
- Blocked by runner capabilities: Web persistence test (no Chrome device), Android persistence test (`adb: command not found`), and Android APK build (no Android SDK).
- Overall Actions checks remain failed because the required platform jobs cannot run on the configured self-hosted runner.
- Not measured: recorder overhead, recording-on/off frame timing, recovery after browser refresh or Android process death, and Web quota/storage-selection behavior.

The CI workflow remains self-hosted-only. PR #5 remains a draft while these gates are open. Sprint 1 is not authorized by this ADR until the missing platform and performance evidence is recorded.
