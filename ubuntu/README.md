# Ubuntu 26.04 LTS: ThinkPad E14 Gen 2 (Intel, 20TA)

Tested with USB `06cb:00da`, Ubuntu libfprint `1:1.95.1+tod1-0ubuntu2`,
fprintd `1.94.5-4` and GDM `50.1-0ubuntu0.1`. This is an experimental
system-wide TOD plugin for this USB ID only.

| Hardware test | Observed result |
| --- | --- |
| Enroll, then verify via fprintd | Registered finger accepted; another finger rejected |
| Verify after suspend/resume | Passed; automatic screen locking on suspend was not confirmed |
| Manually lock GNOME and unlock | Finger accepted |
| GDM after cold boot | Fingerprint opened the user session on both attempts. GNOME Shell aborted in the first session and returned to the greeter; the second login persisted. Cause of the crash not established. |

GDM used Ubuntu's existing `gdm-fingerprint` stack. No changes to PAM were
needed. A password-protected GNOME login keyring can still prompt for its
password. Fingerprint authentication for sudo and polkit was not tested here.

## Build and inspect

Install `build-essential binutils git meson ninja-build pkg-config innoextract wget
libusb-1.0-0-dev libssl-dev libfprint-2-tod-dev libgusb-dev libjson-glib-dev
libcap-dev libseccomp-dev libglib2.0-dev libdbus-1-dev libudev-dev systemd-dev`.
Then run `bash ubuntu/build.sh` **as your normal user**. It prints the path to a
local `.deb`; it does not install anything. To use a previously downloaded
Lenovo installer, set `LENOVO_INSTALLER` to its absolute path.

The build uses the [Ubuntu combined patch](https://github.com/Mandi-steph/synaptics-06cb-00da-ubuntu),
including francescomcrtl's patches and xxmarkxx8's [v108 and shutdown fixes](https://github.com/francescomcrtl/synaptics-00da-linux/issues/4),
and [synaTudor PR 67](https://github.com/Popax21/synaTudor/pull/67).
The final patch follows the [E14 Gen 2 report](https://github.com/Popax21/synaTudor/issues/57#issuecomment-6549698449):
handle WM_QUIT and notification cleanup, install the udev rules in `rules.d`,
and match only the device supported by the embedded v108 driver.
The download hash is from [Lenovo's manifest](https://download.lenovo.com/pccbbs/mobiles/r16sf12w_2004_2_.xml).
Do not upload the generated package: it contains Lenovo DLLs.

## Install and test

Verify your password login first. Opening the device may change its pairing;
removing the package does not undo pairing. Inspect the package with
`dpkg-deb -c /absolute/path/to/package.deb` and check for pre-existing Tudor
files before installing. Do not overlay a previous manual installation.

```sh
sudo apt install --no-remove /absolute/path/to/package.deb
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --attr-match=idVendor=06cb --attr-match=idProduct=00da
fprintd-list "$USER"
fprintd-enroll -f right-index-finger
fprintd-verify -f right-index-finger
```

Verify both a non-matching and a matching finger. The launcher is D-Bus
activated; it does not need `systemctl enable`. Test manual screen unlock
and a fresh GDM login separately. Do not copy the Arch PAM examples.

To uninstall, run `sudo bash ubuntu/uninstall.sh`. It removes the local
package via apt, preserving pairing data, fingerprints and PAM settings.
