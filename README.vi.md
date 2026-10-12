# wakeonlan

CLI gửi Wake-on-LAN magic packet, viết bằng Rust.

Xem [README.md](README.md) cho phiên bản tiếng Anh.

## Cài qua mise

```sh
mise use gh:<owner>/wakeonlan
```

mise dùng backend `ubi` tự nhận diện asset theo triple (`x86_64-unknown-linux-musl`, `aarch64-apple-darwin`, …). Đảm bảo release đã được tag đúng version (ví dụ `v0.1.0`) và upload toàn bộ archive + `SHA256SUMS.txt` vào release đó.

## Cài thủ công

Tải archive khớp OS/arch từ release, giải nén, đặt binary vào PATH:

```sh
tar -xzf wakeonlan-<version>-<target>.tar.gz   # Windows: giải nén .tar.gz tương ứng, binary là wakeonlan.exe
```

## Dùng

```sh
wakeonlan 01:23:45:67:89:ab                        # broadcast 255.255.255.255:9
wakeonlan 01-23-45-67-89-AB -a 192.168.1.255 -p 7  # broadcast cụm mạng, cổng 7
wakeonlan 0123456789ab --bind 192.168.1.10         # máy nhiều interface
```

MAC nhận mọi format: `01:23:45:67:89:ab`, `01-23-45-67-89-ab`, `01.23.45.67.89.ab`, `0123456789ab`.

## Build release đa nền tảng

Yêu cầu: `rustup`, `zig`, `cargo-zigbuild` (`cargo install cargo-zigbuild`).

```sh
./build-release.sh
```

Script build 6 target từ một máy Linux, kết quả trong `dist/`:

| Target | Ghi chú |
|---|---|
| `x86_64-unknown-linux-musl` | static, không phụ thuộc glibc |
| `aarch64-unknown-linux-musl` | static, không phụ thuộc glibc |
| `x86_64-apple-darwin` | macOS Intel |
| `aarch64-apple-darwin` | macOS Apple Silicon |
| `x86_64-pc-windows-gnu` | Windows x86_64 |
| `aarch64-pc-windows-gnullvm` | Windows ARM64 |

Mỗi archive chứa một binary đã strip, kèm `dist/SHA256SUMS.txt`.

## Phát hành

1. Đổi `version` trong `Cargo.toml` rồi chạy `./build-release.sh`.
2. Tạo tag `v<version>` và push.
3. Upload toàn bộ file trong `dist/` vào GitHub release của tag đó.
4. `mise use gh:<owner>/wakeonlan` giờ cài được theo OS/arch.
