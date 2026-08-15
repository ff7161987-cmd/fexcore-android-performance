# Optimization audit

The audit was performed against the upstream `main` checkout used for this build. The purpose was to reduce x86_64-to-ARM64 translation overhead without changing guest semantics or claiming native execution.

| Area | Observed path | Decision | Reason |
| --- | --- | --- | --- |
| JIT compilation | `JIT.cpp` emits into a temporary buffer, reserves shared code-cache space, copies the block, and publishes it through existing link/invalidation paths. | Apply one small patch in the reservation path. | The reservation cursor is atomic but its compare-exchange used implicit sequential consistency even though it is an allocation counter, not a publication barrier. |
| Register allocation / IR | `PassManager` and `RegisterAllocationPass` already perform flag handling, allocation, move coalescing, and post-RA work. | No speculative change. | A new pass would need IR-level workload data and cross-architecture correctness coverage. |
| ARM64 emitter | `Arm64Emitter::LoadConstant` already selects compact immediate forms and handles relocation padding. Branch wrappers already handle range fallback. | No speculative change. | Enabling PC-relative materialization is disabled because the temporary emission address differs from the final relocated code address. |
| Branches | Direct exits are linked and backpatched; indirect exits use the L1 cache and fall back to the dispatcher. | No speculative change. | The existing paths preserve guest RIP/NZCV behavior and already avoid repeated steady-state lookups where linking is possible. |
| SIMD | Vector lowering selects NEON/SVE operations and has runtime fallbacks. Memory operations select MOPS, RCPC, NEON pair operations, or scalar loops based on host features. | No speculative change. | Replacing these sequences without device counters risks regressions on hosts without the same feature set. |
| Memory / code cache | `SharedCodeBufferManager::AtomicAllocateBuffer` is a linear lock-free allocator with 16-byte alignment and bounds checks. | Apply explicit relaxed CAS ordering. | This removes unnecessary ARM64 ordering fences while preserving atomic uniqueness of every allocation. |
| Threads | Buffer allocation is lock-free; code-buffer growth and cache invalidation remain coordinated by existing shared ownership and lock tokens. | No lock redesign. | Lock removal would affect code lifetime and invalidation correctness, which cannot be established without concurrent device workloads. |

## Applied patch

```cpp
while (!CodeBufferOffset.compare_exchange_strong(
    ExpectedOffset,
    DesiredOffset,
    std::memory_order_relaxed,
    std::memory_order_relaxed)) {
```

The patch does not change the value returned by the allocator, the alignment, the out-of-space behavior, code-buffer generation, or instruction-cache publication. It only specifies the weakest ordering sufficient for the cursor's reservation role.

## Verification performed

The patched source passed `git diff --check`, host Release compilation, AArch64 Release compilation, and the selected FEX ABI/verification tests. The final AArch64 build is a stripped ELF executable configured with Release, LTO, LLD, ccache, generic AArch64 tuning, and no debug symbols.

No claim is made about ETS2 FPS or stutter in this environment. Those values require the same ETS2 scenario on the user's Winlator/Ludashi device before and after the build, using the protocol in `benchmarks/README.md`.
