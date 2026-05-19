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
```

`oldrtbuddy_ordered_reply` only sends if the full stable loop is observed, no unknown messages are present, and the current message matches the requested phase.

## Best Next Contributions

- Identify what the four old RTBuddy messages mean.
- Compare A8 RTBuddyManagementEndpoint behavior from iOS 12.5.8 against the Linux diagnostic driver.
- Propose the first safe acknowledgement sequence to test through `oldrtbuddy_ordered_reply`.
- Find how `ANSEndpoint1` is advertised and started on A8.
- Sketch a minimal read-only ASPStorage / ASPBlockStorage command path.

Please start from `A8_STORAGE_FINDINGS.md`; it has the detailed test timeline and evidence.

