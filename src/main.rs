use anyhow::Context;
use dav_server::{localfs::LocalFs, memls::MemLs, DavHandler};
use serde::Deserialize;
use std::{
    ffi::OsString,
    fs::File,
    io::BufReader,
    net::{IpAddr, SocketAddr},
    path::PathBuf,
};

#[derive(Deserialize)]
struct Config {
    ip: IpAddr,
    port: u16,
    path: PathBuf,
}

impl Config {
    fn addr(&self) -> SocketAddr {
        SocketAddr::new(self.ip, self.port)
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let config_file_path: OsString = match std::env::args_os().nth(1) {
        Some(x) => x,
        None => {
            eprintln!(
                "usage: {} [config-file.json]",
                std::env::args_os()
                    .next()
                    .unwrap_or_else(|| OsString::from("???"))
                    .to_string_lossy()
            );
            std::process::exit(1);
        }
    };

    systemd_journal_logger::JournalLog::new().context("Failed to initialize logging")?;
    log::set_max_level(log::LevelFilter::Trace);

    log::debug!("Hello world");

    let file: File = File::open(&config_file_path).with_context(|| {
        format!(
            "Failed to open config file {}",
            config_file_path.to_string_lossy()
        )
    })?;
    let reader: BufReader<File> = BufReader::new(file);
    let config: Config =
        serde_json::from_reader(reader).context("Failed to deserialize config file")?;

    let addr: SocketAddr = config.addr();
    let davpath: PathBuf = config.path;

    log::info!("listening on {addr}");
    log::info!("serving {}", davpath.to_string_lossy());

    const PUBLIC: bool = false;
    const CASE_INSENSITIVE: bool = false;
    const MACOS: bool = false;
    let handler: DavHandler = DavHandler::builder()
        .filesystem(LocalFs::new(davpath, PUBLIC, CASE_INSENSITIVE, MACOS))
        .locksystem(MemLs::new())
        .build_handler();
    let routes = dav_server::warp::dav_handler(handler);

    let (_addr, fut) = warp::serve(routes)
        .try_bind_with_graceful_shutdown(addr, async move {
            tokio::signal::ctrl_c()
                .await
                .expect("failed to listen to shutdown signal");
        })
        .context("try_bind_with_graceful_shutdown failed")?;

    fut.await;

    log::warn!("shutting down");

    Ok(())
}
