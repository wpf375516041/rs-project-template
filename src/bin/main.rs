use anyhow::Result;
use tracing::{Level, info};
use tracing_subscriber::fmt::time::ChronoLocal;

#[tokio::main]
async fn main() -> Result<()> {
    // tracing 日志初始化
    tracing_subscriber::fmt()
        .with_max_level(Level::INFO)
        .with_line_number(true)
        .with_timer(ChronoLocal::new("%Y-%m-%d %H:%M:%S%.3f".to_string()))
        .with_ansi(false)
        .init();
    // 业务逻辑
    info!("hello world!");

    Ok(())
}
