# Release AArch64 build for Winlator/Ludashi

This project builds FEX as a user-mode x86/x86-64 emulator for an AArch64 host. It does not turn x86_64 binaries into native ARM64 binaries. The resulting executable still performs dynamic translation and depends on the guest rootfs/Wine/Winlator integration used by the target environment.

## Host packages

On Debian/Ubuntu, install Clang/LLVM, LLD, CMake, Ninja, ccache, Python build helpers, NASM for the assembly tests, the Python Clang binding for structure verification, and the x86 cross compilers used by thunks. Initialize every Git submodule before configuring.

```sh
sudo apt-get update
sudo apt-get install -y clang llvm clang-tools lld cmake ninja-build ccache pkg-config \
  python3-setuptools python3-clang nasm \
  gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
  gcc-x86-64-linux-gnu g++-x86-64-linux-gnu \
  gcc-i686-linux-gnu g++-i686-linux-gnu

git clone --branch main --recurse-submodules https://github.com/FEX-Emu/FEX.git
cd FEX
git submodule update --init --recursive
```

## Generic AArch64 Release

The official FEX toolchain expects a `SYSROOT` environment variable. On an Ubuntu cross-toolchain installation, `SYSROOT=/` works with the compiler's target-triple search paths. For an Android or device rootfs, point `SYSROOT` at the matching AArch64 development sysroot instead.

```sh
export SYSROOT=/
export SCAN_DEPS=/usr/lib/llvm-18/bin/clang-scan-deps

cmake -S . -B build-aarch64-release -G Ninja \
  --toolchain Data/CMake/toolchain_aarch64.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER_CLANG_SCAN_DEPS="$SCAN_DEPS" \
  -DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS="$SCAN_DEPS" \
  -DENABLE_LTO=ON \
  -DUSE_LINKER=lld \
  -DENABLE_CCACHE=ON \
  -DBUILD_TESTING=OFF \
  -DBUILD_THUNKS=OFF \
  -DBUILD_FEXCONFIG=OFF \
  -DENABLE_GDB_SYMBOLS=OFF \
  -DTUNE_CPU=none \
  -DTUNE_ARCH=generic

ninja -C build-aarch64-release -j"$(nproc)"
file build-aarch64-release/Bin/FEX
```

`-DTUNE_CPU=none -DTUNE_ARCH=generic` is the portable choice. For maximum performance on one known device family, replace `TUNE_CPU` with a compiler-supported CPU name after checking the target SoC and compiler support. A binary tuned for one CPU family must not be distributed as a universal Android build without testing it on the other CPUs that will receive it.

## Thunks

Thunk generation is a separate cross-build inside the top-level build. It needs the x86-64 and i686 development sysroots and the matching cross compilers. Enable it only when those sysroots contain the headers and libraries required by the selected thunk set.

```sh
cmake -S . -B build-aarch64-thunks -G Ninja \
  --toolchain Data/CMake/toolchain_aarch64.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_THUNKS=ON \
  -DENABLE_CLANG_THUNKS=ON \
  -DX86_DEV_ROOTFS=/ \
  -DENABLE_LTO=ON \
  -DUSE_LINKER=lld \
  -DENABLE_CCACHE=ON \
  -DBUILD_TESTING=OFF \
  -DBUILD_FEXCONFIG=OFF \
  -DTUNE_CPU=none \
  -DTUNE_ARCH=generic

ninja -C build-aarch64-thunks -j"$(nproc)"
```

## Verification

Before packaging, run `git diff --check`, inspect the architecture with `file`, and run the selected unit/ABI verification tests on a native host build. Full guest execution and Android performance validation must be performed on the intended ARM64 device/rootfs.
