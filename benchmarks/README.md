# ETS2 benchmark protocol

This benchmark is designed for the user's ARM64 Android device running ETS2 through the same Winlator or Ludashi configuration. It must be run twice: once with the reference FEXCore and once with the optimized build. Do not change the Wine/Proton version, DXVK/VKD3D settings, resolution, graphics preset, power mode, thermal state, savegame, route, traffic/weather settings, or background applications between runs.

Use a fixed scenario such as the same saved route and the same first 120 seconds after loading. Warm up once before recording. Capture the Winlator/DXVK/MangoHud overlay or equivalent for average FPS, 1% low FPS, frame-time graph, and stutter count. Measure shader compilation time from the same cold-start condition, and record peak process RSS from the capture CSV. The helper script collects process CPU ticks, process RSS, and available system memory; it cannot infer FPS or shader time and intentionally does not fabricate those values.

```sh
chmod +x benchmarks/ets2_android_capture.sh
adb devices
# Start ETS2 in the target container, then run on the host:
benchmarks/ets2_android_capture.sh <package-or-process-name> results/fex-reference.csv 120 1
benchmarks/ets2_android_capture.sh <package-or-process-name> results/fex-optimized.csv 120 1
```

Record the game-facing metrics in the table below or in a spreadsheet. A valid comparison requires at least three runs per build after the same warm-up procedure; report the median and the run-to-run spread rather than a single favorable run.

| Build | Run | Average FPS | 1% low FPS | Stutter events | Shader compile time (s) | Peak process RSS (MiB) | Average process CPU (%) | Device / SoC | Winlator/Ludashi version | Notes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- | --- |
| Reference | 1 |  |  |  |  |  |  |  |  |  |
| Reference | 2 |  |  |  |  |  |  |  |  |  |
| Reference | 3 |  |  |  |  |  |  |  |  |  |
| Optimized | 1 |  |  |  |  |  |  |  |  |  |
| Optimized | 2 |  |  |  |  |  |  |  |  |  |
| Optimized | 3 |  |  |  |  |  |  |  |  |  |

## Interpreting the helper CSV

`process_cpu_ticks` is the sum of user and system CPU ticks from `/proc/<pid>/stat`. Convert the delta to CPU time using the device clock tick rate and compare it with the elapsed wall time and the number of online CPUs. `process_rss_kib` is the process resident set size at each sample. `system_mem_available_kib` is the Android kernel's available-memory estimate. These values are useful for comparing runs on the same device, but they are not a substitute for FPS or frame-time data.

## Required report discipline

Do not describe the optimized build as native execution. Report it as reduced translation overhead only when the device measurements support that conclusion. If no Android device is connected to the development environment, leave the game metrics blank and attach the user's captured results after testing.
