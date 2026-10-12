# wakeonlan

A Wake-on-LAN magic packet CLI written in Rust.

## Install with mise

```sh
mise use -g github:manhavn/wakeonlan
```

mise uses the `ubi` backend, which matches assets by target triple (`x86_64-unknown-linux-musl`, `aarch64-apple-darwin`, …). Make sure the release is tagged with the right version (e.g. `v0.1.0`) and that all archives plus `SHA256SUMS.txt` are uploaded to it.

See [README.vi.md](README.vi.md) for the Vietnamese version.

## Manual install

Download the archive matching your OS/arch from the release, extract it, and put the binary on your PATH:

```sh
tar -xzf wakeonlan-<version>-<target>.tar.gz   # Windows: extract the matching archive; the binary is wakeonlan.exe
```

## Usage

```sh
wakeonlan 01:23:45:67:89:ab                        # broadcast 255.255.255.255:9
wakeonlan 01-23-45-67-89-AB -a 192.168.1.255 -p 7  # subnet broadcast, port 7
wakeonlan 0123456789ab --bind 192.168.1.10         # multi-homed host
```

The MAC address accepts any of these formats: `01:23:45:67:89:ab`, `01-23-45-67-89-ab`, `01.23.45.67.89.ab`, `0123456789ab`.

## Cross-platform release build

Requires: `rustup`, `zig`, `cargo-zigbuild` (`cargo install cargo-zigbuild`).

```sh
./build-release.sh
```

Builds 6 targets from a single Linux machine; output lands in `dist/`:

| Target | Notes |
|---|---|
| `x86_64-unknown-linux-musl` | static, no glibc dependency |
| `aarch64-unknown-linux-musl` | static, no glibc dependency |
| `x86_64-apple-darwin` | macOS Intel |
| `aarch64-apple-darwin` | macOS Apple Silicon |
| `x86_64-pc-windows-gnu` | Windows x86_64 |
| `aarch64-pc-windows-gnullvm` | Windows ARM64 |

Each archive contains a single stripped binary, and `dist/SHA256SUMS.txt` is generated alongside.

## Releasing

1. Bump `version` in `Cargo.toml`, then run `./build-release.sh`.
2. Create the tag `v<version>` and push it.
3. Upload every file in `dist/` to that tag's GitHub release.
4. `mise use -g github:manhavn/wakeonlan` now installs the right binary for each OS/arch.
