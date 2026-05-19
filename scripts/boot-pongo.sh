#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

PALERA1N="$ROOT/bin/palera1n"
PONGO="$ROOT/bin/Pongo.bin"

if [ ! -x "$PALERA1N" ]; then
	echo "Missing executable: $PALERA1N" >&2
	exit 1
fi

if [ ! -f "$PONGO" ]; then
	echo "Missing Pongo.bin: $PONGO" >&2
	exit 1
fi

PALERA1N_BYPASS_PASSCODE_CHECK=1 "$PALERA1N" -lp -k "$PONGO"
