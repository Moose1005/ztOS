# ztOS for Samsung Galaxy S7 (herolight)

[![ztOS Installer](https://img.shields.io/badge/Installer-Live-success)](https://g7qispjjjjky4.kimi.page)
[![Status](https://img.shields.io/badge/Status-Alpha-orange)](docs/README.md)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue)](LICENSE)

**Device:** Samsung Galaxy S7 (SM-G930W8)  
**Codename:** herolight  
**SoC:** Exynos 8890 (4x Mongoose M1 + 4x Cortex-A53)  
**GPU:** Mali-T880 MP12  

> ⚠️ **Alpha Software** - This is a work in progress. Expect bugs, incomplete features, and potential data loss. Always backup your EFS partition before flashing!

---

## Live Web Installer

**[→ Open ztOS Installer](https://g7qispjjjjky4.kimi.page)**

The web installer runs entirely in your browser (Chrome/Edge) using WebUSB:
- Detects your device in download mode
- Flashes TWRP, ztOS kernel, and rootfs automatically
- No software installation required
- Rescue mode for restoring stock firmware

---

## Quick Start

### Prerequisites
- Samsung Galaxy S7 **SM-G930W8** (Canadian Exynos variant)
- USB cable with data support
- Windows: [Zadig](https://zadig.akeo.ie/) for driver setup
- Linux/macOS: No driver setup needed

### Install ztOS

1. **Backup your stock firmware first:**
   ```bash
   ./scripts/backup.sh
   ```

2. **Enable OEM unlock:**
   - Settings → About phone → Tap "Build number" 7 times
   - Developer options → Enable "OEM unlocking"
   - Reboot to download mode → Volume Up to confirm unlock
   - ⚠️ This trips Knox permanently!

3. **Open the [Web Installer](https://g7qispjjjjky4.kimi.page)**
   - Select "Galaxy S7 (herolight)"
   - Follow the guided steps
   - Keep your phone connected throughout

4. **First boot:**
   - Takes 2-3 minutes
   - Connect USB for SSH at `172.16.42.1` (login: alarm / alarm)
   - Open Settings → Wi-Fi to connect to your network

---

## Project Status

| Component | Status |
|-----------|--------|
| Kernel bring-up | 🟡 In Progress |
| Display (DECON/DSI) | 🔴 Not Started |
| Touchscreen | 🔴 Not Started |
| GPU (Panfrost) | 🟡 Configured |
| Wi-Fi (BCM4361) | 🟡 PCIe configured |
| Modem (Shannon 333) | 🟡 Stock cbd needed |
| USB Gadget | 🟡 Configured |
| Audio (ABOX) | 🔴 Not Started |
| Camera | 🔴 Not Started |
| Bluetooth | 🔴 Not Started |
| Sensors | 🔴 Not Started |

See [docs/README.md](docs/README.md) for detailed hardware status and timeline.

---

## Repository Structure

```
├── kernel/              # Mainline kernel port
│   ├── arch/arm64/boot/dts/samsung/
│   │   ├── exynos8890.dtsi          # Base SoC device tree
│   │   └── exynos8890-herolight.dts # Device-specific tree
│   ├── build-herolight.sh           # Build script
│   └── exynos8890_herolight_defconfig
│
├── device/              # Device configuration
│   └── herolight/
│       ├── BoardConfig.mk
│       └── device.mk
│
├── installer/           # Web installer (React + WebUSB + ODIN)
│   ├── src/
│   │   ├── components/   # UI components
│   │   ├── lib/          # ODIN protocol, ADB client
│   │   └── types/        # TypeScript definitions
│   └── dist/             # Built installer
│
├── scripts/             # Helper scripts
│   ├── backup.sh        # CRITICAL: Run before flashing
│   └── flash.sh         # Manual flash helper
│
├── firmware/            # Firmware storage
│   └── stock/           # Stock backups (KEEP SAFE!)
│
└── docs/                # Documentation
    ├── README.md        # Full documentation
    ├── EDGE_CASE_AUDIT.md
    └── CONTRIBUTING.md
```

---

## Building from Source

### Kernel

```bash
# Install prerequisites
sudo apt install gcc-aarch64-linux-gnu device-tree-compiler u-boot-tools

# Build
cd kernel
./build-herolight.sh boot

# Output: out/boot.img
```

### Web Installer

```bash
cd installer
npm install
npm run build

# Deploy dist/ folder to any static host
```

---

## Key Differences from S9 Port

The S9 (starlte) port builds on [SheroAbi's mainline work](https://github.com/SheroAbi/galaxy-s9plus-mainline-linux) for Exynos 9810. The S7 requires building from scratch:

- **No existing Exynos 8890 mainline base** - Using Samsung's 3.18 GPL sources as register reference
- **Mongoose M1 cores** - Custom Samsung big cores with unique power management
- **DECON v1** - Earlier display controller than S9's DECON v2
- **UFS differences** - 8890 uses different UFS controller variant

---

## Safety & Warnings

### ⚠️ Critical
- **Knox eFuse:** OEM unlocking trips this permanently. Samsung Pay, Secure Folder, and Knox container will never work again.
- **EFS Partition:** Contains your IMEI and Wi-Fi/Bluetooth MAC addresses. If lost without backup, cellular is **permanently broken**.
- **Data Loss:** Flashing ztOS erases USERDATA. Back up photos, contacts, and files first.

### Recovery
- **Download mode always works** - S-Boot lives in ROM and cannot be overwritten
- **TWRP recovery** - Volume Up + Home + Power
- **Stock restore** - Use rescue mode in web installer or `./scripts/flash.sh stock-full`

See [docs/EDGE_CASE_AUDIT.md](docs/EDGE_CASE_AUDIT.md) for comprehensive safety analysis.

---

## Contributing

We need help with:
- Kernel driver porting (UFS, DECON, DSI)
- Device tree verification
- Web installer testing on real hardware
- Documentation improvements

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for setup and workflow.

---

## License

- **Kernel & DTS**: GPL-2.0-only (Linux kernel compatible)
- **Installer & Tools**: GPL-3.0-or-later
- **ztOS Userspace**: Follows upstream [ztOS licensing](https://github.com/Zerone-Laboratories/ztOS)

---

## Acknowledgments

- Samsung for GPL kernel sources
- [SheroAbi](https://github.com/SheroAbi) for the S9+ mainline reference
- [Zerone Laboratories](https://github.com/Zerone-Laboratories) for ztOS
- postmarketOS community for Exynos documentation
- Panfrost/Mesa developers for open-source Mali drivers
- heimdall developers for reverse-engineering the ODIN protocol
