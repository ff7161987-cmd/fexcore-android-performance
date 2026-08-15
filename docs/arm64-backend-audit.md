# ARM64 backend audit

## Constant materialization

`Arm64Emitter::LoadConstant` already handles 32-bit and 64-bit values, negative constants through `movn`/`movk`, logical immediates through `orr`, and compact `movz`/`movk` sequences. It also preserves padding when relocations require a fixed-size site. The PC-relative ADR/ADRP path is intentionally disabled because the temporary emission address does not match the final relocated code address after the block is copied into the shared code buffer. Enabling it without relocation support would be unsafe.

## Branch emission

The branch wrappers select direct conditional branches when the target is encodable and use the existing far-jump restart path when the code buffer layout requires it. Exit lowering already distinguishes direct known RIPs from indirect targets, uses L1 cache entries for indirect exits, and backpatches linkable exits. The current sequences preserve the guest state and existing invalidation model.

## Code cache interaction

The shared code buffer grows geometrically up to its configured maximum and uses a linear, atomically reserved allocation cursor. The applied change makes all cursor reads and compare-exchange orders explicitly relaxed. It does not change code-buffer size, guard pages, huge-page advice, ownership, relocation, or cache invalidation.

## Result

No instruction-level ARM64 emission transformation was merged in this release. The existing emitter already contains nontrivial correctness-sensitive heuristics, and device-level instruction/cache counters are required before replacing any of its sequences.
