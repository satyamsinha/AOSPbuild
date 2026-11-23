#!/usr/bin/env bash
set -Eeuo pipefail

: "${AOSP_WORKDIR:=/data/aosp}"
: "${AOSP_MANIFEST_URL:=https://android.googlesource.com/platform/manifest}"
: "${AOSP_BRANCH:=android-latest-release}"
: "${AOSP_LUNCH_TARGET:=aosp_cf_x86_64_only_phone-aosp_current-userdebug}"
: "${REPO_SYNC_JOBS:=8}"

BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"

if ! command -v repo >/dev/null 2>&1; then
  echo "ERROR: repo is not installed or not on PATH." >&2
  echo "Run scripts/setup-runner-ubuntu.sh on the self-hosted runner." >&2
  exit 1
fi

if [[ "$AOSP_WORKDIR" != /* ]]; then
  echo "ERROR: AOSP_WORKDIR must be an absolute path." >&2
  exit 1
fi

mkdir -p "$AOSP_WORKDIR"
cd "$AOSP_WORKDIR"

echo "==> Initializing AOSP manifest: $AOSP_BRANCH"
repo init --partial-clone --no-use-superproject \
  -u "$AOSP_MANIFEST_URL" \
  -b "$AOSP_BRANCH"

echo "==> Synchronizing AOSP source"
repo sync -c -j"$REPO_SYNC_JOBS"

echo "==> Configuring build target: $AOSP_LUNCH_TARGET"
# envsetup.sh and lunch must run in the same shell.
source build/envsetup.sh
lunch "$AOSP_LUNCH_TARGET"

echo "==> Building AOSP with $BUILD_JOBS jobs"
m -j"$BUILD_JOBS" dist

echo "==> Build completed"
echo "Distribution artifacts: $AOSP_WORKDIR/out/dist"
echo "Product output: $AOSP_WORKDIR/out/target/product"
