#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
	echo "usage: $0 /dev/cu.usbmodemXYZ" >&2
	exit 2
fi

TTY="$1"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/artifacts/oldrtbuddy-transaction-plans-$(date +%Y-%m-%d-%H%M%S).txt"

if [ ! -c "$TTY" ]; then
	echo "Missing serial device: $TTY" >&2
	exit 1
fi

python3 - "$TTY" <<'PY' | tee "$OUT"
import os
import select
import sys
import time

tty = sys.argv[1]
plans = ["canonical4", "oldecho4", "mixed-power-first", "mixed-state-first"]

def read_for(fd, seconds):
    deadline = time.time() + seconds
    out = bytearray()
    while time.time() < deadline:
        readable, _, _ = select.select([fd], [], [], 0.25)
        if not readable:
            continue
        try:
            chunk = os.read(fd, 8192)
        except BlockingIOError:
            continue
        if not chunk:
            break
        out.extend(chunk)
    return out.decode("utf-8", "replace")

fd = os.open(tty, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
try:
    os.write(fd, b"\n")
    time.sleep(0.4)
    os.write(fd, b"""
echo TRANSACTION_BEGIN
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_plan
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_transaction_plan
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_state
cat /proc/partitions
""")
    print(read_for(fd, 5))

    for idx, plan in enumerate(plans, 1):
        os.write(fd, f"""
echo TRANSACTION_TEST_{idx} {plan}
echo '{plan}' > /sys/bus/platform/devices/208040000.ans/oldrtbuddy_transaction
echo TRANSACTION_STATUS_{idx} $?
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_plan
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_state
cat /sys/bus/platform/devices/208040000.ans/akf_decode
cat /proc/partitions
""".encode())
        print(read_for(fd, 14))
        time.sleep(0.5)

    os.write(fd, b"""
echo TRANSACTION_DMESG
dmesg | grep -i 'T7000 ANS'
echo TRANSACTION_END
""")
    print(read_for(fd, 6))
finally:
    os.close(fd)
PY

echo "$OUT"
