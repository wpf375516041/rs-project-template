#[allow(unused)]
use tracing::info;

pub fn use_jemalloc() {
    #[cfg(not(target_env = "msvc"))]
    use tikv_jemallocator::Jemalloc;

    // 将 Jemalloc 设置为全局内存分配器
    #[cfg(not(target_env = "msvc"))]
    #[global_allocator]
    static GLOBAL: Jemalloc = Jemalloc;
}

pub fn start_memory_profilers() {
    // 配置 Jemalloc 内存分析参数
    #[allow(non_upper_case_globals)]
    #[unsafe(export_name = "malloc_conf")]
    pub static malloc_conf: &[u8] = b"prof:true,prof_active:true,lg_prof_sample:16\0";

    // Memory profiler
    tokio::spawn(async {
        let mut interval = tokio::time::interval(std::time::Duration::from_secs(300));
        loop {
            interval.tick().await;
            #[cfg(not(target_env = "msvc"))]
            {
                info!("Starting memory profiler...");
                match dump_memory_profile().await {
                    Ok(profile_path) => {
                        info!("Memory profile dumped successfully: {}", profile_path)
                    }
                    Err(e) => info!("Failed to dump memory profile: {}", e),
                }
            }
        }
    });
}

#[cfg(not(target_env = "msvc"))]
async fn dump_memory_profile() -> Result<String, String> {
    // 获取 jemalloc 的 profiling 控制器
    let prof_ctl = jemalloc_pprof::PROF_CTL
        .as_ref()
        .ok_or_else(|| "Profiling controller not available".to_string())?;

    let mut prof_ctl = prof_ctl.lock().await;

    // 检查 profiling 是否已激活
    if !prof_ctl.activated() {
        return Err("Jemalloc profiling is not activated".to_string());
    }

    // 调用 dump_pprof() 方法生成 pprof 数据
    let pprof_data = prof_ctl
        .dump_pprof()
        .map_err(|e| format!("Failed to dump pprof: {}", e))?;

    // 使用时间戳生成唯一文件名
    let timestamp = chrono::Utc::now().format("%Y%m%d_%H%M%S");
    let filename = format!("memory_profile_{}.pb", timestamp);

    // 将 pprof 数据写入本地文件
    std::fs::write(&filename, pprof_data)
        .map_err(|e| format!("Failed to write profile file: {}", e))?;

    info!("Memory profile dumped to: {}", filename);
    Ok(filename)
}
