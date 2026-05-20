# iPhone 6 Plus Linux / Android Storage Bring-up

This repository documents an experimental effort to get a real Linux/Android-based system running on the iPhone 6 Plus (`iPhone7,1`, `N56AP`, Apple A8/T7000).

The current blocker is not Android userspace. Linux boots on the phone, but internal NAND storage is not exposed yet because the A8-era Apple ANS / RTBuddy / ASPStorage path is not implemented in Linux.

## Current Status

Confirmed on real iPhone 6 Plus hardware:

- Custom Linux payloads boot through the existing iPhone bring-up chain.
- Linux exposes a USB shell.
- The T7000 ANS MMIO region at `0x208040000` can be mapped and powered.
- The correct A8-era AKF mailbox is at ANS base plus `0x1000`.
- Linux can receive stable old RTBuddy / ANS management traffic.
- The stable observed loop is:

```text
0600000000000012
0600000000000004
00b0000000000010
0070000000000001
```

- A guarded ordered-reply path now exists in the diagnostic driver.
- Recovered old RTBuddy packet shapes from iOS 12.5.8 are now staged in Linux:

```text
old-small: prefix=0400000054000000 word0=0x6 word1=0x11 total_len=0x54
old-0x40: prefix=0400000054000000 word0=0x7 word1=0x44 total_len=0x120
```

- A guarded packet-address candidate path was tested on real hardware.
- The latest phone-side result showed the controller remained stable after
  packet-address candidates, but storage still did not appear:

```text
oldrtbuddy_state=v1
samples=64 unknown=0 phase=stable-management-loop last_msg=0070000000000001
seen: state12=1 state04=1 ap_power10=1 iop_ack01=1 mask=f
```

Storage is still not visible as the real internal NAND. Linux currently sees only RAM disks plus tiny MTD boot artifacts:

```text
ram0..ram15
mtdblock0
mtdblock1
```

Those MTD devices are not the 128 GB NAND.

## What We Need Help With

The next engineering target is old A8 RTBuddy / ANS protocol bring-up:

1. Reconstruct the old RTBuddy shared-buffer transaction layout.
2. Identify packet header, descriptor, sequence/status, callback/context, and ownership fields.
3. Reach the endpoint map and start `ANSEndpoint1`.
4. Implement enough `ASPStorage` / `ASPBlockStorage` to register a read-only Linux block device.
5. Only after that, try Android userspace or an Android system image.

The packet-address run ruled out a simple physical-address handoff through the
mailbox. The controller tolerated the traffic and stayed in the management
loop, but it did not semantically accept it as a complete transaction.

The iPhone 6 Plus schematic also supports this direction: NAND is a physical
package (`U0604`) behind Apple’s A8-era NAND/ANS/ASP controller path. The
blocker is the controller protocol, not merely the NAND chip package.

The patch in `patches/0001-t7000-ans-akf-oldrtbuddy-diagnostics.patch` adds the current Linux diagnostic driver and T7000 device-tree hook.

## Important Reports

- `iPhone_6_Plus_Android_Bringup_Report.md`
- `iPhone_6_Plus_Android_Bringup_Report.pdf`
- `A8_STORAGE_FINDINGS.md`
- `A8_STORAGE_FINDINGS.pdf`
- `HELP_WANTED.md`
- `CREDITS.md`

## What This Is Not

This is not a claim that Android already fully runs on the iPhone 6 Plus.

The phone can boot Linux code, but internal storage still requires driver work. Android comes later, after Linux can expose the Apple NAND through the A8 ANS / RTBuddy / ASPStorage stack.
