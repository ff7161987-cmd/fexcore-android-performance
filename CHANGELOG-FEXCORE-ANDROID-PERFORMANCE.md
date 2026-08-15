# FEXCore Android Performance — technical changelog

## Unreleased / first experimental release

This release is based on the upstream FEX-Emu `main` checkout at commit `f3ab82a73fb48271ee12a882c98bc5d823a2b4d1` and adds one narrowly scoped ARM64-oriented code-cache optimization.

### Implemented

`SharedCodeBufferManager::AtomicAllocateBuffer` now uses explicit relaxed success and failure memory orders for its compare-and-exchange loop. The cursor only reserves disjoint ranges in a linear code buffer; it is not used to publish generated instructions or to establish guest-memory visibility. The change removes unnecessary sequential-consistency fences from concurrent JIT compilation on ARM64 while preserving atomic reservation, 16-byte alignment, bounds checks, buffer growth, and existing publication/invalidation behavior.

### Audited but intentionally unchanged

The IR pass manager and register allocator already perform substantial dead-operation removal, flag handling, move coalescing, and register-class management. The ARM64 emitter already has immediate-size heuristics for `movz`/`movk`/`movn`, logical-immediate materialization, and relocation padding. Branch linking already uses direct links and fallback thunks. Memory and SIMD paths already select NEON, SVE, MOPS, RCPC, and scalar fallbacks based on runtime host features. No transformation was merged in these areas without a device-backed workload proving that it removes instructions without changing guest semantics.

### Validation

The reference checkout and patched checkout both produced successful host and AArch64 Release builds. The patched AArch64 executable is a stripped `ELF 64-bit LSB pie executable, ARM aarch64`. The selected FEX verification/ABI tests passed on the host. ETS2 FPS, frame-time, shader compilation, and Android CPU/RSS measurements remain device-dependent and are intentionally not fabricated here.

### Known build limitation

The normal FEXCore AArch64 Release build completes with LTO, LLD, ccache, and no debug symbols. The optional all-in-one thunk build requires a target-compatible OpenSSL/graphics development sysroot; the sandbox has host OpenSSL/OpenGL development files but not the corresponding AArch64 target sysroot, so the thunk generator must be rebuilt later with the Android/device sysroot. This does not invalidate the FEXCore AArch64 binary build.
