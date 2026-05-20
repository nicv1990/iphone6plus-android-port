# Help Wanted: A8 ANS / RTBuddy / ASPStorage

We are looking for people who understand any of these areas:

- Apple A7/A8 IOP systems
- old RTBuddy management protocol
- Apple ANS / ASPStorage / ASPBlockStorage
- Linux block driver bring-up
- m1n1 / Hoolock Linux internals
- iOS kernelcache reverse engineering for storage drivers

## Known Good Facts

The iOS storage path is:

```text
ans@8040000
  iop-ans-nub
    RTBuddy
      ANSEndpoint1
        ASPStorage
          ASPBlockStorage
            IONANDBlockDevice
              Apple NAND Media -> disk0
```

The Linux diagnostic path currently reaches:

```text
ANS MMIO
  AKF mailbox
    old RTBuddy management loop
```

The current stable receive loop is:

```text
0600000000000012
0600000000000004
00b0000000000010
0070000000000001
```

The newest diagnostic driver exposes:

```text
/sys/bus/platform/devices/208040000.ans/oldrtbuddy_plan
/sys/bus/platform/devices/208040000.ans/oldrtbuddy_ordered_reply
/sys/bus/platform/devices/208040000.ans/oldrtbuddy_packet_model
/sys/bus/platform/devices/208040000.ans/oldrtbuddy_packet_addr_plan
/sys/bus/platform/devices/208040000.ans/oldrtbuddy_packet_addr_send
```

`oldrtbuddy_ordered_reply` only sends if the full stable loop is observed, no unknown messages are present, and the current message matches the requested phase.

Recovered old RTBuddy packet shapes from iOS 12.5.8:

```text
old-small: prefix=0400000054000000 word0=0x6 word1=0x11 total_len=0x54
old-0x40: prefix=0400000054000000 word0=0x7 word1=0x44 total_len=0x120
```

The latest packet-address candidate run tested plain address, shifted address,
address + length, and length + address mailbox payloads. Linux-side writes
completed, but the controller did not advance to endpoint discovery. This
strongly suggests the missing piece is the higher-level old RTBuddy
shared-buffer transaction format, not a single mailbox word.

## Best Next Contributions

- Identify the old RTBuddy shared-buffer transaction object layout.
- Compare A8 `RTBuddyManagementEndpoint` behavior from iOS 12.5.8 against the Linux diagnostic driver.
- Identify packet header, sequence/status, callback/context, descriptor, and queue ownership fields.
- Find how `ANSEndpoint1` is advertised and started on A8.
- Sketch a minimal read-only ASPStorage / ASPBlockStorage command path.

Please start from `A8_STORAGE_FINDINGS.md`; it has the detailed test timeline and evidence.
