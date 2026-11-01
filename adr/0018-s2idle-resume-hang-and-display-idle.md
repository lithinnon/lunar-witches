# ADR 0018: S2idle Resume Hang Workaround & Display Idle Power

> **Status:** Accepted  
> **Date:** 2026-11-01  
> **Scope:** Suspend/Resume, Display Power & Hardware Quirks (`lunar-qualia`, BIOS 308)  

---

## 1. Context & Problem

The ASUS TUF A14 FA401EA froze on wake from real S0i3 whenever `amdgpu.dcdebugmask=0x800` was absent. That mask (ADR 0011) only survives by never reaching S0i3 (0% hardware sleep) and is rejected: IPS must stay on for battery life.

Tested and ruled out as the cause of the hang: rtw89 quirks, Panel Replay (`0x400`), `0x1000`, BIOS 308, the CachyOS kernel (stock 7.3 hangs), a recent regression (stock 6.18 hangs), reader ASPM, and reloading the reader driver at boot.

`pm_trace` named `rtsx_pci` (`0000:61:00.0`) as the device being resumed at the hang, with `pm_async` both on and off. The hang needs the driver loaded during the first real S0i3 of a boot. With the driver absent for that one sleep, later sleeps resume fine with it loaded.

## 2. Decision

1. **Reader Driver Hook:** `hosts/lunar-qualia/default.nix` unloads `rtsx_pci` and stops the `Tera` mount before each sleep until a sleep has logged real hardware residency, tracked by `/run/rtsx-s0i3-done`, restoring both on wake.
2. **`0x800` Removed:** `hardware.amdgpu.integrated.disableDcIps` is deleted. No `dcdebugmask` is set.
3. **VRR Never on `eDP-1`:** Set through KWin, persisted in `~/.config/kwinoutputconfig.json`, not in this repository. With VRR Always, the desktop stuttered after real sleeps, `amdgpu_dm_handle_vrr_transition` warned on resume, and IPS RCG entries stayed at 0. With Never, three lid sleeps were reported smooth, with no warnings and RCG entries rising.

## 3. Consequences

- Three self-timed and three lid sleeps resumed on generation 219 with 10-33s of S0i3 each. This is a small sample.
- The root cause is unknown, so this is a workaround. A kernel fix would start at `rtsx_pci_resume` in `drivers/misc/cardreader/rtsx_pcr.c`.
- If `Tera` is busy on the first sleep the driver cannot unload, and the hang can still occur. The first sleep of each boot also unmounts it.
- The VRR setting must be reapplied on a new user profile. VRR on the internal panel is lost, including in games. The battery gain from RCG is unmeasured.
- Changing VRR after a sleep has frozen the display (`Pageflip timed out`, kernel alive). Change it only on a boot with no sleeps yet.
- Open: each lid sleep logs one instant `EBUSY` failure before a successful retry, source unknown; occasional shallow sleeps with 0% residency.
