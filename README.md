# Linux System Health Monitor

Lightweight Bash monitor for generating daily Linux system health reports.

## What It Monitors

- CPU usage (calculated from `/proc/stat`).
- Memory usage.
- Root disk usage (`/`).
- Network download/upload rate (optional).
- Top processes by CPU and memory.

## Features

- Safer script defaults with strict Bash mode.
- Dependency checks with clear warnings/errors.
- Supports `text` and `json` report formats.
- Configurable output path, process count, and network interval.
- Optional network section (`--no-network`) for environments without `ifstat`.

## Requirements

- Linux environment with Bash.
- Commands: `awk`, `date`, `df`, `free`, `ps`, `sed`, `grep`.
- `ifstat` only when network section is enabled.

Install `ifstat` on Ubuntu/Debian:

```bash
sudo apt-get update && sudo apt-get install -y ifstat
```

## Usage

```bash
chmod +x health-monitor.sh
./health-monitor.sh
```

By default, reports are written to:

- `logs/system_report_YYYY-MM-DD.text`

### CLI Options

```bash
./health-monitor.sh [options]
```

- `--output <file>`: Write to a specific file.
- `--log-dir <dir>`: Output directory when `--output` is not provided.
- `--top <n>`: Number of top processes (default `5`).
- `--interval <sec>`: Network sampling interval (default `1`).
- `--no-network`: Skip network section.
- `--format <text|json>`: Report format (default `text`).
- `--help`: Show help.

### Examples

```bash
# Default text report
./health-monitor.sh

# JSON report
./health-monitor.sh --format json

# Custom output file
./health-monitor.sh --output /tmp/system_report.json --format json

# Top 10 processes without network collection
./health-monitor.sh --top 10 --no-network
```

## Sample Output (Text)

```text
=== System Health Report: 2026-02-28 ===
Generated at: 2026-02-28T12:34:56+0000
------------------------------------

CPU Usage:
  14.23% used

Memory Usage:
  Used: 2.9Gi, Free: 5.1Gi, Total: 8.0Gi
```

## Troubleshooting

- `ifstat: command not found`
  - Use `--no-network` or install `ifstat`.
- Empty or invalid report sections
  - Ensure script runs on Linux and required commands are installed.
- Permission denied
  - Run `chmod +x health-monitor.sh` and ensure output directory is writable.

## Automated Checks

This repository includes:

- Smoke test: `tests/smoke-test.sh`
- CI workflow: `.github/workflows/ci.yml`
- Shell linting via `shellcheck`

Run checks locally:

```bash
shellcheck health-monitor.sh tests/smoke-test.sh
bash tests/smoke-test.sh
```

## Run Periodically

Example cron entry (runs every 5 minutes):

```bash
*/5 * * * * /path/to/linux-system-health-monitor/health-monitor.sh
```

## License

This project is released under the `MIT` license. See `LICENSE`.
