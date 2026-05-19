#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
	echo "usage: $0 /dev/cu.usbmodemXYZ" >&2
	exit 2
fi

TTY="$1"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/artifacts/oldrtbuddy-reply-matrix-$(date +%Y-%m-%d-%H%M%S).txt"

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

tests = [
    ("ap_power10", "0060000000000010", "canonical/type6 ap-power candidate"),
    ("ap_power10", "00b0000000000010", "old-layout ap-power echo"),
    ("ap_power10", "00b0000000000020", "old-layout ap-power next-state candidate"),
    ("iop_ack01", "0070000000000001", "old-layout iop-ack echo"),
    ("iop_ack01", "0060000000000001", "canonical/type6 iop-ack candidate"),
    ("state12", "0060000000000012", "canonical/type6 state12 candidate"),
    ("state04", "0060000000000004", "canonical/type6 state04 candidate"),
]

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
    pre = """
echo MATRIX_BEGIN
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_plan
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_state
cat /proc/partitions
""".encode()
    os.write(fd, pre)
    print(read_for(fd, 5))

    for idx, (phase, reply, label) in enumerate(tests, 1):
        cmd = f"""
echo MATRIX_TEST_{idx} {phase} {reply} {label}
echo '{phase} {reply}' > /sys/bus/platform/devices/208040000.ans/oldrtbuddy_ordered_reply
echo MATRIX_STATUS_{idx} $?
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_plan
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_state
cat /proc/partitions
cat /sys/bus/platform/devices/208040000.ans/akf_decode
""".encode()
        os.write(fd, cmd)
        print(read_for(fd, 12))
        time.sleep(0.5)

    post = b"""
echo MATRIX_DMESG
dmesg | grep -i 'T7000 ANS'
dmesg | grep -i 'ordered reply'
echo MATRIX_END
"""
    os.write(fd, post)
    print(read_for(fd, 6))
finally:
    os.close(fd)
PY

echo "$OUT"
