#!/bin/sh
set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
	echo "usage: $0 /dev/cu.usbmodemXYZ [phase] [reply-hex64]" >&2
	echo "default: phase=ap_power10 reply=0060000000000010" >&2
	exit 2
fi

TTY="$1"
PHASE="${2:-ap_power10}"
REPLY="${3:-0060000000000010}"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/artifacts/oldrtbuddy-ordered-reply-$(date +%Y-%m-%d-%H%M%S).txt"

if [ ! -c "$TTY" ]; then
	echo "Missing serial device: $TTY" >&2
	exit 1
fi

python3 - "$TTY" "$PHASE" "$REPLY" <<'PY' | tee "$OUT"
import os
import select
import sys
import time

tty, phase, reply = sys.argv[1:4]

commands = f"""
echo BEFORE_PLAN
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_plan
echo BEFORE_STATE
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_state
echo SEND_ORDERED_REPLY {phase} {reply}
echo '{phase} {reply}' > /sys/bus/platform/devices/208040000.ans/oldrtbuddy_ordered_reply
echo SEND_STATUS $?
echo AFTER_PLAN
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_plan
echo AFTER_STATE
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_state
echo PARTITIONS
cat /proc/partitions
dmesg | tail -n 60
""".encode()

fd = os.open(tty, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
try:
    os.write(fd, b"\n")
    time.sleep(0.4)
    os.write(fd, commands)

    deadline = time.time() + 15
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

    print(out.decode("utf-8", "replace"))
finally:
    os.close(fd)
PY

echo "$OUT"
