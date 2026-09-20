# ADR 0001: Local persistence for Training Arena data

- Date: 2026-09-20
- Status: Candidate selected; Sprint 0 runtime validation is still required
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

Repository review on 2026-09-20 confirmed default branch `main`, current commit `4c50fb459bc21cdf6110597f5f88fc92959c5fbc`, Flutter/Flame targets, the profile store, and existing test seams. `.github/workflows/flutter.yml` and `.github/workflows/auto-merge.yml` both use `runs-on: self-hosted`. The Flutter workflow runs formatting, analysis, unit tests, and a Web release build; it does not currently run Android build/runtime checks.

This workspace has no local Flutter/Dart executable and no repository checkout. Therefore no storage benchmark, Android runtime test, or browser persistence probe has been run here. Do not treat the 1 ms target or Drift's platform behavior as empirically confirmed. The Sprint 0 exit gate remains the validation matrix above, run on the configured self-hosted platforms before Sprint 1 adopts the adapter.

## References

- Drift Web platform and storage-selection documentation: https://drift.simonbinder.eu/platforms/web/
- Drift Flutter adapter and platform setup: https://pub.dev/packages/drift_flutter
- Sembast Web IndexedDB behavior and memory model: https://pub.dev/packages/sembast_web
- Shared Preferences scope and durability note: https://pub.dev/packages/shared_preferences


## Sprint 0 execution

A minimal Drift run-header/chunk store and persistence probe now exercise chunk ordering, checksums, interrupted recording recovery after closing and reopening the database, idempotent finalization, status/date lookup, and deletion. The CI workflow downloads version-matched Drift WebAssembly/worker assets and runs Web persistence tests in Chrome plus Android integration persistence tests on the self-hosted runner. These checks are pending; this section will be updated from their results.
