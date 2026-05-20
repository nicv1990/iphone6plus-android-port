#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
IMAGE="${1:-/tmp/m1n1-linux-t7000-n56-oldrtb-transaction.bin}"
TTY=""

if [ ! -f "$IMAGE" ]; then
	echo "Missing image: $IMAGE" >&2
	exit 1
fi

pkill -f 'palera1n|checkra1n|pongoterm|irecovery|send-m1n1' 2>/dev/null || true

echo "Booting Pongo and sending $IMAGE"
set +e
"$ROOT/scripts/boot-pongo.sh" && sleep 2 && "$ROOT/scripts/send-m1n1-linux.sh" "$IMAGE"
BOOT_RET=$?
set -e
echo "boot/send exit status: $BOOT_RET"

echo "Waiting for Linux USB serial..."
for _ in $(seq 1 45); do
	for dev in /dev/cu.usbmodem*; do
		if [ -c "$dev" ]; then
			TTY="$dev"
			break 2
		fi
	done
	sleep 1
done

if [ -z "$TTY" ]; then
	echo "No Linux serial device appeared" >&2
	exit 1
fi

echo "Running one-shot suite on $TTY"
"$ROOT/scripts/test-oldrtbuddy-one-shot.sh" "$TTY"
