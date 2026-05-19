#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

M1N1="${M1N1:-$ROOT/artifacts/prebuilt/m1n1.bin}"
KERNEL="${KERNEL:-$ROOT/hoolock-linux/arch/arm64/boot/Image.gz}"
DTB_DIR="${DTB_DIR:-$ROOT/hoolock-linux/arch/arm64/boot/dts/apple}"
INITRAMFS="${INITRAMFS:-$ROOT/artifacts/prebuilt/initramfs.gz}"
OUT="${OUT:-$ROOT/artifacts/m1n1-linux.bin}"
BOOTARGS="${BOOTARGS:-earlycon console=tty0}"

for file in "$M1N1" "$KERNEL" "$INITRAMFS"; do
	if [ ! -f "$file" ]; then
		echo "Missing file: $file" >&2
		exit 1
	fi
done

if [ ! -d "$DTB_DIR" ]; then
	echo "Missing DTB directory: $DTB_DIR" >&2
	exit 1
fi

if ! ls "$DTB_DIR"/*.dtb >/dev/null 2>&1; then
	echo "No DTBs found in: $DTB_DIR" >&2
	exit 1
fi

mkdir -p "$(dirname -- "$OUT")"

{
	cat "$M1N1"
	printf 'chosen.bootargs=%s\n' "$BOOTARGS"
	cat "$DTB_DIR"/*.dtb
	cat "$KERNEL"
	cat "$INITRAMFS"
} > "$OUT"

echo "$OUT"
