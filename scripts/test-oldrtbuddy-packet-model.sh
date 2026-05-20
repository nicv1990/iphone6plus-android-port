#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
	echo "usage: $0 /dev/cu.usbmodemXYZ" >&2
	exit 2
fi

TTY="$1"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/artifacts/oldrtbuddy-packet-model-$(date +%Y-%m-%d-%H%M%S).txt"

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

commands = b"""
echo PACKET_MODEL_BEGIN
uname -a
cat /sys/bus/platform/devices/208040000.ans/state
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_packet_model
echo STAGE_OLD_SMALL
echo old-small > /sys/bus/platform/devices/208040000.ans/oldrtbuddy_packet_stage
echo STAGE_OLD_SMALL_STATUS $?
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_packet_dump
echo STAGE_OLD_40
echo old-0x40 > /sys/bus/platform/devices/208040000.ans/oldrtbuddy_packet_stage
echo STAGE_OLD_40_STATUS $?
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_packet_dump
echo CONTROLLER_STATE_AFTER_PACKET_STAGE
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_state
cat /proc/partitions
echo PACKET_MODEL_END
"""

fd = os.open(tty, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
try:
    os.write(fd, b"\n")
    time.sleep(0.5)
    print(read_for(fd, 3), end="")
    os.write(fd, commands)
    print(read_for(fd, 18), end="")
finally:
    os.close(fd)
PY

echo "$OUT"
