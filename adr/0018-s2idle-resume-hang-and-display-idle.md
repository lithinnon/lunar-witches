# ADR 0018: S2idle Resume Hang Fix & Display Idle Power

> **Status:** Accepted  
> **Date:** 2026-11-01  
> **Scope:** Suspend/Resume, Display Power & Hardware Quirks (`lunar-qualia`, BIOS 308)  

---

## 1. Context & Problem

The ASUS TUF A14 FA401EA froze on wake from the first real S0i3 of each boot whenever `amdgpu.dcdebugmask=0x800` was absent. That mask (ADR 0011) only survived by never reaching S0i3 (0% hardware sleep) and is rejected: IPS must stay on for battery life.

Tested and ruled out as the cause: rtw89 quirks, Panel Replay (`0x400`), `0x1000`, BIOS 308, the CachyOS kernel (stock 7.3 hangs), a recent regression (stock 6.18 hangs), reader ASPM, and reloading the reader driver at boot.

## 2. Root Cause

1. Firmware marks root port `00:02.2` hotplug-capable although the RTS525A reader behind it is soldered on.
2. Firmware sets the reader's subsystem IDs to `1043:202f` on boot but does not restore them after S0i3, so they read back as `10ec:525a`.
3. `pciehp_device_replaced()` compares config space with the IDs cached at enumeration, concludes the device was swapped, and removes it.
4. Removal runs `sync_filesystem` through `bdev_mark_dead` on a card that is already gone, and blocks resume whenever the card is mounted.

Re-enumeration caches the new IDs, which is why only the first real S0i3 of a boot hung. The chain follows a linux-pci thread on the MSI Claw A8 with the same reader on the same port ("Disable native PCIe hotplug on MSI Claw A8 root bridge", August 2026), whose stall analysis was done on that hardware and not repeated here. Evidence on this machine:

- **T19** (driver loaded, card unmounted): 3/3 pass, IDs changed as above, reader re-enumerated on first wake only.
- **T20** (module loaded, card mounted, no workaround): 3/3 pass, 27-29s S0i3 each, no `pciehp` events, one mount for the whole boot.

## 3. Decision

1. **`rtsx-subsystem-ids` Module:** `pkgs/rtsx-subsystem-ids` rewrites the reader's cached subsystem IDs to `10ec:525a` at boot, so `pciehp` sees no change on wake. It only acts on `1043:202f`. An out-of-tree module is used instead of a kernel patch so that kernel updates rebuild one small module rather than the whole LTO kernel.
2. **`0x800` Removed:** `hardware.amdgpu.integrated.disableDcIps` is deleted. No `dcdebugmask` is set.
3. **VRR Never on `eDP-1`:** Set through KWin, persisted in `~/.config/kwinoutputconfig.json`, not in this repository. With VRR Always, the desktop stuttered after real sleeps, `amdgpu_dm_handle_vrr_transition` warned on resume, and IPS RCG entries stayed at 0. With Never, three lid sleeps were reported smooth, with no warnings and RCG entries rising.

## 4. Consequences

- The kernel stall bug itself remains and is only avoided here. Upstream patches were proposed in the linux-pci thread but were not in master as of 7.3. Drop this module if an upstream quirk covers this board.
- The kernel is tainted (`O`) by the out-of-tree module, and the reader's subsystem reads as Realtek from boot.
- If a BIOS update changes the boot-time IDs, the module stops matching and the hang returns on a mounted card. Check `cached subsystem IDs` in the boot log after BIOS updates.
- The VRR setting must be reapplied on a new user profile. VRR on the internal panel is lost, including in games. The battery gain from RCG is unmeasured.
- Changing VRR after a sleep has frozen the display (`Pageflip timed out`, kernel alive). Change it only on a boot with no sleeps yet.
- Open: each lid sleep logged one instant `EBUSY` failure before a successful retry in T18, source unknown; occasional shallow sleeps with 0% residency.
