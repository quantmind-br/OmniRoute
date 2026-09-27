# `patches/nightly/` — fork-owned nightly build fixes

This fork never opens upstream PRs, so build breaks inherited from the
upstream HEAD (`diegosouzapw/OmniRoute`) are fixed HERE and applied by the
`Apply fork nightly patches` step in `nightly-image.yml`, right after the
upstream checkout and before `docker build`.

## What goes here

| File pattern          | How it is applied                                          | On mismatch |
| --------------------- | ---------------------------------------------------------- | ----------- |
| `NN-short-name.patch` | `git apply --whitespace=fix` (strict)                      | Skipped with a `::warning::` annotation; the build then proves whether the fix is still needed. Refresh or delete the patch. |
| `NN-short-name.sh`    | `bash` (must be idempotent, `set -euo pipefail`)           | Fatal — a fixup is fork-owned code, so a failure fails the run loudly instead of hiding that the fix is inactive. |
| `*.example`           | Ignored (documentation only)                               | — |

Number prefixes define application order (`NN` ascending, patches before
fixups). Keep every entry small, single-purpose, with a header comment naming
the upstream failure class (run id + date) it addresses.

## Testing a change before fast-forwarding `ops/nightly-image`

Push this branch and run on it — the workflow checks out patches from
`${{ github.ref }}`, so a feature branch tests its own patches:

```bash
git push fork ops/nightly-patches
gh workflow run nightly-image.yml --repo quantmind-br/OmniRoute --ref ops/nightly-patches
gh run watch <id> --repo quantmind-br/OmniRoute
```

Local dry-run of the apply loop against any upstream tree:

```bash
git apply --check --whitespace=fix patches/nightly/NN-name.patch
bash -n patches/nightly/NN-name.sh
```

## Failure classes already seen (Sept/2026)

- `Can't resolve 'child_process'/'fs'/'module'` via `sharp → cursorImages.ts → … → combos/page.tsx`
  (12, 13, 14, 19, 20, 21/09): client component importing a server-only chain.
  Covered at build time by the webpack + Turbopack-fallback passes; if BOTH
  fail again, add a targeted static `*.patch` here.
- `[MDX] invalid frontmatter in docs/…` (03/09): covered by
  `10-mdx-frontmatter-guard.sh`.
- `502 Bad Gateway` from the buildx toolkit download (10/09): covered by the
  buildx retry step in the workflow.
- arm64 heap OOM (16/09): covered by `OMNIROUTE_BUILD_MEMORY_MB=8192` + swap.
- `Cannot read private member #state` on every `/v1/chat/completions`,
  `/v1/messages` and `/v1/responses` request (27/09, run 36313753532, upstream
  `a58000c7685f`): `withDeadlineSignal` rebuilt the route's NextRequest with
  `new Request(request, …)` on Node 26. Covered by
  `20-deadline-signal-request-rebuild.patch`.
