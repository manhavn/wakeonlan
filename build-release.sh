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

# rustc appends -Wl,-O1 for release musl builds and probes for a macOS SDK
# when cross-linking darwin; both make lld/xcrun print deprecation noise
# that rustc surfaces as `linker_messages` warnings. Harmless for these
# zig-linked cross builds, so allow the lint here.
export RUSTFLAGS="${RUSTFLAGS:-} -A linker_messages"

# rustc probes for a macOS SDK via xcrun when cross-linking darwin targets
# from a non-macOS host; without Xcode that probe fails and rustc emits a
# warning that is not lint-controlled. zig bundles its own SDK stubs, so the
# link is fine without one. Filter exactly that warning (and its summary
# line) while keeping exit status and all other output intact.
build_target() {
  local log status=0
  log="$(mktemp)"
  cargo zigbuild --release --locked --target "$1" >"$log" 2>&1 || status=$?
  grep -vE \
    -e '^warning: invoking `"xcrun" "--sdk" "macosx" "--show-sdk-path"` to find MacOSX\.sdk failed' \
    -e '^  = note: the SDK is needed by the linker' \
    -e '^  = help: pass the path of an Xcode installation' \
    -e '^warning: `wakeonlan` \(bin "wakeonlan"\) generated [0-9]+ warnings?$' \
    "$log" >&2 || true
  rm -f "$log"
  return "$status"
}

rm -rf dist
mkdir -p dist

for target in "${TARGETS[@]}"; do
  echo "==> $name $version for $target"
  build_target "$target"

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
