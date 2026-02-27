#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DEFAULT_LOG_DIR="logs"
DEFAULT_TOP_COUNT=5
DEFAULT_NET_INTERVAL=1

LOG_DIR="$DEFAULT_LOG_DIR"
OUTPUT_FILE=""
TOP_COUNT="$DEFAULT_TOP_COUNT"
NET_INTERVAL="$DEFAULT_NET_INTERVAL"
NO_NETWORK=0
FORMAT="text"

DATE="$(date '+%Y-%m-%d')"
TIMESTAMP="$(date '+%Y-%m-%dT%H:%M:%S%z')"

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [options]

Options:
  --output <file>      Write report to a specific file.
  --log-dir <dir>      Directory for generated reports (default: $DEFAULT_LOG_DIR).
  --top <n>            Number of top processes to include (default: $DEFAULT_TOP_COUNT).
  --interval <sec>     Network sampling interval in seconds (default: $DEFAULT_NET_INTERVAL).
  --no-network         Skip network usage section.
  --format <text|json> Output format (default: text).
  --help               Show this help message.
EOF
}

error() {
    echo "Error: $*" >&2
    exit 1
}

warn() {
    echo "Warning: $*" >&2
}

require_commands() {
    local commands=("awk" "date" "df" "dirname" "free" "grep" "head" "mkdir" "ps" "sed" "sleep")
    local missing=()
    local cmd

    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if (( NO_NETWORK == 0 )) && ! command -v ifstat >/dev/null 2>&1; then
        warn "Command 'ifstat' not found. Network section will be skipped."
        NO_NETWORK=1
    fi

    if (( ${#missing[@]} > 0 )); then
        error "Missing required command(s): ${missing[*]}"
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output)
                [[ $# -ge 2 ]] || error "--output requires a file path"
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --log-dir)
                [[ $# -ge 2 ]] || error "--log-dir requires a directory path"
                LOG_DIR="$2"
                shift 2
                ;;
            --top)
                [[ $# -ge 2 ]] || error "--top requires a numeric value"
                TOP_COUNT="$2"
                shift 2
                ;;
            --interval)
                [[ $# -ge 2 ]] || error "--interval requires a numeric value"
                NET_INTERVAL="$2"
                shift 2
                ;;
            --no-network)
                NO_NETWORK=1
                shift
                ;;
            --format)
                [[ $# -ge 2 ]] || error "--format requires 'text' or 'json'"
                FORMAT="$2"
                shift 2
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                error "Unknown argument: $1"
                ;;
        esac
    done

    [[ "$TOP_COUNT" =~ ^[1-9][0-9]*$ ]] || error "--top must be a positive integer"
    [[ "$NET_INTERVAL" =~ ^[1-9][0-9]*$ ]] || error "--interval must be a positive integer"
    [[ "$FORMAT" == "text" || "$FORMAT" == "json" ]] || error "--format must be 'text' or 'json'"
}

prepare_output_file() {
    if [[ -z "$OUTPUT_FILE" ]]; then
        mkdir -p "$LOG_DIR"
        OUTPUT_FILE="$LOG_DIR/system_report_${DATE}.${FORMAT}"
    else
        local parent_dir
        parent_dir="$(dirname "$OUTPUT_FILE")"
        mkdir -p "$parent_dir"
    fi
}

collect_cpu_usage() {
    local cpu_line
    cpu_line="$(grep '^cpu ' /proc/stat)" || return 1
    read -r _ u1 n1 s1 i1 w1 irq1 sirq1 st1 _ <<<"$cpu_line"
    local total1=$((u1 + n1 + s1 + i1 + w1 + irq1 + sirq1 + st1))
    local idle1=$((i1 + w1))

    sleep 1

    cpu_line="$(grep '^cpu ' /proc/stat)" || return 1
    read -r _ u2 n2 s2 i2 w2 irq2 sirq2 st2 _ <<<"$cpu_line"
    local total2=$((u2 + n2 + s2 + i2 + w2 + irq2 + sirq2 + st2))
    local idle2=$((i2 + w2))

    local total_delta=$((total2 - total1))
    local idle_delta=$((idle2 - idle1))

    if (( total_delta <= 0 )); then
        echo "N/A"
        return 0
    fi

    awk -v td="$total_delta" -v id="$idle_delta" 'BEGIN { printf "%.2f", (100 * (td - id) / td) }'
}

collect_memory_text() {
    free -h | awk '/^Mem:/ {print "  Used: "$3", Free: "$4", Total: "$2}'
}

collect_memory_json() {
    free -b | awk '/^Mem:/ {print $2, $3, $4}'
}

collect_disk_text() {
    df -h --output=size,used,avail,target | awk 'NR==1 || $4=="/" {if (NR>1) print "  Total: "$1", Used: "$2", Available: "$3}'
}

collect_disk_json() {
    df -B1 --output=size,used,avail,target | awk '$4=="/" {print $1, $2, $3}'
}

collect_network_kbps() {
    local line
    line="$(ifstat "$NET_INTERVAL" 1 2>/dev/null | awk 'NF>=2 {last=$0} END {print last}')"
    if [[ -z "${line// }" ]]; then
        echo "N/A N/A"
        return 0
    fi

    awk '{print $1, $2}' <<<"$line"
}

render_processes_text() {
    local metric="$1"
    ps -eo pid,comm,"$metric" --sort="-$metric" | head -n $((TOP_COUNT + 1))
}

escape_json() {
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

generate_text_report() {
    local cpu_usage down up
    cpu_usage="$(collect_cpu_usage || echo "N/A")"
    down="N/A"
    up="N/A"
    if (( NO_NETWORK == 0 )); then
        read -r down up <<<"$(collect_network_kbps)"
    fi

    {
        echo "=== System Health Report: $DATE ==="
        echo "Generated at: $TIMESTAMP"
        echo "------------------------------------"
        echo ""
        echo "CPU Usage:"
        echo "  ${cpu_usage}% used"
        echo ""
        echo "Memory Usage:"
        collect_memory_text || echo "  N/A"
        echo ""
        echo "Disk Usage (root /):"
        collect_disk_text || echo "  N/A"
        echo ""
        echo "Network Usage:"
        if (( NO_NETWORK == 1 )); then
            echo "  Skipped"
        else
            echo "  Download: ${down} KB/s, Upload: ${up} KB/s"
        fi
        echo ""
        echo "Top ${TOP_COUNT} Processes by CPU Usage:"
        render_processes_text "%cpu" || echo "  N/A"
        echo ""
        echo "Top ${TOP_COUNT} Processes by Memory Usage:"
        render_processes_text "%mem" || echo "  N/A"
    } >"$OUTPUT_FILE"
}

generate_json_report() {
    local cpu_usage
    local mem_total mem_used mem_free
    local disk_total disk_used disk_avail
    local net_down net_up
    local top_cpu top_mem

    cpu_usage="$(collect_cpu_usage || echo "N/A")"
    read -r mem_total mem_used mem_free <<<"$(collect_memory_json || echo "0 0 0")"
    read -r disk_total disk_used disk_avail <<<"$(collect_disk_json || echo "0 0 0")"
    net_down="N/A"
    net_up="N/A"
    if (( NO_NETWORK == 0 )); then
        read -r net_down net_up <<<"$(collect_network_kbps)"
    fi
    top_cpu="$(ps -eo pid=,comm=,%cpu= --sort=-%cpu | head -n "$TOP_COUNT" | awk '{$1=$1; print}' | escape_json)"
    top_mem="$(ps -eo pid=,comm=,%mem= --sort=-%mem | head -n "$TOP_COUNT" | awk '{$1=$1; print}' | escape_json)"

    {
        echo "{"
        echo "  \"date\": \"${DATE}\","
        echo "  \"generated_at\": \"${TIMESTAMP}\","
        echo "  \"cpu\": {\"usage_percent\": \"${cpu_usage}\"},"
        echo "  \"memory\": {\"total_bytes\": ${mem_total}, \"used_bytes\": ${mem_used}, \"free_bytes\": ${mem_free}},"
        echo "  \"disk_root\": {\"total_bytes\": ${disk_total}, \"used_bytes\": ${disk_used}, \"available_bytes\": ${disk_avail}},"
        if (( NO_NETWORK == 1 )); then
            echo "  \"network\": {\"status\": \"skipped\"},"
        else
            echo "  \"network\": {\"download_kbps\": \"${net_down}\", \"upload_kbps\": \"${net_up}\"},"
        fi
        echo "  \"top_processes\": {"
        echo "    \"cpu\": ["
        awk 'NF { printf "      \"%s\",\n", $0 }' <<<"$top_cpu" | sed '$ s/,$//'
        echo "    ],"
        echo "    \"memory\": ["
        awk 'NF { printf "      \"%s\",\n", $0 }' <<<"$top_mem" | sed '$ s/,$//'
        echo "    ]"
        echo "  }"
        echo "}"
    } >"$OUTPUT_FILE"
}

main() {
    parse_args "$@"
    require_commands
    prepare_output_file

    if [[ "$FORMAT" == "json" ]]; then
        generate_json_report
    else
        generate_text_report
    fi

    echo "System health report saved to $OUTPUT_FILE"
}

main "$@"
