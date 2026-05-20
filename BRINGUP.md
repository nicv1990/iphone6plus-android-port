# iPhone 6 Plus Android Bring-up Notes

Target: Apple iPhone 6 Plus, board N56, Apple A8/T7000.

The practical boot chain is:

1. checkm8/palera1n loads pongoOS.
2. pongoOS loads m1n1.
3. m1n1 loads the Hoolock Linux kernel, Apple DTBs, boot args, and initramfs.
4. Linux proves hardware bring-up over USB serial/networking.
5. Android userspace becomes possible after the Linux boot path is repeatable.

## Current Findings

- Hoolock Linux has an iPhone 6 Plus device tree at `arch/arm64/boot/dts/apple/t7000-n56.dts`.
- Hoolock Linux builds `t7000-n56.dtb` from `arch/arm64/boot/dts/apple/Makefile`.
- Hoolock docs list A8 iPhone 6 Plus support for DeviceTree, main display, brightness, and buttons.
- Hoolock docs list A8 USB2 device mode support in `linux-apple`.
- The Hoolock and pmaports kernel configs enable Android binder IPC with `binder,hwbinder,vndbinder`.
- The configs also enable `CONFIG_MEMFD_CREATE`, which modern Android userspace expects.
- The current storage blocker is not Android userspace or APFS. Linux reaches
  the A8 ANS / old RTBuddy management loop, but does not yet implement the
  shared-buffer transaction path needed to start `ANSEndpoint1` and expose
  ASPStorage as a Linux block device.
- Packet-address candidates were tested on real iPhone 6 Plus hardware. The
  controller stayed stable, but did not advance, so the missing piece is not a
  plain physical address or address/length mailbox payload.
- GPU is still listed as TBA for A8. The Hoolock kernel tree contains the upstream Imagination/PowerVR Rogue DRM driver, but A8 configs currently leave `CONFIG_DRM_POWERVR` disabled and the T7000 DTS files do not declare a GPU node yet.
- The T7000 PMGR device tree does include a `ps_gfx` power domain, which is one necessary piece for a GPU node.
- pmaports already has an iPhone 6 package. This workspace adds a local iPhone 6 Plus package in `device/testing/device-apple-iphone6plus`.

## GPU Bring-up Hypothesis

The iPhone 6 Plus uses the Apple A8/T7000 with a PowerVR Rogue-class GX6450 GPU. The kernel already has a generic PowerVR Rogue DRM driver under `drivers/gpu/drm/imagination`, and Mesa has a matching PowerVR userspace driver family. The missing Apple A8-specific work is likely:

1. Enable `CONFIG_DRM_POWERVR`.
2. Identify the A8 GPU MMIO range, interrupt, clocks, reset behavior, and firmware BVNC.
3. Add a GPU node to `arch/arm64/boot/dts/apple/t7000.dtsi` using `img,img-rogue`-style binding data.
4. Wire it to `ps_gfx` and any required Apple clock/power/reset providers.
5. Provide matching `powervr/rogue_<BVNC>_v1.fw` firmware.
6. Boot Linux and look for `/dev/dri/renderD*`.
7. Test Mesa `pvr` with a minimal EGL/Vulkan userspace before attempting Android SurfaceFlinger.

If step 2 or 5 cannot be solved, Android can still boot, but accelerated Android will not be realistic.

See `GPU_EXPERIMENT.md` for the concrete "try it on the phone" path.

## First Boot Target

Available locally:

- `bin/Pongo.bin`
- `bin/palera1n` v2.2.1 for macOS arm64
- `bin/pongoterm`

Still build or download:

- `m1n1.bin`
- `Image.gz`
- `t7000-n56.dtb` and other Apple DTBs
- an arm64 gzip-compressed initramfs

Then create a combined image:

```sh
scripts/make-m1n1-linux.sh
```

Boot path from Hoolock docs:

```sh
scripts/boot-pongo.sh
scripts/send-m1n1-linux.sh /path/to/m1n1-linux.bin
```

## Android Target

Do not start with Pixel UI. Start with Linux and initramfs proof. Once USB networking and a shell work, move to an Android rootfs or Halium-style userspace. Pixel-style UI can be layered only after binder/ashmem or their modern replacements, graphics, input, and storage behavior are understood.

Minimum Android userspace checkpoints after Linux boot:

1. Confirm `/dev/binder`, `/dev/hwbinder`, and `/dev/vndbinder` exist.
2. Confirm USB networking or USB serial gives a reliable shell.
3. Try a tiny initramfs with Android init pieces before a full system image.
4. Try a generic arm64 AOSP or Lineage-style rootfs with hardware services disabled.
5. Add display/input handling before attempting a launcher.
