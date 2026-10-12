#!/usr/bin/env bash
# Build release archives for every supported OS/arch combo from one host.
# Requires: rustup, cargo-zigbuild, zig.
#
# Linux ships musl static binaries (no glibc dependency, runs anywhere).
# macOS/Windows cross-link via zig.
set -euo pipefail
cd "$(dirname "$0")"

version="$(sed -n 's/^version = "\(.*\)"/\1/p' Cargo.toml | head -1)"
name="wakeonlan"

TARGETS=(
  x86_64-unknown-linux-musl
  aarch64-unknown-linux-musl
  x86_64-apple-darwin
  aarch64-apple-darwin
  x86_64-pc-windows-gnu
  aarch64-pc-windows-gnullvm
)

for tool in rustup cargo-zigbuild zig sha256sum; do
  command -v "$tool" >/dev/null || { echo "error: missing $tool" >&2; exit 1; }
done

rm -rf dist
mkdir -p dist

for target in "${TARGETS[@]}"; do
  echo "==> $name $version for $target"
  cargo zigbuild --release --locked --target "$target"

  bin="$name"
  [[ "$target" == *windows* ]] && bin="$name.exe"

  archive="$name-$version-$target.tar.gz"
  stage="dist/$name-$version-$target"
  mkdir -p "$stage"
  cp "target/$target/release/$bin" "$stage/"
  tar -C dist -czf "dist/$archive" "$name-$version-$target"
  rm -rf "$stage"
done

(cd dist && sha256sum ./*.tar.gz > SHA256SUMS.txt)
echo
echo "Archives ready in dist/:"
ls -lh dist/
