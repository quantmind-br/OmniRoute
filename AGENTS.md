# AGENTS.md — OmniRoute fork (quantmind-br/OmniRoute)

> **Fork context (TL;DR).** This repository is a DEPLOYMENT fork of
> `diegosouzapw/OmniRoute`. Its only purpose is to build and publish the Docker
> nightly image used to update the operator's own remote OmniRoute instances.
> It is NOT a contribution channel: **never open PRs against the upstream.**

## Hard rules (fork-specific)

1. **No upstream PRs — ever.** Do not open, and immediately close any
   mistakenly-opened, pull request against `diegosouzapw/OmniRoute`. Upstream
   contributions are out of scope for this repo.
2. **The main branch is `ops/nightly-image`.** It holds a single file,
   `.github/workflows/nightly-image.yml`. Do not treat `main` or `release/*` as
   the operative branch of this fork.
3. **Delivery is a direct push** to `fork/ops/nightly-image` (remote `fork` →
   `quantmind-br/OmniRoute`). No PRs, no merge queues, no upstream syncs.
4. **Do not merge/sync upstream history** into fork branches unless the
   operator explicitly asks. Fork branches can be far behind upstream on
   purpose (e.g. `release/v3.8.51` was ~364 commits behind).
5. The app source code is NOT maintained on this fork. `nightly-image.yml`
   checks out the upstream default branch HEAD at build time; only the workflow
   file is owned here.

## How the nightly image is produced

- Trigger: schedule `50 5 * * *` UTC (02:50 BRT — ready before the 04:00 BRT
  deploys) or `workflow_dispatch`.
- Checks out the **upstream default branch HEAD** (`diegosouzapw/OmniRoute`).
- Builds `runner-base` on native `linux/amd64` (`ubuntu-latest`) and
  `linux/arm64` (`ubuntu-24.04-arm`), then merges the multi-arch manifest:
  `ghcr.io/quantmind-br/omniroute:nightly` (+ `:r<sha>`).
- **Bundler: webpack — always.** The build step passes
  `OMNIROUTE_USE_TURBOPACK=0` + `OMNIROUTE_BUILD_MEMORY_MB=6144` as build-args
  because the upstream Dockerfile defaults to Turbopack, whose native Rust
  compile is NOT bounded by `--max-old-space-size` (#6409) and OOMs the hosted
  runners with `cannot allocate memory`. Keep the 12 GB swapfile step. Do not
  remove these build-args.
- Variants that OOM upstream CI (`-bun`, `-web`, `-web-bun`) are intentionally
  not built here.

## State of the fork (2026-08-28)

- `ops/nightly-image` — main branch: `nightly-image.yml` with the webpack fix
  (+ this file).
- `release/v3.8.51` — carries the upstream workflow OOM fixes (build.yml /
  quality.yml heap 12288 → 8192, Dockerfile default webpack), cherry-picked for
  reference. Instances consume the nightly image, not this branch.
- Upstream remains untouched (no PRs, no pushes).

## Git setup

- `origin` → `https://github.com/diegosouzapw/OmniRoute` (upstream; push denied)
- `fork` → `https://github.com/quantmind-br/OmniRoute` (this repo; push target)
- Authenticated GitHub account: `quantmind-br`

## Workflow change checklist

1. Edit `.github/workflows/nightly-image.yml` on a branch off `ops/nightly-image`.
2. Validate: `npx prettier --check` the YAML and parse it with `yaml`.
3. Push the branch and fast-forward `fork/ops/nightly-image` (direct push).
4. Smoke-test: `gh workflow run nightly-image.yml --repo quantmind-br/OmniRoute
--ref ops/nightly-image`, then watch the run to completion
   (`gh run view <id>` / `gh run watch`).
5. Clean up temporary worktrees/branches; never touch other sessions' work.
