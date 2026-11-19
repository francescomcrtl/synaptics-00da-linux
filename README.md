# Synaptics 06cb:00da Fingerprint Reader on Linux

<p align="center">
  <a href="https://paypal.me/fraxdea0102">
    <img src="https://img.shields.io/badge/Donate-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Donate with PayPal"/>
  </a>
</p>

> If this project saved you hours of frustration, consider buying me a coffee ☕

Linux support for the **Synaptics 06cb:00da** fingerprint reader (ThinkPad E15 Gen 2 and similar), based on [synaTudor](https://github.com/Popax21/synaTudor) with additional patches to support this specific device.

## Tested hardware

For **Ubuntu 26.04 on ThinkPad E14 Gen 2**, see the separate [Ubuntu build, test results and removal instructions](ubuntu/README.md).

| Field | Value |
|-------|-------|
| USB ID | `06cb:00da` |
| Family | VSI 55D |
| Firmware | ROM 10.1 (Jan 17 2020) |
| Tested on | ThinkPad E15 Gen 2 — CachyOS (Arch-based) |

## What these patches add

synaTudor upstream supports `06cb:00be`. These patches extend it to `06cb:00da`:

- **udev rules** — added `06cb:00da` device entry
- **libfprint-tod** — added `06cb:00da` to the driver device table
- **`user32.c`** (new file) — Win32 stubs required by the `00da` firmware:
  - `RegisterPowerSettingNotification` → no-op
  - `WTSRegisterSessionNotification` → returns TRUE
- **`reg.c`** — `RegQueryInfoKeyW` stub (firmware queries it at init)
- **`module.c`** — fixed `GetModuleHandleA/W` NULL self-handle, and `GetModuleHandleExW` FROM_ADDRESS address lookup
- **`api.h`** — added `base_addr`/`image_size` fields to `winmodule` (required for the above)
- **`wdf.c`** — `wdf_func_stub` calling convention fix (`__winfnc`), stub for WDF loader pad functions
- **`wdf/device.c`** — additional WDF device function stubs required by this firmware
- **`download_driver.sh`** — skip hash check (Lenovo updated the installer) and map v108 DLL names to the v104 names the build system expects

## Requirements

- Arch Linux / CachyOS — or any systemd distro with equivalent packages
- `git`, `meson`, `ninja`, `pkg-config`, `innoextract`, `wget`
- `libusb`, `openssl`, `fprintd`

```bash
# Arch / CachyOS
sudo pacman -S git meson ninja pkg-config innoextract wget libusb openssl fprintd
```

## Installation

```bash
git clone https://github.com/francescomcrtl/synaptics-00da-linux.git
cd synaptics-00da-linux
sudo ./install.sh
```

The script will:
1. Clone synaTudor at a pinned commit
2. Apply the patches and copy `user32.c`
3. Build (this downloads the Lenovo driver installer ~30 MB to extract the DLLs)
4. Install and enable the `tudor-host-launcher` systemd service

## Enroll your fingerprint

```bash
sudo tudor_cli /var/lib/tudor/data.db -P0x00da
# type 'y' at the warning prompt, then follow the on-screen instructions
```

## PAM configuration

### sudo — fingerprint first, password as fallback

```bash
sudo cp pam/sudo /etc/pam.d/sudo
```

### SDDM login screen

```bash
sudo cp pam/sddm /etc/pam.d/sddm
```

> **Note on SDDM:** Press Enter on the login screen with an empty password field to activate the fingerprint prompt. This is a known SDDM limitation — SDDM only starts the PAM conversation when the form is submitted. It is not a bug in this driver.

## Manual start (without fprintd)

```bash
sudo systemctl start tudor-host-launcher
sudo tudor_cli /var/lib/tudor/data.db -P0x00da
```

## Credits

- [synaTudor](https://github.com/Popax21/synaTudor) by **Popax21** — the reverse-engineered Linux driver for Synaptics Tudor fingerprint readers. This project would not exist without it.
- Patches, reverse engineering work, and `06cb:00da` support by **[francescomcrtl](https://github.com/francescomcrtl)**
- Patch development assisted by **[Claude](https://claude.ai)** (Anthropic) — the Windows API stubs, WDF fixes, and debugging were largely worked out with Claude's help

## License

GPL-2.0 — same as synaTudor.
