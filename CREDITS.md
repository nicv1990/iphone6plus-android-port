# Credits and Acknowledgements

This project builds on years of work from other open-source and research communities. Thank you to everyone whose tools, documentation, and reverse engineering made this experiment possible.

## Projects Used or Referenced

- Hoolock Linux: Linux bring-up work for Apple mobile devices.
  - Local checkout used: `hoolock-linux`
  - Upstream remote: `https://github.com/HoolockLinux/linux.git`

- Hoolock m1n1:
  - Local checkout used: `hoolock-m1n1`
  - Upstream remote: `https://github.com/HoolockLinux/m1n1.git`

- Hoolock documentation:
  - Local checkout used: `hoolock-docs`
  - Upstream remote: `https://github.com/HoolockLinux/docs.git`

- pongoOS / checkra1n ecosystem:
  - Local checkout used: `pongoOS`
  - Upstream remote: `https://github.com/checkra1n/pongoOS.git`

- Project Sandcastle:
  - Local checkout used: `projectsandcastle`
  - Upstream remote: `https://github.com/corellium/projectsandcastle.git`

- postmarketOS pmaports:
  - Local checkout used: `pmaports`
  - Upstream remote: `https://gitlab.com/postmarketOS/pmaports.git`

- SSHRD_Script:
  - Local checkout used: `tools/SSHRD_Script`
  - Upstream remote: `https://github.com/verygenericname/SSHRD_Script.git`

## Specific Things These Projects Helped With

- Booting custom payloads on the iPhone 6 Plus.
- Getting a Linux shell on real hardware.
- Understanding Apple device trees and boot handoff.
- Finding that A8-era `iop,s5l8960x` devices use the older AKF mailbox path.
- Comparing the Linux view against iOS ramdisk evidence.
- Identifying that the real blocker is ANS / RTBuddy / ASPStorage, not a generic Android image.
- Cross-checking the iPhone 6 Plus schematic and A8-era device teardowns to
  separate the physical NAND package question from the Apple storage-controller
  protocol question.

## Our Current Contribution

This repository currently contributes documentation, phone-side test evidence, and a Linux diagnostic patch for the T7000 ANS path:

```text
patches/0001-t7000-ans-akf-oldrtbuddy-diagnostics.patch
```

That patch adds:

- T7000 ANS device-tree node.
- Linux diagnostic driver for the A8 ANS region.
- ASC and AKF mailbox diagnostics.
- old RTBuddy state-machine sampling.
- guarded ordered-reply sysfs path for controlled management experiments.
- recovered old RTBuddy packet staging diagnostics.
- guarded packet-address candidate diagnostics showing that a simple mailbox
  physical-address handoff is insufficient.

All upstream projects remain owned by their respective authors and licenses.
