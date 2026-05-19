#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
	echo "usage: $0 /path/to/m1n1-linux.bin" >&2
	exit 2
fi

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PONGOTERM="$ROOT/bin/pongoterm"
IMAGE="$1"

if [ ! -x "$PONGOTERM" ]; then
	echo "Missing executable: $PONGOTERM" >&2
	exit 1
fi

if [ ! -f "$IMAGE" ]; then
	echo "Missing image: $IMAGE" >&2
	exit 1
fi

printf '/send %s\nbootm\n' "$IMAGE" | "$PONGOTERM"
