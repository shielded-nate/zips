#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/format.sh <subcommand>

Subcommands:
  help, --help      Show this help text.
  check             Check formatting divergence for all .md files without modifying files.
  rewrite           Rewrite formatting for all .md files in place.
  commit-rewrite    Require a clean repo, run rewrite, git add -A, and commit.
USAGE
}

if [[ "$#" -ne 1 ]]; then
  echo "Usage problem: expected exactly one subcommand argument." >&2
  usage
  exit 1
fi

subcommand="$1"

run_check() {
  dprint check
}

run_rewrite() {
  dprint fmt
}

case "$subcommand" in
  help|--help)
    usage
    ;;
  check)
    run_check
    ;;
  rewrite)
    run_rewrite
    ;;
  commit-rewrite)
    if [[ -n "$(git status --porcelain)" ]]; then
      echo "Repository must be clean before commit-rewrite." >&2
      exit 1
    fi
    run_rewrite
    git add -A
    git commit -m "format.sh auto-format commit"
    ;;
  *)
    echo "Usage problem: unknown subcommand '$subcommand'." >&2
    usage
    exit 1
    ;;
esac
