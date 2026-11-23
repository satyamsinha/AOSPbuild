# AOSPbuild

Automated AOSP source sync and build using GitHub Actions and a dedicated
Ubuntu x86_64 self-hosted runner.

The initial configuration builds the official AOSP Cuttlefish x86_64
userdebug target. This repository contains build automation and your
customizations; it does not mirror Google's entire AOSP source tree.
Source projects are fetched from Google's official Repo manifest.

## Build defaults

- Manifest: https://android.googlesource.com/platform/manifest
- Branch: `android-latest-release`
- Lunch target: `aosp_cf_x86_64_only_phone-aosp_current-userdebug`
- Build goal: `m -j<jobs> dist`
- Persistent source: `/data/aosp`
- Persistent ccache: `/data/ccache`
- Output: `/data/aosp/out/dist` and the Cuttlefish product output

These defaults follow Google's current AOSP instructions:
- https://source.android.com/docs/setup/download
- https://source.android.com/docs/setup/build/building

## 1. Provision a build host

Use a dedicated Ubuntu x86_64 VM or physical machine. Start with at least
64 GB RAM and 500 GB free SSD; 128 GB RAM and 1 TB NVMe are preferable.
Mount persistent storage at `/data`.

Do not use a small ephemeral GitHub-hosted runner for a full AOSP build.

## 2. Install build dependencies

Clone this repository on the build host and run as the same non-root user
that will run the GitHub Actions runner:

```bash
git clone git@github.com:satyamsinha/AOSPbuild.git
cd AOSPbuild
chmod +x scripts/setup-runner-ubuntu.sh
./scripts/setup-runner-ubuntu.sh
```

The setup script installs the build packages, verifies Google's Repo
launcher signature, installs Repo, and creates persistent workspace/cache
directories.

## 3. Register the self-hosted runner

In this repository:

1. Open **Settings → Actions → Runners**.
2. Select **New self-hosted runner** and choose Linux x64.
3. Follow GitHub's generated download and configuration commands.
4. Add the custom label `aosp` (keep `self-hosted`, `linux`, and `x64`).
5. Install and start the runner as a service.

Runner documentation:
https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners

The runner service user must have read/write access to `/data/aosp` and
`/data/ccache`.

## 4. Run a build

Open **Actions → AOSP build → Run workflow**.

A push to `main` that changes scripts, patches, manifest overlays,
workflow files, or README also triggers the build. The first run downloads
the AOSP source and performs a full compile; later runs reuse the source
checkout and ccache.

## 5. Customize the build

In **Settings → Secrets and variables → Actions → Variables**, optionally set:

- `AOSP_BRANCH`: defaults to `android-latest-release`
- `AOSP_LUNCH_TARGET`: defaults to
  `aosp_cf_x86_64_only_phone-aosp_current-userdebug`
- `BUILD_JOBS`: parallel build jobs; leave unset to use `nproc`
- `CCACHE_MAXSIZE`: defaults to `50G`

The lunch target must exist in the selected source branch.

### Local manifest overlays

Put Repo local manifest XML files directly in `manifest/`. They are copied
to `.repo/local_manifests/` before source synchronization.

### Custom patches

Put patches under the matching AOSP project path. For example:

```text
patches/
└── frameworks/
    └── base/
        └── 0001-example-change.patch
```

The build script applies patches in sorted filename order. It recognizes
patches that are already applied on a previous run. A patch that no longer
applies cleanly fails the build.

## 6. Download build output

After a successful run, open the workflow run and download the
`aosp-cuttlefish-images-<run number>` artifact.

## Important notes

- The first source sync and full compile can take many hours.
- The workflow runs only on a self-hosted runner labelled `aosp`.
- The runner should be dedicated to trusted builds. Do not execute
  untrusted pull-request code on a privileged self-hosted runner.
- The workflow produces build artifacts; it does not flash a physical device
  or launch Cuttlefish.
- Physical-device builds require the correct device configuration and any
  required proprietary vendor binaries. Respect their licensing and
  distribution terms.
- Do not commit signing keys, credentials, or proprietary blobs to this
  public repository.
