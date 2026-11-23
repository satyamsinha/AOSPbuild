#!/usr/bin/env bash
set -Eeuo pipefail

# Run as the same non-root user that will run the GitHub Actions runner.
# Recommended host: Ubuntu x86_64, 64+ GB RAM, 500 GB+ free SSD.

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "This runner setup targets Ubuntu x86_64." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y \
  git git-lfs gnupg flex bison build-essential zip curl \
  zlib1g-dev libc6-dev-i386 libncurses-dev libx11-dev \
  lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc \
  unzip fontconfig python3 python-is-python3 rsync \
  ccache libssl-dev libelf-dev

# Install Repo and verify Google's published signature.
tmp_repo="$(mktemp)"
trap 'rm -f "$tmp_repo" "$tmp_repo.asc"' EXIT
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$tmp_repo"
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo.asc -o "$tmp_repo.asc"
gpg --keyserver hkps://keyserver.ubuntu.com \
  --recv-keys 8BB9AD793E8E6153AF0F9A4416530D5E920F5C65
gpg --verify "$tmp_repo.asc" "$tmp_repo"
sudo install -m 0755 "$tmp_repo" /usr/local/bin/repo

# Create persistent work/cache directories accessible to this runner user.
sudo mkdir -p /data/aosp /data/ccache
sudo chown -R "$USER":"$(id -gn)" /data/aosp /data/ccache

ccache -M 50G

echo
echo "Setup complete."
repo version
echo "AOSP workspace: /data/aosp"
echo "ccache directory: /data/ccache"
echo
echo "Next: register this machine as a GitHub self-hosted runner"
echo "with labels including: linux, x64, aosp."
