use std::collections::BTreeMap;
use std::sync::atomic::{AtomicI32, AtomicUsize, Ordering};
use std::sync::{Arc, Mutex, RwLock};
use std::time::Duration;
use clap::Parser;
use log::{error, info};
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};

use inferno_aoip::device_server::{
    DeviceServer, ExternalBufferParameters, RealTimeSamplesReceiver, Settings, AtomicSample
};

#[derive(Parser, Debug)]
#[command(author, version, about = "Hydra Inferno Bridge", long_about = None)]
struct Args {
    #[arg(long, short)]
    bridge_name: String,

    #[arg(long, short)]
    interface_name: String,

    #[arg(long, short)]
    latency_ms: u64,

    #[arg(long, short)]
    channels: usize,
}

// Intermediate ring buffer for Dante RX -> CoreAudio output
struct RxRingBuffer {
    buffer: Vec<Vec<i32>>,
    write_pos: usize,
    read_pos: usize,
    capacity: usize,
}

impl RxRingBuffer {
    fn new(channels: usize, capacity: usize) -> Self {
        Self {
            buffer: vec![vec![0; capacity]; channels],
            write_pos: 0,
            read_pos: 0,
            capacity,
        }
    }

    fn write(&mut self, ch: usize, samples: &[i32]) {
        let len = samples.len();
        let mut idx = self.write_pos;
        for &val in samples {
            self.buffer[ch][idx % self.capacity] = val;
            idx += 1;
        }
        if ch == self.buffer.len() - 1 {
            self.write_pos = (self.write_pos + len) % self.capacity;
        }
    }

    fn read(&mut self, ch: usize, out: &mut [i32]) -> usize {
        let available = if self.write_pos >= self.read_pos {
            self.write_pos - self.read_pos
        } else {
            self.capacity - self.read_pos + self.write_pos
        };
        
        let to_read = out.len().min(available);
        let mut idx = self.read_pos;
        for i in 0..to_read {
            out[i] = self.buffer[ch][idx % self.capacity];
            idx += 1;
        }
        if ch == self.buffer.len() - 1 {
            self.read_pos = (self.read_pos + to_read) % self.capacity;
        }
        to_read
    }
}

#[tokio::main]
async fn main() {
    let logenv = env_logger::Env::default().default_filter_or("info");
    env_logger::init_from_env(logenv);

    let args = Args::parse();
    info!("Starting Hydra Inferno Bridge with settings: {:?}", args);

    // 1. Locate CoreAudio devices (retry — the bridge may not be enabled yet)
    let host = cpal::host_from_id(cpal::HostId::CoreAudio).expect("CoreAudio not available");
    let bridge_name_lower = args.bridge_name.to_lowercase();

    let mut input_device = None;
    let mut output_device = None;

    for attempt in 1..=30 {
        if input_device.is_none() {
            input_device = host.input_devices()
                .ok()
                .and_then(|mut devs| devs.find(|d| d.name().unwrap_or_default().to_lowercase().contains(&bridge_name_lower)));
        }
        if output_device.is_none() {
            output_device = host.output_devices()
                .ok()
                .and_then(|mut devs| devs.find(|d| d.name().unwrap_or_default().to_lowercase().contains(&bridge_name_lower)));
        }
        if input_device.is_some() && output_device.is_some() {
            break;
        }
        if attempt == 1 {
            info!("Waiting for CoreAudio device \"{}\" to appear (is the bridge enabled in Hydra?)...", args.bridge_name);
        }
        if attempt == 30 {
            error!("CoreAudio device \"{}\" not found after 30s. Make sure the bridge is enabled in the Hydra app.", args.bridge_name);
            std::process::exit(1);
        }
        std::thread::sleep(Duration::from_secs(1));
    }

    let input_device = input_device.unwrap();
    let output_device = output_device.unwrap();

    info!("Input device: {}", input_device.name().unwrap());
    info!("Output device: {}", output_device.name().unwrap());

    // 2. Configure CPAL formats (typically 48000Hz, selected channels)
    let sample_rate = cpal::SampleRate(48000);
    
    let input_config = cpal::StreamConfig {
        channels: args.channels as u16,
        sample_rate,
        buffer_size: cpal::BufferSize::Default,
    };
    
    let output_config = cpal::StreamConfig {
        channels: args.channels as u16,
        sample_rate,
        buffer_size: cpal::BufferSize::Default,
    };

    // 3. Prepare Dante parameters via Environment or Settings map
    let mut config_map = BTreeMap::new();
    config_map.insert("BIND_IP".to_string(), args.interface_name.clone());
    config_map.insert("NAME".to_string(), "Hydra Soundcard".to_string());
    config_map.insert("SAMPLE_RATE".to_string(), "48000".to_string());
    config_map.insert("RX_CHANNELS".to_string(), args.channels.to_string());
    config_map.insert("TX_CHANNELS".to_string(), args.channels.to_string());

    let clock_path = format!("/tmp/hydra-usrvclock-{}", std::process::id());
    config_map.insert("CLOCK_PATH".to_string(), clock_path.clone());
    
    let latency_ns = args.latency_ms * 1_000_000;
    config_map.insert("RX_LATENCY_NS".to_string(), latency_ns.to_string());
    config_map.insert("TX_LATENCY_NS".to_string(), latency_ns.to_string());

    // Use ALT_PORT to prevent port conflicts with Audinate's DVS daemon (dvsd)
    config_map.insert("ALT_PORT".to_string(), "18700".to_string());

    // Start a local fake usrvclock server to drive the media clock on macOS
    let clock_path_thread = clock_path.clone();
    std::thread::spawn(move || {
        let mut server = usrvclock::Server::new(clock_path_thread.into()).expect("Failed to start usrvclock server");
        let overlay = usrvclock::ClockOverlay {
            clock_id: 6i64, // CLOCK_MONOTONIC on macOS (fixes panic on .now())
            last_sync: 0,
            shift: 0,
            freq_scale: 0.0,
        };
        loop {
            server.send(overlay);
            std::thread::sleep(Duration::from_millis(100));
        }
    });

    let mut settings = Settings::new("Hydra Soundcard", "HydraSC", None, &config_map);
    settings.make_rx_channels(args.channels);
    settings.make_tx_channels(args.channels);

    // 4. Dante Transmitter Ring Buffers (lock-free Atomic arrays)
    // Allocated contiguous arrays of AtomicSample
    let ring_buffer_size = 65536; // power of 2
    let mut tx_buffers = vec![];
    for _ in 0..args.channels {
        let mut buf = Vec::with_capacity(ring_buffer_size);
        for _ in 0..ring_buffer_size {
            buf.push(AtomicI32::new(0));
        }
        tx_buffers.push(buf.into_boxed_slice());
    }

    let valid_flag = Arc::new(RwLock::new(true));
    let mut ext_params = vec![];
    for buf in &tx_buffers {
        let param = unsafe {
            ExternalBufferParameters::new(
                buf.as_ptr() as *const AtomicSample,
                buf.len(),
                1,
                valid_flag.clone(),
                None,
            )
        };
        ext_params.push(param);
    }

    let current_timestamp = Arc::new(AtomicUsize::new(0));
    let current_timestamp_capture = current_timestamp.clone();
    
    // cpal input stream captures audio from the virtual bridge output (played by DAW/system apps)
    // and writes it to the Dante transmitter atomic buffers
    let tx_buffers_capture = Arc::new(tx_buffers);
    let channels = args.channels;
    
    let input_stream = input_device.build_input_stream(
        &input_config,
        move |data: &[f32], _: &cpal::InputCallbackInfo| {
            let frames = data.len() / channels;
            let mut write_pos = current_timestamp_capture.load(Ordering::Relaxed);
            
            for f in 0..frames {
                let idx = (write_pos + f) % ring_buffer_size;
                for ch in 0..channels {
                    let sample_f32 = data[f * channels + ch];
                    // Convert float to i32 Sample
                    let sample_i32 = (sample_f32.clamp(-1.0, 1.0) * (i32::MAX as f32)) as i32;
                    tx_buffers_capture[ch][idx].store(sample_i32, Ordering::Relaxed);
                }
            }
            current_timestamp_capture.store(write_pos + frames, Ordering::Release);
        },
        |err| error!("Error on CPAL input stream: {:?}", err),
        None
    ).expect("Failed to build input stream");

    // 5. Dante Receiver Ring Buffer (Dante RX -> CPAL output)
    let rx_ring = Arc::new(Mutex::new(RxRingBuffer::new(args.channels, 16384)));
    let rx_ring_play = rx_ring.clone();
    
    let output_stream = output_device.build_output_stream(
        &output_config,
        move |data: &mut [f32], _: &cpal::OutputCallbackInfo| {
            let mut rx_ring_locked = rx_ring_play.lock().unwrap();
            let frames = data.len() / channels;
            
            // Read received Dante audio from the ring buffer
            let mut ch_buf = vec![0; frames];
            for ch in 0..channels {
                let read = rx_ring_locked.read(ch, &mut ch_buf);
                for f in 0..frames {
                    let sample_i32 = if f < read { ch_buf[f] } else { 0 };
                    let sample_f32 = (sample_i32 as f32) / (i32::MAX as f32);
                    data[f * channels + ch] = sample_f32;
                }
            }
        },
        |err| error!("Error on CPAL output stream: {:?}", err),
        None
    ).expect("Failed to build output stream");

    // Start CPAL streams
    input_stream.play().expect("Failed to start input stream");
    output_stream.play().expect("Failed to start output stream");
    info!("CoreAudio CPAL input and output streams running.");

    // 6. Start Dante server
    let mut server = DeviceServer::start(settings).await;
    
    // Dante TX
    let (tx_start_sender, tx_start_receiver) = tokio::sync::oneshot::channel();
    let tx_current_timestamp = current_timestamp.clone();
    server.transmit_from_external_buffer(
        ext_params,
        tx_start_receiver,
        tx_current_timestamp,
        None
    ).await;
    let _ = tx_start_sender.send(0); // start immediately
    info!("Dante transmitter started.");

    // Dante RX realtime task
    let mut rx_receiver = server.receive_realtime().await;
    info!("Dante receiver started.");

    // background task to poll Dante RX and write to rx_ring
    let rx_ring_poll = rx_ring.clone();
    let poll_task = tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_millis(5));
        let mut last_timestamp: usize = 0;
        let mut ch_bufs = vec![vec![0; 512]; channels];
        
        loop {
            interval.tick().await;
            
            let current_clock = rx_receiver.clock().wrapping_now_in_timebase(48000).unwrap_or(0) as usize;
            
            if current_clock == 0 {
                continue;
            }
            
            if last_timestamp == 0 {
                last_timestamp = current_clock;
            }
            
            let diff = (current_clock as isize) - (last_timestamp as isize);
            if diff <= 0 {
                continue;
            }
            
            let to_read = (diff as usize).min(512);
            let mut read_ok = true;
            for ch in 0..channels {
                if !rx_receiver.get_samples(last_timestamp, ch, &mut ch_bufs[ch][..to_read]) {
                    read_ok = false;
                }
            }
            
            if read_ok {
                let mut rx_ring_locked = rx_ring_poll.lock().unwrap();
                for ch in 0..channels {
                    rx_ring_locked.write(ch, &ch_bufs[ch][..to_read]);
                }
                last_timestamp += to_read;
            } else {
                // reset or skip if packet lost/not ready
                last_timestamp = current_clock;
            }
        }
    });

    info!("Dante Virtual Soundcard bridge is running. Press Ctrl+C to stop.");
    tokio::select! {
        _ = tokio::signal::ctrl_c() => {
            info!("Shutting down...");
        }
    }

    poll_task.abort();
    let _ = input_stream.pause();
    let _ = output_stream.pause();
    server.shutdown().await;
    info!("Hydra Inferno Bridge stopped cleanly.");
}
