#!/usr/bin/env bash
set -Eeuo pipefail

: "${AOSP_WORKDIR:=/data/aosp}"
: "${AOSP_MANIFEST_URL:=https://android.googlesource.com/platform/manifest}"
: "${AOSP_BRANCH:=android-latest-release}"
: "${AOSP_LUNCH_TARGET:=aosp_cf_x86_64_only_phone-aosp_current-userdebug}"
: "${REPO_SYNC_JOBS:=8}"
: "${CCACHE_DIR:=/data/ccache}"
: "${CCACHE_MAXSIZE:=50G}"

BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$SCRIPT_DIR/.." && pwd)}"

if ! command -v repo >/dev/null 2>&1; then
  echo "ERROR: repo is not installed or not on PATH." >&2
  echo "Run scripts/setup-runner-ubuntu.sh on the self-hosted runner." >&2
  exit 1
fi

if ! command -v ccache >/dev/null 2>&1; then
  echo "ERROR: ccache is not installed." >&2
  exit 1
fi

if [[ "$AOSP_WORKDIR" != /* ]]; then
  echo "ERROR: AOSP_WORKDIR must be an absolute path." >&2
  exit 1
fi

mkdir -p "$AOSP_WORKDIR" "$CCACHE_DIR"
cd "$AOSP_WORKDIR"

echo "==> Initializing AOSP manifest: $AOSP_BRANCH"
repo init --partial-clone --no-use-superproject \
  -u "$AOSP_MANIFEST_URL" \
  -b "$AOSP_BRANCH"

# Replace repository-managed local manifest overlays on each run.
if [[ -d "$GITHUB_WORKSPACE/manifest" ]]; then
  mkdir -p .repo/local_manifests
  find .repo/local_manifests -maxdepth 1 -type f -name '*.xml' -delete
  if compgen -G "$GITHUB_WORKSPACE/manifest/*.xml" >/dev/null; then
    cp "$GITHUB_WORKSPACE"/manifest/*.xml .repo/local_manifests/
  fi
fi

echo "==> Synchronizing AOSP source"
repo sync -c -j"$REPO_SYNC_JOBS"

# Apply patches stored as patches/<AOSP project path>/*.patch.
# Already-applied patches are detected so repeat builds remain usable.
if [[ -d "$GITHUB_WORKSPACE/patches" ]]; then
  while IFS= read -r -d '' patch_file; do
    relative_path="${patch_file#"$GITHUB_WORKSPACE/patches/"}"
    if [[ "$relative_path" != */* ]]; then
      echo "ERROR: Put each patch under patches/<AOSP project path>/*.patch: $patch_file" >&2
      exit 1
    fi
    project_path="${relative_path%/*}"
    project_dir="$AOSP_WORKDIR/$project_path"

    if [[ ! -d "$project_dir/.git" ]]; then
      echo "ERROR: No synced Git project found for patch: $patch_file" >&2
      exit 1
    fi

    if git -C "$project_dir" apply --check "$patch_file"; then
      echo "==> Applying $patch_file to $project_path"
      git -C "$project_dir" apply "$patch_file"
    elif git -C "$project_dir" apply --reverse --check "$patch_file"; then
      echo "==> Patch already applied: $patch_file"
    else
      echo "ERROR: Patch does not apply cleanly: $patch_file" >&2
      exit 1
    fi
  done < <(find "$GITHUB_WORKSPACE/patches" -type f -name '*.patch' -print0 | sort -z)
fi

export USE_CCACHE=1
export CCACHE_DIR
export CCACHE_EXEC="$(command -v ccache)"
ccache -M "$CCACHE_MAXSIZE"
ccache -o compression=true

echo "==> Configuring build target: $AOSP_LUNCH_TARGET"
source build/envsetup.sh
lunch "$AOSP_LUNCH_TARGET"

echo "==> Building AOSP with $BUILD_JOBS jobs"
m -j"$BUILD_JOBS" dist

echo "==> Build completed"
echo "ccache statistics:"
ccache -s
echo "Distribution artifacts: $AOSP_WORKDIR/out/dist"
echo "Product output: $AOSP_WORKDIR/out/target/product"
