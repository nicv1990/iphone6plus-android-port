#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
	echo "usage: $0 /dev/cu.usbmodemXYZ" >&2
	exit 2
fi

TTY="$1"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/artifacts/oldrtbuddy-one-shot-$(date +%Y-%m-%d-%H%M%S).txt"

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

plans = [
    "canonical4",
    "oldecho4",
    "mixed-power-first",
    "mixed-state-first",
]

single_replies = [
    ("ap_power10", "0060000000000010", "canonical/type6 ap-power"),
    ("ap_power10", "00b0000000000010", "old-layout ap-power echo"),
    ("ap_power10", "00b0000000000020", "old-layout ap-power next-state"),
    ("iop_ack01", "0070000000000001", "old-layout iop-ack echo"),
    ("iop_ack01", "0060000000000001", "canonical/type6 iop-ack"),
    ("state12", "0060000000000012", "canonical/type6 state12"),
    ("state04", "0060000000000004", "canonical/type6 state04"),
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

def send(fd, text, wait=5):
    os.write(fd, text.encode())
    output = read_for(fd, wait)
    print(output, end="" if output.endswith("\n") else "\n")

def snapshot(fd, label, wait=6):
    send(fd, f"""
echo SNAPSHOT_{label}
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_plan
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_state
cat /sys/bus/platform/devices/208040000.ans/akf_decode
cat /proc/partitions
""", wait)

fd = os.open(tty, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
try:
    os.write(fd, b"\n")
    time.sleep(0.6)
    print(read_for(fd, 3), end="")

    send(fd, """
echo ONE_SHOT_BEGIN
uname -a
cat /sys/bus/platform/devices/208040000.ans/state
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_transaction_plan
""", 5)
    snapshot(fd, "BASELINE", 8)

    for idx, plan in enumerate(plans, 1):
        send(fd, f"""
echo ONE_SHOT_TRANSACTION_{idx} {plan}
echo '{plan}' > /sys/bus/platform/devices/208040000.ans/oldrtbuddy_transaction
echo ONE_SHOT_TRANSACTION_STATUS_{idx} $?
""", 4)
        snapshot(fd, f"AFTER_TRANSACTION_{idx}", 8)
        send(fd, """
echo ONE_SHOT_DRAIN_WAIT
sleep 2
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_state
""", 5)

    for idx, (phase, reply, label) in enumerate(single_replies, 1):
        send(fd, f"""
echo ONE_SHOT_SINGLE_{idx} {phase} {reply} {label}
echo '{phase} {reply}' > /sys/bus/platform/devices/208040000.ans/oldrtbuddy_ordered_reply
echo ONE_SHOT_SINGLE_STATUS_{idx} $?
""", 4)
        snapshot(fd, f"AFTER_SINGLE_{idx}", 7)
        send(fd, """
echo ONE_SHOT_SINGLE_DRAIN_WAIT
sleep 1
cat /sys/bus/platform/devices/208040000.ans/oldrtbuddy_state
""", 4)

    send(fd, """
echo ONE_SHOT_FINAL
cat /proc/partitions
dmesg | tail -n 120
echo ONE_SHOT_END
""", 8)
finally:
    os.close(fd)
PY

echo "$OUT"
