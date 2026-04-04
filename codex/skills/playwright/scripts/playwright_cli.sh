#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v python3 >/dev/null 2>&1; then
    exec python3 "${script_dir}/playwright_cli.py" "$@"
fi

if ! command -v npx >/dev/null 2>&1; then
    echo "Error: npx is required but not found on PATH." >&2
    exit 1
fi

echo "Warning: python3 is unavailable; using the basic npx wrapper. Session-aware fallback features, especially close cleanup, are disabled, so re-check session/process state after running close." >&2

has_session_flag="false"
for arg in "$@"; do
    case "$arg" in
    --session | --session=*)
        has_session_flag="true"
        break
        ;;
    esac
done

cmd=(npx --yes --package @playwright/cli playwright-cli)
if [[ "${has_session_flag}" != "true" && -n "${PLAYWRIGHT_CLI_SESSION:-}" ]]; then
    cmd+=(--session "${PLAYWRIGHT_CLI_SESSION}")
fi
cmd+=("$@")

exec "${cmd[@]}"
