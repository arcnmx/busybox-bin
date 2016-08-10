BUSYBOX_VERSION := 1.25.0
MATRIXSSL_VERSION := 3-8-4-open
MUSL_VERSION := 1.1.15

WORKDIR := $(shell mkdir -p build && pwd)/build

BUSYBOX_DIR := build/busybox-$(BUSYBOX_VERSION)
SSL_HELPER_DIR := $(BUSYBOX_DIR)/networking/ssl_helper
MATRIXSSL_DIR := build/matrixssl-$(MATRIXSSL_VERSION)
MUSL_DIR := build/musl-$(MUSL_VERSION)

BUSYBOX_STAMP := $(BUSYBOX_DIR)/stamp
MATRIXSSL_STAMP := $(MATRIXSSL_DIR)/stamp
MUSL_STAMP := $(MUSL_DIR)/stamp

DEFCONFIG ?= defconfig
ifneq ($(MUSL_TARGET),)
	MUSL_TARGET := --target=$(MUSL_TARGET)
endif

MUSL := $(WORKDIR)/musl
BUSYBOX := $(WORKDIR)/busybox
SSL_HELPER := $(WORKDIR)/ssl_helper
MATRIXSSL_CORE := $(MATRIXSSL_DIR)/core/libcore_s.a
MATRIXSSL_CRYPTO := $(MATRIXSSL_DIR)/crypto/libcrypt_s.a
MATRIXSSL_SSL := $(MATRIXSSL_DIR)/matrixssl/libssl_s.a

export CFLAGS := $(CFLAGS) -ffunction-sections -fdata-sections -fomit-frame-pointer
export LDFLAGS := $(LDFLAGS)
export REALGCC := gcc
export PATH := $(MUSL)/bin:$(PATH)
export MAKE := $(MAKE) -e

all: $(BUSYBOX) $(SSL_HELPER)

$(BUSYBOX_STAMP): ssl_helper.patch
	curl -fsSL https://busybox.net/downloads/busybox-$(BUSYBOX_VERSION).tar.bz2 | \
		tar -xjC$(WORKDIR)
	patch -p1 -d$(SSL_HELPER_DIR) < ssl_helper.patch
	patch -p1 -d$(BUSYBOX_DIR) < busybox_net.patch
	touch $(BUSYBOX_STAMP)

$(MATRIXSSL_STAMP): matrixssl_32bit.patch
	curl -fsSL https://github.com/matrixssl/matrixssl/archive/$(MATRIXSSL_VERSION).tar.gz | \
		tar -xzC$(WORKDIR)
	patch -p1 -d$(MATRIXSSL_DIR) < matrixssl_32bit.patch
	touch $(MATRIXSSL_STAMP)

$(MUSL_STAMP):
	curl -fsSL https://www.musl-libc.org/releases/musl-$(MUSL_VERSION).tar.gz | \
		tar -xzC$(WORKDIR)
	touch $(MUSL_STAMP)

$(BUSYBOX_DIR)/.config: $(BUSYBOX_STAMP) $(DEFCONFIG)
	mkdir -p $(BUSYBOX_DIR)
	cp $(DEFCONFIG) $(BUSYBOX_DIR)/.config
	$(MAKE) -C $(BUSYBOX_DIR) oldconfig

$(MATRIXSSL_SSL): $(MATRIXSSL_STAMP) $(MATRIXSSL_CRYPTO)
	$(MAKE) -C $(MATRIXSSL_DIR)/matrixssl

$(MATRIXSSL_CRYPTO): $(MATRIXSSL_STAMP) $(MATRIXSSL_CORE)
	$(MAKE) -C $(MATRIXSSL_DIR)/crypto

$(MATRIXSSL_CORE): $(MATRIXSSL_STAMP)
	$(MAKE) -C $(MATRIXSSL_DIR)/core

$(BUSYBOX): $(BUSYBOX_STAMP) $(BUSYBOX_DIR)/.config
	$(MAKE) -C $(BUSYBOX_DIR) install
	cp -a $(BUSYBOX_DIR)/_install/bin/busybox $(BUSYBOX)

$(SSL_HELPER): $(BUSYBOX_STAMP) $(MATRIXSSL_CORE) $(MATRIXSSL_CRYPTO) $(MATRIXSSL_SSL)
	$(CC) -Os -DPOSIX -I$(MATRIXSSL_DIR) -Wall \
		$(CFLAGS) \
		$(SSL_HELPER_DIR)/ssl_helper.c \
		$(LDFLAGS) \
		-static -lc $(MATRIXSSL_SSL) $(MATRIXSSL_CRYPTO) $(MATRIXSSL_CORE) \
		-o $(SSL_HELPER)

clean:
	rm -rf "$(WORKDIR)"

$(MUSL): $(MUSL_STAMP)
	cd $(MUSL_DIR) && ./configure --prefix=$(MUSL) --disable-shared $(MUSL_TARGET)
	$(MAKE) -C $(MUSL_DIR) install
	ln -s \
		/usr/include/linux \
		/usr/include/asm /usr/include/asm-generic /usr/include/misc \
		/usr/include/mtd \
		$(MUSL)/include/

musl: $(MUSL)
busybox: $(BUSYBOX)
ssl_helper: $(SSL_HELPER)

.PHONY: clean all musl busybox ssl_helper
