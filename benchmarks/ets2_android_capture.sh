#!/usr/bin/env bash
set -euo pipefail

# Capture coarse process CPU/RSS and system memory samples from a connected Android device.
# FPS, stutter, and shader compilation time must be recorded from the same Winlator HUD/scenario.
# Usage: ./benchmarks/ets2_android_capture.sh <package-or-process> <output.csv> [seconds] [interval]

TARGET=${1:?package or process name is required}
OUTPUT=${2:?output CSV path is required}
DURATION=${3:-120}
INTERVAL=${4:-1}

command -v adb >/dev/null 2>&1 || { echo "adb is required" >&2; exit 2; }
mkdir -p "$(dirname "$OUTPUT")"

PID="$(adb shell "pidof '$TARGET' 2>/dev/null | awk '{print \$1}'" | tr -d '\r')"
if [[ -z "$PID" ]]; then
  PID="$(adb shell "pidof '$TARGET' 2>/dev/null" | tr -d '\r' | awk '{print $1}')"
fi
if [[ -z "$PID" ]]; then
  echo "Could not find a running process named/package '$TARGET'. Start ETS2 in Winlator and retry." >&2
  exit 3
fi

read_proc() {
  local now cpu rss mem
  now=$(date +%s)
  cpu=$(adb shell "awk '{print \$14+\$15}' /proc/$PID/stat" | tr -d '\r')
  rss=$(adb shell "awk '/VmRSS:/ {print \$2}' /proc/$PID/status" | tr -d '\r')
  mem=$(adb shell "awk '/MemAvailable:/ {print \$2}' /proc/meminfo" | tr -d '\r')
  printf '%s,%s,%s,%s\n' "$now" "$cpu" "$rss" "$mem" >> "$OUTPUT"
}

echo 'timestamp_epoch,process_cpu_ticks,process_rss_kib,system_mem_available_kib' > "$OUTPUT"
END=$((SECONDS + DURATION))
while (( SECONDS < END )); do
  read_proc
  sleep "$INTERVAL"
done

echo "Captured $TARGET (pid $PID) to $OUTPUT"
