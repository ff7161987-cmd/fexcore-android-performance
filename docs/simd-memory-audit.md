# SIMD and memory audit

## SSE-family lowering

The ARM64 JIT contains feature-dependent vector lowering for SSE-family operations and uses NEON or SVE forms where the host supports them. Vector operations also retain scalar and narrower fallbacks for hosts without the same feature set. These paths are correctness-sensitive because lane width, upper-lane state, MXCSR behavior, and x86 exception semantics must remain consistent.

## Memory operations

The memory lowering selects MOPS for eligible non-atomic copies/sets, NEON pair operations for larger scalar/vector loops, RCPC or acquire/release forms for the TSO path, and scalar fallbacks for overlap, alignment, atomicity, or unsupported host features. MOPS operations preserve NZCV using the existing save/restore sequence because the guest flags can be observable. That sequence was not removed.

## Cache and thread behavior

L1/L2/L3 lookup and invalidation are coordinated by the existing lock tokens and per-thread caches. The dynamic L1 heuristic is enabled by default but samples only L2/L3 hits; it is not in the steady-state L1 hit path. The shared code-buffer reservation cursor is the only concurrency change in this release, and it remains atomic.

## Result

No SIMD instruction sequence was changed. The release avoids unsupported claims about SSE-to-NEON speedups and leaves device-specific feature selection to the existing runtime detection. Future SIMD work should use representative ETS2 traces and host counters on the target Snapdragon/ARM64 device before merging.
