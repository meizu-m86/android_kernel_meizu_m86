CURRENT_DIR = $(shell pwd)
CPUS = $(shell cat /proc/cpuinfo | grep processor | wc -l)
UBUNTU_OUT ?= $(CURRENT_DIR)/ubuntu_out
UBUNTU_INITRD=$(UBUNTU_OUT)/initrd.img-touch
PREBUILT_KERNEL_IMAGE=$(UBUNTU_OUT)/arch/arm64/boot/Image
UBUNTU_BOOTIMG=$(UBUNTU_OUT)/boot.img
ifeq ($(USE_CCACHE),1)
CCACHE=ccache
else
CCACHE=
endif
TURBO_CROSS_COMPILE ?=$(CCACHE) $(CURRENT_DIR)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
MKIMG=./prebuilts/mkbootimg
CORE_NAME=vivid_overlay
$(UBUNTU_OUT):
	mkdir -p $@

$(PREBUILT_KERNEL_IMAGE): $(UBUNTU_OUT)
	make CROSS_COMPILE="$(TURBO_CROSS_COMPILE)" O=$(UBUNTU_OUT) ARCH=arm64 VARIANT_DEFCONFIG= SELINUX_DEFCONFIG= m86_user_defconfig -j$(CPUS)
	make CROSS_COMPILE="$(TURBO_CROSS_COMPILE)" O=$(UBUNTU_OUT) ARCH=arm64 headers_install -j$(CPUS)
	make CROSS_COMPILE="$(TURBO_CROSS_COMPILE)" O=$(UBUNTU_OUT) CFLAGS_MODULE="-fno-pic" ARCH=arm64 Image -j$(CPUS)

$(UBUNTU_INITRD): $(UBUNTU_OUT)
	cp prebuilts/initrd/initrd.img-touch-arm64 $(UBUNTU_OUT)/initrd.img-touch; \

PHONY += bootimage
bootimage: $(PREBUILT_KERNEL_IMAGE) $(UBUNTU_INITRD)
	$(MKIMG) --kernel $(PREBUILT_KERNEL_IMAGE) --ramdisk $(UBUNTU_INITRD) --cmdline "console=ttyFIQ2,115200n8 androidboot.console=ttyMSM0 androidboot.hardware=m86 earlycon=exynos4210,0x14c20000 console=tty0" --base 0x40000000 --pagesize 4096 --kernel_offset 0x80000 --ramdisk_offset 0x2000000 --output $(UBUNTU_BOOTIMG)

