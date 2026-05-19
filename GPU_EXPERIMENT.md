# A8 PowerVR GPU Experiment

Goal: test the real PowerVR driver path on the iPhone 6 Plus instead of assuming GPU acceleration is impossible.

## What We Know

- iPhone 6 Plus uses Apple A8/T7000 with PowerVR GX6450.
- Hoolock Linux contains the upstream `drivers/gpu/drm/imagination` PowerVR Rogue DRM driver.
- Hoolock/pmaports configs currently disable `CONFIG_DRM_POWERVR`.
- T7000 DTS currently has no GPU node.
- T7000 PMGR DTS does have `ps_gfx`, so there is at least a known graphics power domain.
- Hoolock m1n1 has GPU/ADT code that looks for `/arm-io/sgx`, but its main `dt_set_gpu()` path currently targets Apple AGX-era chips, not T7000 PowerVR.

## Experiment 1: Enable The Driver

Apply this fragment while building the kernel:

```sh
./scripts/kconfig/merge_config.sh .config ../kernel-config/powervr-experiment.fragment
make -j$(nproc) LLVM=1 ARCH=arm64 Image.gz dtbs
```

Expected outcome without a GPU DTS node:

- Kernel builds the PowerVR DRM driver.
- Driver probably does not bind to anything.
- No `/dev/dri/renderD*` from PowerVR.

That is still useful because it proves the driver compiles in the Hoolock kernel.

## Experiment 2: Boot And Inspect Firmware Data

Boot m1n1/Linux on the actual phone and capture logs. We need to learn:

- Does the phone ADT contain `/arm-io/sgx`?
- What are its `reg` entries?
- What interrupt does it use?
- Does it expose `perf-states`, `perf-state-count`, or firmware/version properties?
- Are there `clock-gates` or PMGR device IDs associated with `/arm-io/sgx`?

Look for m1n1 lines containing:

```text
ADT: GPU
FDT: GPU
sgx
```

Look for Linux lines containing:

```text
powervr
pvr
drm
firmware
```

## Experiment 3: Add A First DTS Node

Only after we know the ADT data, add a tentative GPU node to `t7000.dtsi` using the upstream binding:

```dts
gpu: gpu@... {
	compatible = "img,img-rogue";
	reg = <...>;
	clocks = <...>;
	clock-names = "core";
	interrupts = <...>;
	power-domains = <&ps_gfx>;
	status = "okay";
};
```

This node is intentionally incomplete until the phone gives us real addresses, IRQs, and clock data.

## Pass / Fail Criteria

Pass:

- PowerVR driver probes.
- Firmware request appears in logs.
- `/dev/dri/renderD*` appears.

Better pass:

- Mesa can open the render node.
- A minimal EGL/Vulkan test runs.

Fail:

- No usable `/arm-io/sgx` data.
- Driver cannot support GX6450/BVNC.
- Matching firmware cannot be found or extracted.
