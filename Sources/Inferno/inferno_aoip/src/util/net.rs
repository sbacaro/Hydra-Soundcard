use log::{error, info};

use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use tokio::{net::UdpSocket, select, sync::broadcast::Receiver};

pub const MTU: usize = 1500;
const PACKET_BUFFER_SIZE: usize = MTU;
pub const MAX_PAYLOAD_BYTES: usize = 1400; // ???

pub struct ReceiveBuffer {
  buff: [u8; PACKET_BUFFER_SIZE],
}

impl ReceiveBuffer {
  pub fn new() -> Self {
    Self { buff: [0u8; PACKET_BUFFER_SIZE] }
  }
}

pub struct UdpSocketWrapper {
  socket: Option<UdpSocket>,
  #[allow(dead_code)]
  listen_addr: Ipv4Addr,
  listen_port: u16,
  shutdown: Receiver<()>,
  dowork: bool,
  #[allow(dead_code)]
  recv_buff: [u8; PACKET_BUFFER_SIZE],
}

impl UdpSocketWrapper {
  pub async fn new(
    listen_addr: Option<Ipv4Addr>,
    listen_port: u16,
    shutdown: Receiver<()>,
  ) -> UdpSocketWrapper {
    let listen_addr = listen_addr.unwrap_or(Ipv4Addr::new(0, 0, 0, 0));
    let sock = socket2::Socket::new(socket2::Domain::IPV4, socket2::Type::DGRAM, None)
      .expect("failed to create socket");
    
    sock.set_reuse_address(true).ok();
    #[cfg(unix)]
    {
      use std::os::unix::io::AsRawFd;
      let fd = sock.as_raw_fd();
      let optval: libc::c_int = 1;
      unsafe {
        let _ = libc::setsockopt(
          fd,
          libc::SOL_SOCKET,
          libc::SO_REUSEPORT,
          &optval as *const _ as *const libc::c_void,
          std::mem::size_of::<libc::c_int>() as libc::socklen_t,
        );
      }
    }
    
    if listen_addr != Ipv4Addr::new(0, 0, 0, 0) {
      if let Err(e) = sock.set_multicast_if_v4(&listen_addr) {
        error!("error setting multicast interface: {:?}", e);
      }
    }
    
    let addr = SocketAddr::new(IpAddr::V4(listen_addr), listen_port);
    if let Err(e) = sock.bind(&addr.into()) {
      error!(
        "Failed to bind socket to {}:{}, falling back to ephemeral port: {:?}",
        listen_addr, listen_port, e
      );
      let fallback_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(0, 0, 0, 0)), 0);
      sock.bind(&fallback_addr.into()).expect("failed to bind fallback socket");
    }
    
    let std_socket: std::net::UdpSocket = sock.into();
    std_socket.set_nonblocking(true).expect("failed to set non-blocking");
    let socket = UdpSocket::from_std(std_socket).expect("error converting std socket to tokio");
    // TODO MAY PANIC: this error should be non-fatal because some apps may use Inferno as an optional audio I/O
    let listen_port = socket.local_addr().unwrap().port();
    UdpSocketWrapper {
      listen_addr,
      socket: Some(socket),
      listen_port,
      shutdown,
      dowork: true,
      recv_buff: [0; PACKET_BUFFER_SIZE],
    }
  }

  pub fn should_work(&self) -> bool {
    self.dowork
  }

  pub fn port(&self) -> u16 {
    self.listen_port
  }

  pub async fn recv<'a>(&mut self, recv_buff: &'a mut ReceiveBuffer) -> Option<(SocketAddr, &'a [u8])> {
    let socket = match &self.socket {
      Some(s) => s,
      None => {
        return None;
      }
    };
    select! {
      r = socket.recv_from(&mut recv_buff.buff) => {
        match r {
          Ok((len_recv, src)) => {
            return Some((src, &recv_buff.buff[..len_recv]));
          },
          Err(e) => {
            error!("error receiving from socket: {e:?}");
            return None;
          }
        }
      },
      _ = self.shutdown.recv() => {
        self.dowork = false;
        return None;
      }
    };
  }

  pub async fn send(&self, dst: &SocketAddr, packet: &[u8]) {
    let socket = match &self.socket {
      Some(s) => s,
      None => {
        info!("shutting down, discarding message to send");
        return;
      }
    };
    if let Err(e) = socket.send_to(packet, dst).await {
      error!("send error (ignoring): {e:?}");
    }
  }
}

pub async fn create_tokio_udp_socket(self_ip: Ipv4Addr) -> tokio::io::Result<(UdpSocket, u16)> {
  let socket = UdpSocket::bind(SocketAddr::new(IpAddr::V4(self_ip), 0)).await?;
  let port = socket.local_addr()?.port();
  return Ok((socket, port));
}

pub fn create_mio_udp_socket(self_ip: Ipv4Addr) -> std::io::Result<(mio::net::UdpSocket, u16)> {
  let socket = mio::net::UdpSocket::bind(SocketAddr::new(IpAddr::V4(self_ip), 0))?;
  let port = socket.local_addr()?.port();
  return Ok((socket, port));
}
