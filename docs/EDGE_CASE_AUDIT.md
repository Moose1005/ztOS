# ztOS herolight - Edge Case Audit & Safety Analysis

**Auditor:** Automated + Human Review  
**Date:** 2026-10-25  
**Device:** Samsung Galaxy S7 (SM-G930W8)  
**Status:** Alpha - Not for production use

---

## 1. Brick Vectors

### 🔴 CRITICAL: EFS Partition Loss
**Vector:** User flashes incorrect image, corrupted EFS, or wipe without backup  
**Impact:** Permanent loss of IMEI, Wi-Fi MAC, Bluetooth MAC, RF calibration  
**Recovery:** None. Only backup restore can fix.  
**Mitigation in installer:**
- EFS is on the `stockPartitions` allowlist - installer NEVER touches it
- Backup verification step before any flash
- Loud warning in UI about EFS importance

### 🔴 CRITICAL: Knox eFuse Trip
**Vector:** OEM unlocking triggers one-shot eFuse  
**Impact:** Permanent. Samsung Pay, Secure Folder, Knox container dead forever  
**Recovery:** None.  
**Mitigation:**
- Multiple confirmation dialogs in installer
- Explicit "I understand this is irreversible" checkbox
- Links to Samsung Knox documentation

### 🟡 HIGH: Wrong Device Flash
**Vector:** User selects wrong device model, flash proceeds  
**Impact:** Soft-brick, possible partition table corruption  
**Recovery:** Re-flash correct images via download mode  
**Mitigation:**
- ODIN chip ID verification before flash
- Model detection from PIT download
- Warning if detected device doesn't match selected model

### 🟡 HIGH: Power Loss During Flash
**Vector:** USB disconnect, battery dies, user unplugs  
**Impact:** Partially written partition, boot loop, or brick  
**Recovery:** Download mode always works (S-Boot in ROM)  
**Mitigation:**
- Battery level check (>30%) before starting
- Chunked writes with progress tracking
- Clear "DO NOT UNPLUG" warnings during flash

### 🟡 HIGH: Windows Driver Conflict
**Vector:** Samsung USB driver claims ODIN interface before WebUSB can  
**Impact:** WebUSB cannot connect to device  
**Recovery:** Use Zadig to replace driver with WinUSB  
**Mitigation:**
- Prerequisite check detects Windows and shows Zadig instructions
- Detailed step-by-step walkthrough with screenshots
- Fallback to heimdall CLI instructions

---

## 2. Partition Safety

### Protected Partitions (NEVER flashed by installer)
| Partition | Contains | Flash Guard |
|-----------|----------|-------------|
| EFS | IMEI, MACs, calibration | Hard-coded in `stockPartitions` array |
| CPEFS | Cellular parameters | Hard-coded in `stockPartitions` array |
| RADIO | Modem firmware | Hard-coded in `stockPartitions` array |
| SYSTEM | Android system | Hard-coded in `stockPartitions` array |
| VENDOR | Android vendor | Hard-coded in `stockPartitions` array |
| PARAM | Device parameters | Hard-coded in `stockPartitions` array |
| MISC | Recovery/misc data | Hard-coded in `stockPartitions` array |

### Flashable Partitions (Installer CAN write)
| Partition | Contains | Verification |
|-----------|----------|--------------|
| BOOT | ztOS kernel | SHA-256 check |
| RECOVERY | TWRP | SHA-256 check |
| USERDATA | ztOS rootfs | Size check, write verification |

### Safety Code Review
```typescript
// In orchestrator.ts - hard-coded allowlist
stockPartitions: ['SYSTEM', 'VENDOR', 'EFS', 'CPEFS', 'RADIO', 'PARAM', 'MISC', 'DTB', 'DTBO']
flashablePartitions: ['BOOT', 'RECOVERY', 'USERDATA']

// In protocol.ts - partition validation before flash
async flashPartition(partitionName: string, fileData: Uint8Array) {
  if (!flashablePartitions.includes(partitionName)) {
    throw new Error(`Partition ${partitionName} is not in the flashable allowlist`);
  }
  // ... proceed with flash
}
```

**Verdict:** ✅ Partition safety is structurally enforced, not just UI warnings.

---

## 3. Boot Safety Chain

### Failsafe Mechanisms

1. **S-Boot ROM (Immutable)**
   - Samsung bootloader lives in mask ROM
   - Cannot be overwritten by any software operation
   - Download mode always accessible via hardware key combo
   - **Verdict:** ✅ Unbrickable at the lowest level

2. **TWRP Fallback**
   - Installer flashes TWRP before ztOS images
   - TWRP provides rescue environment with ADB access
   - Can re-flash any partition from TWRP
   - **Verdict:** ✅ Multiple recovery paths

3. **Watchdog Timer**
   - Exynos 8890 has hardware watchdog
   - Bad kernel image → watchdog reset → download mode
   - **Verdict:** ⚠️ Not yet configured in DTS, needs enabling

4. **INFORM3 Register**
   - Samsung-specific boot mode register
   - Can force recovery/download mode on next boot
   - Used by S9 port for failsafe
   - **Verdict:** ⚠️ Not yet implemented for herolight

### Boot Chain Verification
```
Power On → S-Boot (ROM) → Check INFORM3 → 
  [Download Mode] → USB/ODIN available
  [Normal Boot]   → Load BOOT partition → Kernel → Init
  [Recovery]      → Load RECOVERY partition → TWRP
```

---

## 4. WebUSB / ODIN Protocol Edge Cases

### Case: Device disconnects mid-session
**Behavior:** ODIN session throws `USB_TRANSFER_OUT_FAILED`  
**Handling:** Orchestrator catches error, shows retry dialog  
**Recovery:** User re-enters download mode, clicks retry  

### Case: Device in wrong mode (ADB instead of download)
**Behavior:** `findConnectedDevices()` returns empty  
**Handling:** UI shows "Wrong mode" with correct button combo instructions  
**Auto-detect:** Can detect ADB devices and instruct user to reboot to download mode  

### Case: Multiple Samsung devices connected
**Behavior:** `requestDevice()` shows browser picker with all devices  
**Handling:** User selects correct device; serial number logged  
**Edge:** Two identical models - user must know which is which  

### Case: ODIN NAK (negative acknowledge)
**Behavior:** Device rejects flash request (e.g., SW REV check fail)  
**Handling:** Error shown with code `ODIN_NAK` and hex response  
**Recovery:** Usually means trying to downgrade bootloader - use matching images  

### Case: Corrupted PIT download
**Behavior:** PIT parse fails or partition count is wrong  
**Handling:** Compare against expected partition layout from device config  
**Recovery:** Heimdall can re-flash PIT from stock firmware (DANGEROUS)  

---

## 5. ADB / TWRP Phase Edge Cases

### Case: TWRP doesn't start ADB
**Behavior:** `waitForADBDevice()` times out after 2 minutes  
**Causes:**
- TWRP build without default ADB enabled
- Windows driver issues
- USB cable is charge-only

**Handling:**
- Extend timeout to 5 minutes
- Show "Try different USB cable" hint
- Fallback to manual TWRP swipe instructions

### Case: ADB shell command fails
**Behavior:** `dd` returns non-zero exit code  
**Handling:** Log stderr, show error to user, suggest re-flash  
**Recovery:** Reboot to TWRP, retry from there

### Case: Rootfs push interrupted
**Behavior:** Partial rootfs written to USERDATA  
**Handling:** Chunked writes; verify with checksum after write  
**Recovery:** Re-format USERDATA and re-flash rootfs

### Case: Insufficient space on /tmp in TWRP
**Behavior:** Push fails with "No space left on device"  
**Handling:** Stream writes in smaller chunks, clean up between chunks  
**Mitigation:** Current chunk size is 256MB, TWRP /tmp is usually 1GB+

---

## 6. Image Integrity

### SHA-256 Verification Flow
```
Download image → SHA-256 compute → Compare with release manifest
  ↓ Match            ↓ Mismatch
Flash to device    Abort with verification error
```

### Release Manifest
Each release includes:
- `boot.img` + SHA-256
- `rootfs.img` + SHA-256
- `twrp.img` + SHA-256
- `MANIFEST.json` with all hashes and sizes

### Tamper Detection
- Images downloaded over HTTPS from GitHub Releases
- SHA-256 verified before any flash operation
- Manifest signed with ztOS release key (future)

---

## 7. Known Hardware Quirks

### Exynos 8890-Specific Issues

1. **Mongoose M1 Core Resume**
   - Big cores don't wake from CPU_SUSPEND
   - Workaround: Disable deep idle for big cores in DTS
   - Impact: Higher idle power consumption
   - Status: Known issue, documented in ztOS quirks

2. **UFS Controller Differences**
   - 8890 uses earlier UFS version than 9810
   - S9's ufshcd-exynos driver needs adaptation
   - Risk: UFS timeout or corruption if wrong driver
   - Mitigation: Extensive testing with SD card boot first

3. **DECON v1 vs v2**
   - Display controller differs from S9
   - Panel init sequences may need adjustment
   - Risk: Black screen on boot
   - Mitigation: Framebuffer console as fallback

4. **Sensor Hub Power-Up**
   - Sensor hub needs specific power sequence
   - TWRP sets this up; our kernel may not
   - Impact: Sensors/modem may not work after forced reboot
   - Workaround: One TWRP boot cycle fixes it

---

## 8. Security Considerations

### Threat Model
| Threat | Likelihood | Impact | Mitigation |
|--------|-----------|--------|------------|
| Malicious image in release | Low | Critical | SHA-256 + GitHub release signing |
| Man-in-the-middle download | Low | High | HTTPS only |
| Browser compromise during flash | Medium | High | No sensitive data in browser storage |
| Malicious USB device | Low | Medium | User must explicitly authorize each device |
| Cross-site WebUSB exploit | Low | Medium | Browser same-origin policy, user permission |

### WebUSB Permissions
- Browser shows native permission dialog for each device
- No silent device access possible
- Permission persists per-origin until revoked
- **Verdict:** ✅ Standard WebUSB security model

### Code Signing (Future)
- Images should be signed with ztOS release key
- Installer verifies signature before flash
- Prevents flashing of untrusted images
- **Status:** Not yet implemented

---

## 9. Recovery Scenarios Matrix

| Scenario | Download Mode? | TWRP? | Stock Boot? | Recovery |
|----------|---------------|-------|-------------|----------|
| Bad ztOS kernel | ✅ Yes | ✅ Yes | Flash stock BOOT | Boot stock |
| Bad rootfs | ✅ Yes | ✅ Yes | N/A | Re-flash rootfs |
| Corrupted TWRP | ✅ Yes | 🔴 No | Flash stock RECOVERY | Re-flash TWRP |
| Both bad | ✅ Yes | 🔴 No | Flash stock BOOT+RECOVERY | Full restore |
| EFS lost | ✅ Yes | ✅ Yes | N/A | Restore EFS backup |
| Knox tripped | ✅ Yes | ✅ Yes | N/A | Irreversible |

### Key Insight
**Download mode is the ultimate failsafe.** As long as the user can enter download mode (Volume Down + Home + Power), any software brick can be recovered. The only unrecoverable scenarios are:
1. EFS loss without backup
2. Knox trip (functional, not brick)
3. Physical hardware damage

---

## 10. Recommendations

### Before First Release
- [ ] Implement INFORM3 failsafe register writing
- [ ] Add watchdog timeout configuration
- [ ] Create automated brick test suite (qemu or real device)
- [ ] Implement image signature verification
- [ ] Add battery level check (>30% required)
- [ ] Test all rescue modes on real hardware
- [ ] Document every error code with recovery steps

### For Users
- [ ] ALWAYS run backup.sh before first flash
- [ ] Verify EFS backup integrity (file size should be ~16MB)
- [ ] Store backups on multiple locations (cloud + local)
- [ ] Keep stock firmware package downloaded from Samsung/Frija
- [ ] Use high-quality USB cable (data + power)
- [ ] Ensure battery >50% before flashing
- [ ] Do not use USB hubs - connect directly to motherboard

---

## Audit Summary

| Category | Score | Notes |
|----------|-------|-------|
| Partition Safety | ✅ Good | Hard-coded allowlists prevent EFS/system flash |
| Boot Safety | ⚠️ Fair | Needs INFORM3 + watchdog for full failsafe |
| Protocol Robustness | ⚠️ Fair | ODIN is well-understood; ADB needs real integration |
| Error Handling | ⚠️ Fair | Basic error states defined, needs more granular codes |
| Recovery Paths | ✅ Good | Multiple recovery options documented |
| User Warnings | ✅ Good | Comprehensive warnings about Knox, EFS, data loss |
| Security | ⚠️ Fair | HTTPS + SHA-256; signing not yet implemented |

**Overall Assessment:** The installer architecture is safe for alpha testing with informed users. The main risks are user error (not backing up EFS) and incomplete ADB integration. Before beta release, the failsafe mechanisms (INFORM3, watchdog) must be implemented and tested on real hardware.
