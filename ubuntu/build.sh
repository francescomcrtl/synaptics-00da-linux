#!/usr/bin/env bash
# Build a local-only Ubuntu 26.04 amd64 test package. No device access.
set -euo pipefail
[[ $EUID != 0 && $(dpkg --print-architecture) == amd64 ]] || {
    echo 'Run as a normal user on Ubuntu amd64.' >&2; exit 1;
}
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/tudor-ubuntu.XXXXXXXX")
echo "Build directory: $work"
base=31dfdb06107fd1c35c9f9ceae72617e98eccc43a
pr67=e45ca0fdd6aff6937934cc3224a7514b715830d7
ref=4ceb946466080f0cd40d4069569f24b0d938e0b4
cd "$work"
if [[ -n ${LENOVO_INSTALLER:-} ]]; then
    cp -- "$LENOVO_INSTALLER" r16sf12w.exe
else
    wget -q https://download.lenovo.com/pccbbs/mobiles/r16sf12w.exe
fi
echo '77a2ae51978038462b6891551d45bd237e27aeb8b56b656a9a17f7b92399c653  r16sf12w.exe' | sha256sum -c -
wget -qO ubuntu.patch "https://raw.githubusercontent.com/Mandi-steph/synaptics-06cb-00da-ubuntu/$ref/patches/00da-ubuntu.patch"
echo 'dd2ea7783c2212d19e5abea996f13cabe4e99480d305c1aca425d1f859373087  ubuntu.patch' | sha256sum -c -
git clone -q https://github.com/Popax21/synaTudor.git src
git -C src checkout -q --detach "$base"
git -C src fetch -q origin "$pr67"
git -C src diff "$base...$pr67" > pr67.patch
git -C src apply ../ubuntu.patch ../pr67.patch "$here/e14-gen2.patch"
meson setup build src --prefix=/usr
ninja -C build
meson install -C build --no-rebuild --destdir "$work/stage"
# Package only the runtime components. /sbin is a symlink on merged-/usr Ubuntu.
mkdir -p pkg/usr/sbin/tudor pkg/DEBIAN
cp -r stage/usr/. pkg/usr/
cp stage/sbin/tudor/{tudor_host,tudor_host_launcher,libtudor.so} pkg/usr/sbin/tudor/
install -m 0644 "$here/control" pkg/DEBIAN/control
udevadm verify pkg/usr/lib/udev/rules.d/60-tudor-libfprint-tod.rules
dpkg-deb --root-owner-group --build pkg synaptics-00da-local.deb
echo "Local package: $work/synaptics-00da-local.deb"
