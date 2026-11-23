#!/usr/bin/env bash
set -Eeuo pipefail

# Run this script manually on a dedicated Ubuntu x86_64 build host.
# Provision at least 64 GB RAM and 500 GB free SSD; 128 GB RAM and
# 1 TB NVMe are preferable for a smoother full AOSP build.

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "This initial runner setup targets Ubuntu x86_64." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y \
  git git-lfs gnupg flex bison build-essential zip curl \
  zlib1g-dev libc6-dev-i386 libncurses-dev libx11-dev \
  lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc \
  unzip fontconfig python3 python-is-python3 rsync \
  ccache libssl-dev libelf-dev

mkdir -p "$HOME/bin" /data/aosp /data/ccache
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo \
  -o "$HOME/bin/repo"
chmod 0755 "$HOME/bin/repo"

if ! grep -q 'HOME/bin' "$HOME/.profile" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.profile"
fi

echo
echo "Setup complete. Log out/in or run:"
echo '  export PATH="$HOME/bin:$PATH"'
echo '  ccache -M 50G'
echo
echo "Next: register this machine as a GitHub self-hosted runner"
echo "with labels including: linux, x64, aosp."
