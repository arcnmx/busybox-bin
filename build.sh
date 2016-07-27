#!/bin/sh
set -eu

BUSYBOX_VERSION="1.25.0"

OUT="$1"

curl -fsSL "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2" |
	tar xvj

cp defconfig "busybox-${BUSYBOX_VERSION}/.config"

(
	cd "busybox-${BUSYBOX_VERSION}"
	make oldconfig
	make -j4
	make install
)

cp "busybox-${BUSYBOX_VERSION}/_install/bin/busybox" "$OUT"
