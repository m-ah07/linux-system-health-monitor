# 🛠️ Linux System Health Monitor

## 📖 Description
A **Shell script** that monitors Linux system performance and generates detailed reports on:
- 🖥️ **CPU Usage**
- 🧠 **Memory Usage**
- 💾 **Disk Usage**
- 🌐 **Network Activity**
- 🔍 **Top Processes**

This tool is lightweight, easy to use, and saves reports for later analysis.

---

## ✨ Features
- 🖥️ **CPU Monitoring**: Displays the current CPU usage.
- 🧠 **Memory Monitoring**: Shows memory usage details.
- 💾 **Disk Usage**: Reports disk space usage for the root partition.
- 🌐 **Network Usage**: Monitors download and upload speeds.
- 🔍 **Process Monitoring**: Lists the top 5 processes by CPU and memory usage.
- 📂 **Logging**: Saves daily reports in the `logs/` directory.

---

## 🚀 Usage
1. **Clone the repository**:
    ```bash
    git clone https://github.com/m-ah07/linux-system-health-monitor.git
    cd linux-system-health-monitor
    ```

2. **Make the script executable**:
    ```bash
    chmod +x health-monitor.sh
    ```

3. **Run the script**:
    ```bash
    ./health-monitor.sh
    ```

4. **Check the logs**:
    ```bash
    cat logs/system_report_YYYY-MM-DD.log
    ```

## 📂 Directory Structure
```plaintext
linux-system-health-monitor/
├── logs/
│   └── system_report_YYYY-MM-DD.log
├── health-monitor.sh 
├── README.md 
├── LICENSE
└── .gitignore
```

## ⚙️ Requirements
- 🐚 **Bash**
- 🌐 **ifstat** command (install with `sudo apt install ifstat`)

## 🤝 Contributions
Contributions are welcome! Feel free to:
- 🔧 Add more monitoring features.
- 🛠️ Improve the existing functionality.
- 📘 Enhance documentation.

## 🌟 Stay Connected
Feel free to **star** ⭐ this repository if you find it helpful!
