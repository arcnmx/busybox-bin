#!/bin/sh
set -eu

BUSYBOX_VERSION="1.25.0"
MATRIXSSL_VERSION="3-8-4-open"

POSTFIX="${1-$(uname -m)}"

curl -fsSL "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2" |
	tar xvj

cp defconfig "busybox-${BUSYBOX_VERSION}/.config"

(
	cd "busybox-${BUSYBOX_VERSION}"
	make oldconfig
	make -j4
	make install
)

cp "busybox-${BUSYBOX_VERSION}/_install/bin/busybox" "busybox-$POSTFIX"

curl -fsSL "https://github.com/matrixssl/matrixssl/archive/${MATRIXSSL_VERSION}.tar.gz" |
	tar xvz

(
	cd "matrixssl-${MATRIXSSL_VERSION}"
	cp -a "../busybox-${BUSYBOX_VERSION}/networking/ssl_helper" ./
	patch -p1 -dssl_helper < ../ssl_helper.patch
	make libs -j4
	cd ssl_helper
	gcc -Os -DPOSIX -I.. -I../testkeys -Wall ssl_helper.c \
		-lc ../matrixssl/libssl_s.a ../crypto/libcrypt_s.a ../core/libcore_s.a \
		-o ssl_helper
)

cp "matrixssl-${MATRIXSSL_VERSION}/ssl_helper/ssl_helper" "ssl_helper-$POSTFIX"
