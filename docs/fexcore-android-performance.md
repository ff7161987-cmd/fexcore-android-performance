# FEXCore Android Performance

This tree is an experimental performance-focused variant of FEX-Emu for ARM64 Linux and Android-like environments such as Winlator and Ludashi. It does **not** execute x86_64 code natively. The guest instructions remain x86_64 and are translated to ARM64 host code; the goal is to reduce translation, compilation, synchronization, and code-cache overhead while preserving FEXCore semantics.

## Scope

The first change targets the shared JIT code-buffer allocator in `FEXCore/Source/Interface/Core/SharedCodeBufferManager.h`. The allocator reserves fixed, 16-byte-aligned ranges from the active code buffer with a compare-and-exchange loop. The cursor is an allocation index, not a publication or data-visibility barrier. Code is emitted into a temporary buffer, copied into the reserved range, and the generated code is made executable/visible through the existing code-cache publication and instruction-cache paths.

The compare-and-exchange success and failure orders are therefore explicitly `std::memory_order_relaxed`. This removes unnecessary sequential-consistency fences from a high-frequency compiler-side reservation path on ARM64. No allocation bounds, alignment, buffer-generation, relocation, or code publication behavior is changed.

## Stability rationale

The patch is intentionally narrow. It does not change register allocation, guest-visible memory ordering, conditional branches, SIMD lowering, signal handling, code-buffer lifetime, or linker behavior. The existing `CodeBufferOffset` atomic still serializes reservation among compiling threads; only the ordering strength of that reservation counter is reduced. The published code remains governed by the existing relocation, cache invalidation, and instruction-cache maintenance code.

Further SIMD, branch, and IR transformations were not included without a concrete proof that the generated instruction sequence is redundant on all supported host-feature combinations. FEX already has specialized SSE/SSE2/SSE4-to-NEON/SVE lowering, MOPS paths, branch linking, and a post-RA move-coalescing pass. Speculative changes in those areas would carry a larger compatibility risk than the measured allocator change.

## Build properties

The release build used for this tree is configured with Clang, LLD, Ninja, LTO, ccache, stripped release output, and a generic AArch64 target unless a device-specific `TUNE_CPU` is selected. A device-specific CPU target must only be used when the resulting binary will run on that compatible SoC family; it is not a portable default.

## Validation status

The unmodified upstream checkout was built successfully as an x86_64 host-validation build and as an AArch64 cross build. The patched tree was rebuilt successfully in both configurations. The selected FEX unit/ABI verification subset passed after installing the documented Python Clang binding required by the verifier. The full 6,705-test CTest inventory is not a valid single host baseline because it includes architecture-specific and 32-bit execution suites that require their intended runtime/rootfs configuration.

No ETS2 FPS, stutter, shader-compilation, or Android CPU/memory result is claimed in this repository yet. Those measurements must be collected by running the same ETS2 scenario on the user's Winlator/Ludashi device before and after installing the same FEXCore build. Results should be recorded with the benchmark template under `benchmarks/`.
