use std::net::{Ipv4Addr, SocketAddrV4, UdpSocket};

use clap::Parser;

/// Number of 0xFF bytes preceding the MAC repeats in a magic packet.
const SYNC_STREAM_LEN: usize = 6;
/// A magic packet carries the MAC address repeated 16 times.
const MAC_REPEATS: usize = 16;
const MAGIC_PACKET_LEN: usize = SYNC_STREAM_LEN + MAC_REPEATS * 6;

/// Send a Wake-on-LAN magic packet.
#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    /// Target MAC address (`01:23:45:67:89:ab`, `01-23-45-67-89-ab` or `0123456789ab`).
    mac: String,

    /// Broadcast address to send to.
    #[arg(short, long, default_value = "255.255.255.255")]
    addr: Ipv4Addr,

    /// UDP destination port (Wake-on-LAN conventionally uses 9 or 7).
    #[arg(short, long, default_value_t = 9)]
    port: u16,

    /// Source address to bind before sending (useful on multi-homed hosts).
    #[arg(long)]
    bind: Option<Ipv4Addr>,
}

/// Parse a MAC address written with `:`, `-`, `.` separators or as 12 hex digits.
fn parse_mac(input: &str) -> Result<[u8; 6], String> {
    if !input
        .chars()
        .all(|c| c.is_ascii_hexdigit() || matches!(c, ':' | '-' | '.'))
    {
        return Err(format!("invalid MAC address: {input}"));
    }

    let hex: String = input.chars().filter(|c| c.is_ascii_hexdigit()).collect();
    if hex.len() != 12 {
        return Err(format!("invalid MAC address: {input}"));
    }

    let mut mac = [0u8; 6];
    for (i, byte) in mac.iter_mut().enumerate() {
        *byte = u8::from_str_radix(&hex[i * 2..i * 2 + 2], 16)
            .map_err(|_| format!("invalid MAC address: {input}"))?;
    }
    Ok(mac)
}

/// Build the 102-byte Wake-on-LAN magic packet.
fn magic_packet(mac: &[u8; 6]) -> [u8; MAGIC_PACKET_LEN] {
    let mut packet = [0u8; MAGIC_PACKET_LEN];
    packet[..SYNC_STREAM_LEN].fill(0xFF);
    for chunk in packet[SYNC_STREAM_LEN..].chunks_mut(6) {
        chunk.copy_from_slice(mac);
    }
    packet
}

fn run(cli: Cli) -> Result<(), String> {
    let mac = parse_mac(&cli.mac)?;
    let packet = magic_packet(&mac);

    let socket = UdpSocket::bind(match cli.bind {
        Some(bind) => SocketAddrV4::new(bind, 0),
        None => SocketAddrV4::new(Ipv4Addr::UNSPECIFIED, 0),
    })
    .map_err(|e| format!("cannot bind socket: {e}"))?;

    // Explicit broadcast enable; harmless where it is the default.
    if let Err(e) = socket.set_broadcast(true) {
        return Err(format!("cannot enable broadcast: {e}"));
    }

    let dest = SocketAddrV4::new(cli.addr, cli.port);
    socket
        .send_to(&packet, dest)
        .map_err(|e| format!("cannot send to {dest}: {e}"))?;

    let mac_str: Vec<String> = mac.iter().map(|b| format!("{b:02x}")).collect();
    println!(
        "sent magic packet to {dest} for {}",
        mac_str.join(":")
    );
    Ok(())
}

fn main() {
    if let Err(e) = run(Cli::parse()) {
        eprintln!("error: {e}");
        std::process::exit(1);
    }
}
