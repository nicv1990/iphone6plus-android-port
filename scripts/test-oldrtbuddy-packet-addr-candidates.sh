#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
	echo "usage: $0 /dev/cu.usbmodemXYZ" >&2
	exit 2
fi

TTY="$1"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/artifacts/oldrtbuddy-packet-addr-candidates-$(date +%Y-%m-%d-%H%M%S).txt"

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
echo PACKET_ADDR_CANDIDATES_BEGIN
uname -a
BASE=/sys/bus/platform/devices/208040000.ans
cat $BASE/state
cat $BASE/oldrtbuddy_state
cat $BASE/oldrtbuddy_packet_model
cat $BASE/oldrtbuddy_packet_addr_plan

for test in \\
  "old-small addr64" \\
  "old-0x40 addr64" \\
  "old-0x40 addr-shift4" \\
  "old-0x40 addr-shift12" \\
  "old-0x40 addr-len" \\
  "old-0x40 len-addr"
do
  echo PACKET_ADDR_TEST $test
  echo "$test" > $BASE/oldrtbuddy_packet_addr_send
  echo PACKET_ADDR_STATUS $?
  cat $BASE/oldrtbuddy_packet_addr_plan
  cat $BASE/oldrtbuddy_state
  cat /proc/partitions
  sleep 1
done

echo PACKET_ADDR_FINAL_DECODE
cat $BASE/akf_decode
dmesg | tail -80
echo PACKET_ADDR_CANDIDATES_END
"""

fd = os.open(tty, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
try:
    os.write(fd, b"\n")
    time.sleep(0.5)
    print(read_for(fd, 3), end="")
    os.write(fd, commands)
    print(read_for(fd, 35), end="")
finally:
    os.close(fd)
PY

echo "$OUT"
