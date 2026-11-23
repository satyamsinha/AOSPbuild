# AOSPbuild

Automated AOSP source sync and build using GitHub Actions and a dedicated
Ubuntu self-hosted runner.

The initial configuration builds the official AOSP Cuttlefish x86_64
userdebug target. It does not mirror Google's entire AOSP source tree into
this GitHub repository. The source is fetched from Google's official Repo
manifest during the workflow.

## Build defaults

- Manifest: https://android.googlesource.com/platform/manifest
- Branch: android-latest-release
- Lunch target: aosp_cf_x86_64_only_phone-aosp_current-userdebug
- Build goal: `m -j$(nproc) dist`
- Output: `out/dist` and `out/target/product/aosp_cf_x86_64_only_phone`

These defaults follow Google's current AOSP download and build instructions:
- https://source.android.com/docs/setup/download
- https://source.android.com/docs/setup/build/building

## 1. Provision a build host

Use a dedicated Ubuntu x86_64 VM or physical machine. AOSP builds need
substantial memory and disk space. Start with at least 64 GB RAM and
500 GB free SSD; 128 GB RAM and 1 TB NVMe are recommended.

The runner needs persistent storage mounted at `/data`. Do not use a
small ephemeral GitHub-hosted runner for a full AOSP build.

## 2. Install build dependencies

On the build host, clone this repository and run:

```bash
chmod +x scripts/setup-runner-ubuntu.sh
./scripts/setup-runner-ubuntu.sh
```

Then register the host as a self-hosted GitHub Actions runner:

1. Open this repository's **Settings → Actions → Runners**.
2. Select **New self-hosted runner** and choose Linux x64.
3. Follow GitHub's generated download/configuration commands.
4. Add the custom label `aosp` (keep the `self-hosted`, `linux`, and
   `x64` labels).
5. Install and start the runner as a service.

Runner documentation:
https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners

## 3. Run a build

Open **Actions → AOSP build → Run workflow**.

A push to `main` that changes scripts, patches, config, workflow, or README
also triggers the workflow. The first run initializes and downloads the
AOSP source; later runs reuse the persistent checkout and synchronize it.

## 4. Customize the branch or target

In **Settings → Secrets and variables → Actions → Variables**, optionally set:

- `AOSP_BRANCH`: defaults to `android-latest-release`
- `AOSP_LUNCH_TARGET`: defaults to
  `aosp_cf_x86_64_only_phone-aosp_current-userdebug`

The target must exist in the selected source branch.

## 5. Download build output

After a successful run, open the workflow run and download the
`aosp-cuttlefish-images-<run number>` artifact.

## Important notes

- This repository contains build automation, not the complete AOSP source.
- The first source sync and full compile can take many hours.
- A self-hosted runner must have enough RAM, free disk, CPU and network
  bandwidth. Keep the runner dedicated to trusted builds.
- The workflow is intentionally triggered only by pushes to `main` and
  manual dispatch. Do not run untrusted pull-request code on a privileged
  self-hosted runner.
- The workflow does not flash a physical device or launch Cuttlefish.
- Physical-device builds require the correct device configuration and
  any required proprietary vendor binaries. Their licenses and distribution
  terms must be respected.
- Do not store signing keys, credentials, or proprietary blobs in this
  public repository.
