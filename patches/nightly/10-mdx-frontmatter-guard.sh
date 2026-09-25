#!/usr/bin/env bash
# Fork nightly fixup: quarantine docs with unclosed frontmatter.
#
# Upstream failure class (run 33742607889, 2026-09-03):
#   Error: [MDX] invalid frontmatter in /app/docs/reference/REMOVED_PROVIDERS.md
# Fumadocs validates every docs/**/*.md during `npm run build`; a single file
# with an opening `---` and no closing `---` red-fails the whole Docker image.
# This fork cannot fix upstream docs, so such files are moved out of the build
# context before `docker build`.
#
# Conservative on purpose: only files whose FIRST line is exactly `---` and
# that have no closing `---` within the next 39 lines are quarantined.
# Everything else is untouched. Idempotent: re-runs find nothing to do.
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

quarantine="/tmp/nightly-mdx-quarantine"
moved=0

shopt -s nullglob globstar
for f in docs/**/*.md; do
  [ -f "$f" ] || continue
  [ "$(head -n 1 "$f")" = "---" ] || continue
  if head -n 40 "$f" | tail -n +2 | grep -qxE -- "---[[:space:]]*"; then
    continue
  fi
  mkdir -p "$quarantine/$(dirname "$f")"
  mv "$f" "$quarantine/$f"
  echo "::warning title=mdx quarantined::$f has unclosed frontmatter; moved out of the Docker build context."
  moved=$((moved + 1))
done

echo "MDX frontmatter guard: $moved file(s) quarantined."
