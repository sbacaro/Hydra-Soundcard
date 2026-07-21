use std::collections::BTreeMap;
use std::sync::atomic::{AtomicI32, AtomicUsize, Ordering};
use std::sync::{Arc, Mutex, RwLock};
use std::time::Duration;
use clap::Parser;
use log::{error, info};
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};

use inferno_aoip::device_server::{
    DeviceServer, ExternalBufferParameters, Settings, AtomicSample, Sample,
};

#[derive(Parser, Debug)]
#[command(author, version, about = "Hydra Inferno Bridge", long_about = None)]
struct Args {
    #[arg(long, short)]
    bridge_name: String,

    /// IPv4 address or network interface name (e.g. "192.168.1.10" or "en0")
    #[arg(long)]
    bind_ip: String,

    #[arg(long, short)]
    latency_ms: u64,

    #[arg(long, short)]
    channels: usize,
}

#[tokio::main]
async fn main() {
    let logenv = env_logger::Env::default().default_filter_or("info");
    env_logger::init_from_env(logenv);

    let args = Args::parse();
    info!("Starting Hydra Inferno Bridge with settings: {:?}", args);

    // ── Parent-death watchdog (POSIX only) ──────────────────────────────────
    #[cfg(unix)]
    {
        std::thread::spawn(|| {
            loop {
                std::thread::sleep(Duration::from_secs(1));
                if unsafe { libc::getppid() } == 1 {
                    info!("Parent process died (adopted by launchd). Exiting...");
                    std::process::exit(0);
                }
            }
        });
    }

    // ── 1. Locate CoreAudio bridge device (retry up to 30 s) ───────────────
    let host = cpal::host_from_id(cpal::HostId::CoreAudio).expect("CoreAudio not available");
    let bridge_name_lower = args.bridge_name.to_lowercase();

    let mut input_device = None;
    let mut output_device = None;

    for attempt in 1..=30 {
        if input_device.is_none() {
            input_device = host.input_devices()
                .ok()
                .and_then(|mut devs| devs.find(|d| {
                    d.name().unwrap_or_default().to_lowercase().contains(&bridge_name_lower)
                }));
        }
        if output_device.is_none() {
            output_device = host.output_devices()
                .ok()
                .and_then(|mut devs| devs.find(|d| {
                    d.name().unwrap_or_default().to_lowercase().contains(&bridge_name_lower)
                }));
        }
        if input_device.is_some() && output_device.is_some() {
            break;
        }
        if attempt == 1 {
            info!(
                "Waiting for CoreAudio device \"{}\" to appear (is the bridge enabled in Hydra?)...",
                args.bridge_name
            );
        }
        if attempt == 30 {
            error!(
                "CoreAudio device \"{}\" not found after 30 s. Make sure the bridge is enabled.",
                args.bridge_name
            );
            std::process::exit(1);
        }
        std::thread::sleep(Duration::from_secs(1));
    }

    let input_device  = input_device.unwrap();
    let output_device = output_device.unwrap();
    info!("Input  device: {}", input_device.name().unwrap());
    info!("Output device: {}", output_device.name().unwrap());

    // ── 2. CPAL stream config ───────────────────────────────────────────────
    let sample_rate = cpal::SampleRate(48000);
    let channels    = args.channels;

    let stream_config = cpal::StreamConfig {
        channels: channels as u16,
        sample_rate,
        buffer_size: cpal::BufferSize::Default,
    };

    // ── 3. Inferno (Dante) settings ─────────────────────────────────────────
    let mut config_map: BTreeMap<String, String> = BTreeMap::new();
    // BIND_IP in inferno accepts either an IPv4 address ("192.168.1.10")
    // or a network interface name ("en0") — both work.
    config_map.insert("BIND_IP".to_string(),        args.bind_ip.clone());
    config_map.insert("NAME".to_string(),            "Hydra Soundcard".to_string());
    config_map.insert("SAMPLE_RATE".to_string(),    "48000".to_string());
    config_map.insert("RX_CHANNELS".to_string(),    channels.to_string());
    config_map.insert("TX_CHANNELS".to_string(),    channels.to_string());

    let latency_ns = args.latency_ms * 1_000_000;
    config_map.insert("RX_LATENCY_NS".to_string(), latency_ns.to_string());
    config_map.insert("TX_LATENCY_NS".to_string(), latency_ns.to_string());

    // ── 4. usrvclock server — drives the Inferno media clock on macOS ───────
    let clock_path = format!("/tmp/hydra-usrvclock-{}", std::process::id());
    config_map.insert("CLOCK_PATH".to_string(), clock_path.clone());

    let clock_path_thread = clock_path.clone();
    std::thread::spawn(move || {
        let mut server = usrvclock::Server::new(clock_path_thread.into())
            .expect("Failed to start usrvclock server");
        let mut overlay = usrvclock::ClockOverlay {
            clock_id:   6i64, // CLOCK_MONOTONIC on macOS — prevents panic on .now()
            last_sync:  0,
            shift:      0,
            freq_scale: 0.0,
        };
        loop {
            // Incorporate PTP offset written by the daemon (best-effort)
            if let Ok(s) = std::fs::read_to_string("/tmp/ptp-offset") {
                if let Ok(sec) = s.trim().parse::<f64>() {
                    overlay.shift = (sec * 1_000_000_000.0) as i64;
                }
            }
            server.send(overlay);
            std::thread::sleep(Duration::from_millis(100));
        }
    });

    // ── 5. Inferno Settings ─────────────────────────────────────────────────
    let mut settings = Settings::new("Hydra Soundcard", "HydraSC", None, &config_map);
    settings.make_rx_channels(channels);
    settings.make_tx_channels(channels);

    // Write the clock-stats sentinel so the Swift daemon can track our MAC
    let mac     = settings.self_info.mac_address;
    let octets  = mac.octets();
    let clock_stats_filename = format!(
        "/tmp/clock-stats.{:02x}{:02x}{:02x}{:02x}{:02x}{:02x}0000",
        octets[0], octets[1], octets[2], octets[3], octets[4], octets[5]
    );
    if let Err(e) = std::fs::write(&clock_stats_filename, "") {
        error!("Failed to initialize clock-stats file: {:?}", e);
    } else {
        info!("Initialized clock-stats file {}", clock_stats_filename);
    }

    // ── 6. TX ring buffers (CoreAudio → Dante) ──────────────────────────────
    // One lock-free AtomicI32 buffer per channel.
    let ring_buffer_size: usize = 65536; // must be power-of-2
    let tx_buffers: Vec<Box<[AtomicI32]>> = (0..channels)
        .map(|_| {
            (0..ring_buffer_size)
                .map(|_| AtomicI32::new(0))
                .collect::<Vec<_>>()
                .into_boxed_slice()
        })
        .collect();

    let valid_flag = Arc::new(RwLock::new(true));
    let ext_params: Vec<ExternalBufferParameters<Sample>> = tx_buffers
        .iter()
        .map(|buf| unsafe {
            ExternalBufferParameters::new(
                buf.as_ptr() as *const AtomicSample,
                buf.len(),
                1,
                valid_flag.clone(),
                None,
            )
        })
        .collect();

    let current_timestamp = Arc::new(AtomicUsize::new(0));
    let current_timestamp_capture = current_timestamp.clone();

    // CPAL input: system audio → Dante TX ring buffers
    let tx_buffers_arc = Arc::new(tx_buffers);
    let input_stream = input_device.build_input_stream(
        &stream_config,
        move |data: &[f32], _: &cpal::InputCallbackInfo| {
            let frames    = data.len() / channels;
            let write_pos = current_timestamp_capture.load(Ordering::Relaxed);
            for f in 0..frames {
                let idx = (write_pos + f) % ring_buffer_size;
                for ch in 0..channels {
                    let s_f32 = data[f * channels + ch];
                    let s_i32 = (s_f32.clamp(-1.0, 1.0) * (i32::MAX as f32)) as i32;
                    tx_buffers_arc[ch][idx].store(s_i32, Ordering::Relaxed);
                }
            }
            // Advance timestamp only after ALL channels have been written
            current_timestamp_capture.store(write_pos + frames, Ordering::Release);
        },
        |err| error!("CPAL input error: {:?}", err),
        None,
    ).expect("Failed to build CPAL input stream");

    // ── 7. RX output buffer (Dante RX → CoreAudio) ─────────────────────────
    // Protected ring buffer, written by inferno callback, read by CPAL output.
    // Each channel has its own Vec<f32> so there is no inter-channel dependency.
    const RX_BUF: usize = 16384;
    let rx_buffers: Arc<Vec<Mutex<Vec<f32>>>> = Arc::new(
        (0..channels).map(|_| Mutex::new(vec![0f32; RX_BUF])).collect()
    );
    let rx_write_pos: Arc<Vec<AtomicUsize>> = Arc::new(
        (0..channels).map(|_| AtomicUsize::new(0)).collect()
    );
    let rx_read_pos: Arc<Vec<AtomicUsize>> = Arc::new(
        (0..channels).map(|_| AtomicUsize::new(0)).collect()
    );

    let rx_buffers_out   = rx_buffers.clone();
    let rx_write_out     = rx_write_pos.clone();
    let rx_read_out      = rx_read_pos.clone();

    // CPAL output: drain rx ring buffers → CoreAudio output
    let output_stream = output_device.build_output_stream(
        &stream_config,
        move |data: &mut [f32], _: &cpal::OutputCallbackInfo| {
            let frames = data.len() / channels;
            for ch in 0..channels {
                let wpos = rx_write_out[ch].load(Ordering::Acquire);
                let rpos = rx_read_out[ch].load(Ordering::Relaxed);
                let available = if wpos >= rpos { wpos - rpos } else { RX_BUF - rpos + wpos };
                let to_read = frames.min(available);

                let buf = rx_buffers_out[ch].lock().unwrap();
                let mut idx = rpos;
                for f in 0..frames {
                    let sample = if f < to_read {
                        let s = buf[idx % RX_BUF];
                        idx += 1;
                        s
                    } else {
                        0.0
                    };
                    data[f * channels + ch] = sample;
                }
                // Advance read position only after consuming all frames for this channel
                rx_read_out[ch].store((rpos + to_read) % RX_BUF, Ordering::Release);
            }
        },
        |err| error!("CPAL output error: {:?}", err),
        None,
    ).expect("Failed to build CPAL output stream");

    input_stream.play().expect("Failed to start CPAL input stream");
    output_stream.play().expect("Failed to start CPAL output stream");
    info!("CoreAudio CPAL streams running.");

    // ── 8. Start Inferno (Dante) server ────────────────────────────────────
    let mut server = DeviceServer::start(settings).await;

    // Dante TX: feed audio from ring buffers into Dante network
    let (tx_start_sender, tx_start_receiver) = tokio::sync::oneshot::channel();
    server.transmit_from_external_buffer(
        ext_params,
        tx_start_receiver,
        current_timestamp.clone(),
        None,
    ).await;
    let _ = tx_start_sender.send(0); // start immediately
    info!("Dante transmitter started.");

    // Dante RX: receive audio from Dante network and write to per-channel ring buffers.
    // Using inferno's native receive_with_callback — the correct API for this pattern.
    let rx_buffers_cb  = rx_buffers.clone();
    let rx_write_cb    = rx_write_pos.clone();

    server.receive_with_callback(Box::new(move |samples_count: usize, ch_data: &Vec<Vec<Sample>>| {
        for (ch, samples) in ch_data.iter().enumerate() {
            if ch >= channels { break; }
            let mut buf = rx_buffers_cb[ch].lock().unwrap();
            let mut wpos = rx_write_cb[ch].load(Ordering::Relaxed);
            for &s in &samples[..samples_count] {
                // Convert inferno Sample (i32) to f32
                buf[wpos % RX_BUF] = (s as f32) / (i32::MAX as f32);
                wpos = wpos.wrapping_add(1);
            }
            rx_write_cb[ch].store(wpos % RX_BUF, Ordering::Release);
        }
    })).await;
    info!("Dante receiver started.");

    // ── 9. Run until signal or parent dies ─────────────────────────────────
    let mut sigterm = tokio::signal::unix::signal(
        tokio::signal::unix::SignalKind::terminate()
    ).unwrap();

    let parent_check = tokio::spawn(async {
        let mut interval = tokio::time::interval(Duration::from_secs(1));
        loop {
            interval.tick().await;
            if unsafe { libc::getppid() } == 1 {
                info!("Parent process has exited. Shutting down bridge...");
                break;
            }
        }
    });

    info!("Dante Virtual Soundcard bridge is running. Press Ctrl+C to stop.");
    tokio::select! {
        _ = tokio::signal::ctrl_c() => { info!("Shutting down via Ctrl+C..."); }
        _ = sigterm.recv()          => { info!("Shutting down via SIGTERM..."); }
        _ = parent_check            => {}
    }

    // ── 10. Clean shutdown ──────────────────────────────────────────────────
    let _ = input_stream.pause();
    let _ = output_stream.pause();
    let _ = tokio::time::timeout(Duration::from_millis(500), server.shutdown()).await;
    let _ = std::fs::remove_file(&clock_stats_filename);
    info!("Hydra Inferno Bridge stopped cleanly.");
}
