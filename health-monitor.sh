#!/bin/bash

# Linux System Health Monitor Script
# Author: Marwan Ahmed
# Description: Monitors system performance and generates a report.

# Create logs directory if not exists
LOG_DIR="logs"
mkdir -p $LOG_DIR

# Get current date for the log file
DATE=$(date '+%Y-%m-%d')
LOG_FILE="$LOG_DIR/system_report_$DATE.log"

# Generate system report
{
    echo "=== System Health Report: $DATE ==="
    echo "------------------------------------"
    
    # CPU usage
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print "  " $2 "% used"}'
    echo ""

    # Memory usage
    echo "Memory Usage:"
    free -h | awk '/Mem:/ {print "  Used: "$3", Free: "$4}'
    echo ""

    # Disk usage
    echo "Disk Usage:"
    df -h | awk '$NF=="/"{print "  Total: "$2", Used: "$3", Available: "$4}'
    echo ""

    # Network usage
    echo "Network Usage:"
    ifstat 1 1 | awk 'NR==3 {print "  Download: "$1" KB/s, Upload: "$2" KB/s"}'
    echo ""

    # Top 5 processes by CPU usage
    echo "Top 5 Processes by CPU Usage:"
    ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6
    echo ""

    # Top 5 processes by Memory usage
    echo "Top 5 Processes by Memory Usage:"
    ps -eo pid,comm,%mem --sort=-%mem | head -n 6
    echo ""
} > $LOG_FILE

echo "System health report saved to $LOG_FILE"
