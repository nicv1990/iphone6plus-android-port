#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AOSP_DIR="${1:-$ROOT/aosp-sandcastle}"
SANDCASTLE_DIR="$ROOT/projectsandcastle/android"
REPO="$ROOT/bin/repo"

cat <<EOF
This prepares a patched Project Sandcastle AOSP 10 tree.

Target directory: $AOSP_DIR

Heads up:
- AOSP sync is huge, usually 100+ GB.
- The build expects a case-sensitive filesystem.
- Building AOSP is much more reliable from Linux. On macOS, use a Linux VM
  or a case-sensitive APFS volume with the needed build tools.
EOF

mkdir -p "$ROOT/bin"

if [ ! -x "$REPO" ]; then
  echo "Downloading repo tool..."
  curl -L https://storage.googleapis.com/git-repo-downloads/repo -o "$REPO"
  chmod +x "$REPO"
fi

mkdir -p "$AOSP_DIR"
cd "$AOSP_DIR"

if [ ! -d .repo ]; then
  "$REPO" init -u https://android.googlesource.com/platform/manifest -b android-10.0.0_r3
fi

echo
echo "Next command will download Android source:"
echo "  cd '$AOSP_DIR' && '$REPO' sync -c -j8"
echo
echo "After sync finishes, run:"
echo "  cd '$AOSP_DIR'"
echo "  patch -p1 < '$SANDCASTLE_DIR/sandcastle-aosp.diff'"
echo "  cp '$SANDCASTLE_DIR/webview.apk' external/chromium-webview/prebuilt/arm64/"
echo "  tar -C packages/apps/openlauncher -xzf '$SANDCASTLE_DIR/openlauncher.tar.gz'"
echo "  tar -xzf '$SANDCASTLE_DIR/build-nand-1.1.tar.gz'"
echo "  '$SANDCASTLE_DIR/build.sh'"
