# Artifacts

This folder contains text captures and small evidence files from phone-side runs.

Large generated boot payloads are intentionally not tracked in git. They are reproducible from the source checkouts and the patch in `../patches/`.

Important text captures:

- `ordered-reply-plan-2026-05-18-2238.txt`
  - Confirms the ordered RTBuddy reply path booted on the phone.
  - Shows `stable=1`, `unknown=0`, and `seen_mask=f`.

- `oldrtbuddy-state-2026-05-18-2220.txt`
  - Confirms the old RTBuddy management state-machine view.

- `akf-oldmgmt-decode-2026-05-18-2024.txt`
  - Captures expanded decoding of the stable AKF receive loop.

- `ios-sshrd-aspstorage-ioreg.txt`
  - iOS-side evidence for `ASPStorage`, `ASPBlockStorage`, and `IONANDBlockDevice`.

