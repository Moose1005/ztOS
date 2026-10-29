# Contributing to ztOS herolight

Thank you for helping bring ztOS to the Samsung Galaxy S7!

## Development Setup

### Required Tools
```bash
# Debian/Ubuntu
sudo apt install build-essential gcc-aarch64-linux-gnu device-tree-compiler \
    u-boot-tools bc bison flex libssl-dev libncurses5-dev git \
    android-tools-mkbootimg abootimg heimdall-flash adb fastboot \
    python3 python3-pip nodejs npm

# Arch Linux
sudo pacman -S base-devel aarch64-linux-gnu-gcc dtc uboot-tools \
    bc bison flex openssl ncurses git android-tools heimdall \
    python python-pip nodejs npm
```

### Repository Structure
```
ztos-herolight-port/
├── kernel/              # Kernel bring-up
│   ├── arch/arm64/boot/dts/samsung/  # Device trees
│   ├── build-herolight.sh            # Build script
│   └── exynos8890_herolight_defconfig # Kernel config
├── device/              # Android/device config (for TWRP builds)
├── installer/           # Web installer (React + WebUSB)
├── firmware/            # Stock dumps, TWRP images
│   └── stock/           # CRITICAL: Keep EFS backups here
├── docs/                # Documentation
├── scripts/             # Helper scripts
└── README.md            # This file
```

## Development Workflow

### 1. Kernel Development

```bash
# Clone mainline kernel
git clone --depth 1 --branch v7.1 https://git.kernel.org/.../linux-stable.git kernel/linux

# Build
cd kernel
./build-herolight.sh boot

# Output: out/boot.img
```

### 2. Device Tree Changes

Edit `kernel/arch/arm64/boot/dts/samsung/exynos8890-herolight.dts`

Key areas:
- **GPIO pinmux:** Verify against stock kernel `gpio-*.dts` files
- **Regulators:** Check MAX77705/MAX77854 voltage rails
- **Clocks:** Match CMU register values from Samsung GPL source
- **Panel:** DSI init sequence from `decon-*` driver

### 3. Testing on Device

**SAFETY FIRST:**
```bash
# 1. Always backup first
./scripts/backup.sh

# 2. Verify EFS backup exists
ls -l firmware/stock/efs.bin

# 3. Flash test kernel
./scripts/flash.sh boot -f kernel/out/boot.img

# 4. If it doesn't boot, enter TWRP and restore:
./scripts/flash.sh stock-boot
```

### 4. Web Installer Development

```bash
cd installer
npm install
npm run dev     # Development server
npm run build   # Production build
```

## Testing Matrix

Before submitting changes, verify:

| Test | Method | Expected Result |
|------|--------|----------------|
| Build | `./build-herolight.sh boot` | Generates boot.img without errors |
| Boot | Flash to device | Reaches initramfs or rootfs |
| Console | Serial/ramoops | Kernel messages visible |
| USB | Connect to PC | Enumerates as RNDIS/ACM gadget |
| Display | Visual check | Shows console or GUI |
| Touch | Touchscreen | Responds to input |
| Storage | `lsblk` | UFS partitions visible |
| Network | `ping 8.8.8.8` | Wi-Fi or USB networking works |

## Code Style

### Kernel / DTS
- Follow Linux kernel coding style
- Use tabs for indentation in DTS files
- Comment all non-obvious register values
- Reference Samsung GPL source with file paths

### TypeScript / Installer
- Use provided ESLint config
- Prefer explicit types over `any`
- Comment complex ODIN protocol logic
- Handle all error cases gracefully

## Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit with clear messages
4. Push and open a Pull Request
5. Include:
   - What changed
   - Why it changed
   - Test results on real hardware (if applicable)
   - Screenshots for UI changes

## Communication

- GitHub Issues: Bug reports, feature requests
- Pull Requests: Code contributions
- Discussions: General questions, brainstorming

## Important Notes

- **Never commit EFS backups or personal data**
- **Never share stock firmware images** (copyrighted by Samsung)
- **Always test on your own device first**
- **Document known failures** - they help others avoid the same pitfalls

## Areas Needing Help

### High Priority
- [ ] UFS driver adaptation for Exynos 8890
- [ ] DECON display controller bring-up
- [ ] DSI panel init sequence (S6E3FA3)
- [ ] MAX77705 PMIC regulator definitions

### Medium Priority
- [ ] Sensor hub (SSP) driver port
- [ ] Bluetooth UART HCI setup
- [ ] ABOX audio DSP integration
- [ ] Camera ISP complex

### Low Priority
- [ ] Notification LED patterns
- [ ] Haptic feedback tuning
- [ ] NFC support
- [ ] Fingerprint sensor

## Resources

- [Samsung GPL Sources](https://opensource.samsung.com/) - Search for SM-G930W8
- [Exynos 8890 TRM](https://developer.samsung.com/exynos) (limited public docs)
- [postmarketOS Exynos Wiki](https://wiki.postmarketos.org/wiki/Samsung_Exynos)
- [Mainline Linux ARM64 Docs](https://docs.kernel.org/arch/arm64/)
- [ODIN Protocol Spec](https://github.com/Benjamin-Dobell/Heimdall/tree/master/heimdall/source) (from heimdall source)
