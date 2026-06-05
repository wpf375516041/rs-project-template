let mode = variable::get("cross_cache_mode");
file::write(".env", "CROSS_CACHE_MODE=" + mode);
