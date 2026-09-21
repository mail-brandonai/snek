#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
asset_dir="$repo_root/web"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

release_url="https://github.com/simolus3/drift/releases/download/drift-2.35.0"

curl --fail --location --silent --show-error \
  "$release_url/sqlite3.wasm" \
  --output "$tmp_dir/sqlite3.wasm"
curl --fail --location --silent --show-error \
  "$release_url/drift_worker.js" \
  --output "$tmp_dir/drift_worker.js"

if command -v sha256sum >/dev/null 2>&1; then
  printf '%s  %s\n' \
    13d3f11d05b39ba0618a7115fb41640a5d48b6300f5d3f325f554b42bd6688a4 \
    sqlite3.wasm \
    df0066e75363a9bed59a14eedbbded421c1f5910f8379812df164716aa2e6eed \
    drift_worker.js | (cd "$tmp_dir" && sha256sum --check)
else
  printf '%s  %s\n' \
    13d3f11d05b39ba0618a7115fb41640a5d48b6300f5d3f325f554b42bd6688a4 \
    sqlite3.wasm \
    df0066e75363a9bed59a14eedbbded421c1f5910f8379812df164716aa2e6eed \
    drift_worker.js | (cd "$tmp_dir" && shasum -a 256 --check)
fi

mkdir -p "$asset_dir"
mv "$tmp_dir/sqlite3.wasm" "$asset_dir/sqlite3.wasm"
mv "$tmp_dir/drift_worker.js" "$asset_dir/drift_worker.js"

printf 'Prepared Drift web assets in %s\n' "$asset_dir"
