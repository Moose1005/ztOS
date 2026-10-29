# ztOS Samsung Galaxy S7 (herolight) Port

**Device:** Samsung Galaxy S7 (SM-G930W8)  
**Codename:** herolight  
**SoC:** Exynos 8890 (4x Mongoose M1 + 4x Cortex-A53)  
**GPU:** Mali-T880 MP12  
**RAM:** 4GB LPDDR4  
**Display:** 5.1" Super AMOLED 1440x2560  
**Status:** Alpha (kernel bring-up in progress)

---

## Quick Links

- [Web Installer (Live)](https://g7qispjjjjky4.kimi.page)
- [ztOS Main Repository](https://github.com/Zerone-Laboratories/ztOS)
- [S9 Port Reference](https://github.com/Zerone-Laboratories/ztOS/tree/main/kernel)

---

## Project Structure

```
ztos-herolight-port/
├── kernel/                  # Kernel port files
│   ├── arch/arm64/boot/dts/samsung/
│   │   ├── exynos8890.dtsi          # Base SoC device tree
│   │   └── exynos8890-herolight.dts # Device-specific tree
│   ├── build-herolight.sh           # Build script
│   └── exynos8890_herolight_defconfig
├── device/                  # Device-specific config
├── installer/               # Web installer source
├── firmware/                # Stock firmware dumps
├── docs/                    # Documentation
└── scripts/                 # Helper scripts
```

---

## Hardware Status

| Category | Feature | Status | Notes |
|----------|---------|--------|-------|
| **Boot** | Boot from UFS | 🟡 In Progress | Needs mainline UFS driver adaptation |
| **Boot** | TWRP fallback | ✅ Planned | Same mechanism as S9 |
| **CPU** | All 8 cores | 🟡 Partial | Little cores work; big cores need M1 support |
| **CPU** | Frequency scaling | 🟡 Partial | Requires Exynos 8890 CMU driver |
| **CPU** | Suspend/Idle | 🔴 Not Working | Big cores don't wake from suspend (same as S9) |
| **Display** | DECON scanout | 🟡 In Progress | DSI panel init sequence needed |
| **Display** | Brightness | 🔴 Not Started | PMIC brightness control |
| **Touch** | S6SY761 | 🟡 In Progress | Driver exists in mainline, needs pinmux |
| **GPU** | Mali-T880 | 🟡 Partial | Panfrost supports Midgard; needs DTS enable |
| **Storage** | UFS 2.0 | 🟡 In Progress | Adapt from S9's ufshcd-exynos |
| **Storage** | SD card | 🟡 In Progress | SDHCI should work with minimal changes |
| **USB** | Gadget mode | 🟡 In Progress | DWC3 gadget for installer connectivity |
| **USB** | Host mode | 🔴 Not Started | OTG support |
| **Network** | Wi-Fi BCM4361 | 🟡 In Progress | PCIe + brcmfmac, firmware from stock |
| **Network** | Bluetooth | 🔴 Not Started | UART HCI, firmware needed |
| **Modem** | Shannon 333 | 🟡 Partial | Samsung IPC via stock cbd daemon |
| **Audio** | ABOX DSP | 🔴 Not Started | Adapt from S9's snd-zrn-abox |
| **Audio** | Speakers | 🔴 Not Started | MAX77705 audio amp |
| **Sensors** | Sensor hub | 🔴 Not Started | Samsung SSP firmware |
| **Sensors** | Light/prox | 🔴 Not Started | Via sensor hub |
| **Sensors** | Accel/Gyro | 🔴 Not Started | Via sensor hub |
| **Power** | Battery gauge | 🟡 In Progress | MAX17042 + MAX77705 FG |
| **Power** | Charging | 🟡 In Progress | MAX77705 charger |
| **Power** | Core power down | 🟡 Partial | Same issue as S9 - big cores offline |
| **Camera** | Rear/Front | 🔴 Not Started | Exynos ISP complex |
| **NFC** | NQ331 | 🔴 Not Started | I2C connected |
| **FP** | Fingerprint | 🔴 Not Started | SPI connected |
| **LED** | Notification | 🟡 In Progress | PWM LEDs |
| **Haptics** | Vibrator | 🟡 In Progress | MAX77705 haptic |

### Legend
- ✅ Working
- 🟡 Partial / In Progress
- 🔴 Not Started / Broken

---

## Development Timeline

### Phase 0: Prerequisites (Week 1)
- [x] Dump stock firmware (BOOT, RECOVERY, EFS, SYSTEM, VENDOR, etc.)
- [x] Verify EFS backup integrity
- [x] Enable OEM unlock, verify Knox trip
- [x] Flash TWRP 3.7.0_9-0 for herolight
- [x] Set up build environment (aarch64 toolchain, mkimage, dtc)
- [ ] Document exact partition layout from PIT

### Phase 1: Core SoC Bring-Up (Weeks 2-4)
- [ ] **GIC** - Generic Interrupt Controller (mainline should work)
- [ ] **MCT** - Multi Core Timer verification
- [ ] **CMU** - Clock Management Unit (Exynos 8890 specific)
- [ ] **pinctrl** - Pin controller for GPIO muxing
- [ ] **UART** - Debug console (ramoops + framebuffer console)
- [ ] **PSCI** - Power State Coordination Interface
- [ ] **Secondary cores** - Bring up all 8 CPUs

**Milestone:** Boot to shell on framebuffer console with initramfs

### Phase 2: Storage & Boot (Weeks 4-6)
- [ ] **SDHCI** - SD card boot for development
- [ ] **UFS** - Internal storage (ufshcd-exynos adaptation)
- [ ] **Partition detection** - Read stock partition table
- [ ] **Boot from USERDATA** - Mount ext4 rootfs
- [ ] **TWRP failsafe** - Watchdog + INFORM3 recovery trigger

**Milestone:** Boot Arch Linux ARM from internal UFS

### Phase 3: Essential Peripherals (Weeks 6-9)
- [ ] **DECON + DSI** - Display output
- [ ] **Touchscreen** - S6SY761 multi-touch
- [ ] **USB gadget** - NCM + ACM for installer connectivity
- [ ] **PMIC** - MAX77705/MAX77854 regulators
- [ ] **Battery** - MAX17042 fuel gauge + charging
- [ ] **Thermal** - TMU thermal zones

**Milestone:** Graphical boot with touch, USB networking to host

### Phase 4: Graphics & Performance (Weeks 9-11)
- [ ] **Panfrost** - Mali-T880 GPU acceleration
- [ ] **ztMETRO shell** - Compositor on wlroots
- [ ] **CPU freq scaling** - Dynamic voltage/frequency
- [ ] **zrnperfd** - Power daemon (adapt from S9)

**Milestone:** ztMETRO shell running with GPU acceleration

### Phase 5: Connectivity (Weeks 11-14)
- [ ] **Wi-Fi** - BCM4361 PCIe + brcmfmac
- [ ] **Modem** - Samsung IPC + cbd daemon from stock
- [ ] **SMS** - Send/receive
- [ ] **Mobile data** - 4G LTE
- [ ] **Calls** - Basic voice (audio routing TBD)

**Milestone:** Phone is a usable daily driver (minus camera, BT)

### Phase 6: Polish & Extras (Weeks 14-18)
- [ ] **Audio** - ABOX DSP + speaker/headphone/mic
- [ ] **Sensors** - Sensor hub, auto-brightness
- [ ] **Camera** - Exynos ISP (major effort)
- [ ] **Bluetooth** - UART HCI
- [ ] **NFC** - Basic support
- [ ] **Haptics** - Fine-tuned vibration
- [ ] **LEDs** - Notification patterns

**Milestone:** Feature parity with S9 port

---

## Key Differences from S9 (starlte)

| Aspect | S7 (herolight) | S9 (starlte) |
|--------|---------------|--------------|
| SoC | Exynos 8890 | Exynos 9810 |
| Big cores | Mongoose M1 (custom) | Cortex-M3 (custom) |
| Little cores | Cortex-A53 | Cortex-A55 |
| GPU | Mali-T880 MP12 | Mali-G72 MC18 |
| RAM | 4GB | 4GB |
| Display | 1440x2560 | 1440x2960 |
| Panel | S6E3FA3 | S6E3HA2 |
| Wi-Fi | BCM4361 | BCM4361 |
| Modem | Shannon 333 | Shannon 965 |
| PMIC | MAX77705 + MAX77854 | MAX77705 |
| Fingerprint | Capacitive (front) | Capacitive (rear) |
| Kernel base | None (from scratch) | SheroAbi/galaxy-s9plus-mainline |

### Critical Challenges

1. **No existing mainline base:** Unlike the S9 which built on SheroAbi's work, Exynos 8890 has no equivalent upstream port. We're building from Samsung's 3.18 GPL sources as the register reference.

2. **Mongoose M1 cores:** Samsung's custom big cores. While ARMv8 compatible, they need specific errata workarounds and power management sequences not fully documented in mainline.

3. **UFS vs. eMMC:** The S7 uses UFS 2.0 internal storage. The S9 port's UFS driver needs adaptation for the 8890's UFShci variant.

4. **DECON v1 vs v2:** The 8890 uses an earlier DECON display controller version than the 9810. The DSI and mixer blocks differ.

---

## Building

### Prerequisites

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install build-essential gcc-aarch64-linux-gnu device-tree-compiler \
    u-boot-tools bc bison flex libssl-dev libncurses5-dev git \
    android-tools-mkbootimg abootimg

# Arch Linux
sudo pacman -S base-devel aarch64-linux-gnu-gcc dtc uboot-tools \
    bc bison flex openssl ncurses git android-tools
```

### Clone and Build

```bash
# Clone mainline kernel
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

# Or use stable
git clone --depth 1 --branch v7.1 https://git.kernel.org/.../linux-stable.git linux

# Build
cd kernel
export CROSS_COMPILE=aarch64-linux-gnu-
./build-herolight.sh boot
```

### Output

- `out/kernel.gz` - Compressed kernel image
- `out/dtb` - Device tree blob
- `out/boot.img` - Flashable boot image

---

## Flashing

### Via Web Installer (Recommended)

1. Visit the [ztOS Installer](https://g7qispjjjjky4.kimi.page)
2. Select "Galaxy S7 (herolight)"
3. Follow the guided steps
4. The installer handles ODIN protocol, TWRP flash, and image writing

### Manual (Expert)

```bash
# Enter download mode: Volume Down + Home + Power
# Then Volume Up to confirm

# Flash with heimdall
heimdall flash --BOOT ztos-boot.img --RECOVERY twrp-herolight.img

# Boot to TWRP, then flash rootfs
adb push ztos-rootfs.img /tmp/
adb shell "dd if=/tmp/ztos-rootfs.img of=/dev/block/sda25 bs=4M"
```

---

## Rescue

If the device won't boot:

1. **Download mode always works** - S-Boot cannot be overwritten
2. **Re-flash stock boot** - Use rescue mode in web installer
3. **TWRP recovery** - Volume Up + Home + Power
4. **Full restore** - Flash all stock images via ODIN/heimdall

Stock firmware dumps should be kept in `firmware/stock/`:
- `BOOT.img`
- `RECOVERY.img`
- `EFS.img` (CRITICAL - never lose this)
- `SYSTEM.img`
- `VENDOR.img`

---

## Known Issues & Quirks

### Critical
- **Knox eFuse:** Trips on first unlock. Irreversible. Samsung Pay/Secure Folder dead forever.
- **EFS partition:** Contains IMEI. Corruption = permanent cellular loss. Never flash without backup.

### Hardware
- **No suspend:** Big cores don't wake from CPU_SUSPEND. Screen-off idle drain is higher than Android.
- **Sensor hub init:** May need a TWRP pass to power up after forced reboot (same quirk as S9).
- **Windows drivers:** Samsung USB driver blocks WebUSB. Use Zadig to install WinUSB.

### Software
- **GPU faults:** Mali-T880 may show black patches under heavy load (Panfrost issue).
- **Call audio:** Not routed yet (same as S9).
- **Clock reset:** RTC battery not maintained; time resets to epoch on boot until NTP sync.

---

## Contributing

This port needs help in these areas:

1. **Kernel drivers:** UFS, DECON, DSI panel bring-up
2. **Device tree:** Verifying pinmux, regulators, clocks against stock kernel
3. **Web installer:** Testing ODIN protocol on real hardware
4. **Documentation:** Recording register dumps, boot logs, failure modes

See `docs/CONTRIBUTING.md` for development workflow.

---

## License

- **Kernel drivers & DTS**: GPL-2.0-only (upstream Linux compatible)
- **Installer & tools**: GPL-3.0-or-later
- **ztOS userspace**: Follows upstream ztOS licensing

---

## Acknowledgments

- Samsung for GPL kernel sources (android_kernel_samsung_universal8890)
- [SheroAbi](https://github.com/SheroAbi) for the S9+ mainline reference
- [Zerone Laboratories](https://github.com/Zerone-Laboratories) for ztOS
- The postmarketOS community for Exynos documentation
- Panfrost/Mesa developers for Mali open-source drivers
