pub mod common;
#[macro_export]
macro_rules! here {
    // 基础用法：here!() -> "at file.rs:line:column"
    () => {
        concat!("at ", file!(), ":", line!(), ":", column!())
    };

    // 格式化用法：here!("format {} {}", arg1, arg2) -> "format arg1 arg2 at file.rs:line:column"
    ($($arg:tt)*) => {
        format!("{} {}", format_args!($($arg)*), here!())
    };
}
