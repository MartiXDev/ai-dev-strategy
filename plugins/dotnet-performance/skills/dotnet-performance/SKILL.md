---
name: dotnet-performance
description: 'Improve .NET performance through async correctness, blocking-call elimination, efficient data access, caching strategy, and hotspot-oriented optimization.'
---

# .NET Performance

Use this skill when you need measurable .NET performance gains without sacrificing correctness.

## Focus Areas

### 1) Async Correctness and Blocking Elimination

- Keep hot-path code async end-to-end; propagate `CancellationToken` through service, repository, and HTTP/database calls.
- Remove sync-over-async anti-patterns like `.Result`, `.Wait()`, and `GetAwaiter().GetResult()`.
- Avoid wrapping I/O with `Task.Run`; fix the blocking dependency instead.
- Use `ValueTask` only for truly high-frequency paths where synchronous completion is common and validated by profiling.

### 2) Data-Access Efficiency

- Reduce over-fetching by projecting only required columns (`Select`) and using `AsNoTracking()` for read-only queries.
- Eliminate N+1 patterns with explicit includes, batching, or query reshaping.
- Prefer server-side filtering/sorting/pagination; avoid materializing large sets in memory.
- For repeated hotspots, consider compiled queries and ensure supporting indexes exist.

### 3) Caching Strategy

- Apply cache-aside for expensive and stable reads with explicit TTL, key versioning, and invalidation rules.
- Choose cache scope deliberately (`IMemoryCache` for single-node, distributed cache for multi-node consistency).
- Prevent cache stampedes on hot keys (single-flight, jittered expirations, or stale-while-revalidate patterns).
- Never cache tenant/user-scoped data without full key partitioning and safety checks.

### 4) Hotspot-Oriented Optimization

- Measure first, then optimize: use `dotnet-counters`, tracing, and endpoint-level latency/error metrics.
- Prioritize top p95/p99 endpoints, highest-frequency jobs, and highest-cost queries.
- Validate each change with before/after numbers (latency, allocations, CPU, DB calls, cache hit rate).
- Avoid broad micro-optimizations on cold paths.

## Definition of Done

- Blocking calls are removed from targeted paths.
- Async flow is consistent and cancellation-aware.
- Data-access changes reduce query count, transferred data, or execution time.
- Caching has clear invalidation behavior and demonstrates positive hit-rate impact.
- Performance improvements are validated with measured metrics.
