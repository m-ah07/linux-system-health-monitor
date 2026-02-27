#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
OUTPUT_FILE="$WORK_DIR/report.txt"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

bash "$ROOT_DIR/health-monitor.sh" --no-network --output "$OUTPUT_FILE" --top 3

[[ -f "$OUTPUT_FILE" ]]
[[ -s "$OUTPUT_FILE" ]]

grep -q "System Health Report" "$OUTPUT_FILE"
grep -q "CPU Usage:" "$OUTPUT_FILE"
grep -q "Memory Usage:" "$OUTPUT_FILE"
grep -q "Disk Usage (root /):" "$OUTPUT_FILE"
grep -q "Network Usage:" "$OUTPUT_FILE"
grep -q "Skipped" "$OUTPUT_FILE"
grep -q "Top 3 Processes by CPU Usage:" "$OUTPUT_FILE"
grep -q "Top 3 Processes by Memory Usage:" "$OUTPUT_FILE"

echo "Smoke test passed."
