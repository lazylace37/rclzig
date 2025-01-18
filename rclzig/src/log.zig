const std = @import("std");
const rcl_c = @import("rcl.zig").rcl_c;

pub const RCUTILS_LOG_CONDITION = enum {
    EMPTY,
    ONCE_BEFORE,
    ONCE_AFTER,
    // EXPRESSION_BEFORE,
    // EXPRESSION_AFTER,
    // FUNCTION_BEFORE,
    // FUNCTION_AFTER,
    // SKIPFIRST_BEFORE,
    // SKIPFIRST_AFTER,
    // THROTTLE_BEFORE,
    // THROTTLE_AFTER,
};

inline fn logging_autoinit_allocator(allocator: rcl_c.rcl_allocator_t) void {
    if (!rcl_c.g_rcutils_logging_initialized) {
        @branchHint(.cold);

        const ret = rcl_c.rcutils_logging_initialize_with_allocator(allocator);
        if (ret != rcl_c.RCUTILS_RET_OK) {
            std.log.err("Failed to initialize logging\n{}\n", .{rcl_c.rcutils_get_error_string()});
            rcl_c.rcutils_reset_error();
        }
    }
}

inline fn logging_autoinit() void {
    return logging_autoinit_allocator(rcl_c.rcl_get_default_allocator());
}

pub fn log_cond_named(severity: i32, condition_before: RCUTILS_LOG_CONDITION, condition_after: RCUTILS_LOG_CONDITION, name: [*c]const u8, message: [*c]const u8) void {
    _ = condition_before;
    _ = condition_after;
    logging_autoinit();
    if (rcl_c.rcutils_logging_logger_is_enabled_for(name, severity)) {
        // TODO: condition_before \

        // TODO: this is useless as this gets the current location, not the caller's https://github.com/ziglang/zig/issues/21906
        const src = @src();
        const __rcutils_logging_location = rcl_c.rcutils_log_location_t{ .function_name = src.fn_name, .file_name = src.file, .line_number = src.line };
        rcl_c.rcutils_log_internal(&__rcutils_logging_location, severity, name, message);

        // TODO: condition_after \
    }
}

pub const RCUTILS_LOG_FATAL = _RCUTILS_LOG_SEVERITY(rcl_c.RCUTILS_LOG_SEVERITY_FATAL);
pub const RCUTILS_LOG_FATAL_NAMED = _RCUTILS_LOG_SEVERITY_NAMED(rcl_c.RCUTILS_LOG_SEVERITY_FATAL);
pub const RCUTILS_LOG_ERROR = _RCUTILS_LOG_SEVERITY(rcl_c.RCUTILS_LOG_SEVERITY_ERROR);
pub const RCUTILS_LOG_ERROR_NAMED = _RCUTILS_LOG_SEVERITY_NAMED(rcl_c.RCUTILS_LOG_SEVERITY_ERROR);
pub const RCUTILS_LOG_WARN = _RCUTILS_LOG_SEVERITY(rcl_c.RCUTILS_LOG_SEVERITY_WARN);
pub const RCUTILS_LOG_WARN_NAMED = _RCUTILS_LOG_SEVERITY_NAMED(rcl_c.RCUTILS_LOG_SEVERITY_WARN);
pub const RCUTILS_LOG_INFO = _RCUTILS_LOG_SEVERITY(rcl_c.RCUTILS_LOG_SEVERITY_INFO);
pub const RCUTILS_LOG_INFO_NAMED = _RCUTILS_LOG_SEVERITY_NAMED(rcl_c.RCUTILS_LOG_SEVERITY_INFO);
pub const RCUTILS_LOG_DEBUG = _RCUTILS_LOG_SEVERITY(rcl_c.RCUTILS_LOG_SEVERITY_DEBUG);
pub const RCUTILS_LOG_DEBUG_NAMED = _RCUTILS_LOG_SEVERITY_NAMED(rcl_c.RCUTILS_LOG_SEVERITY_DEBUG);

fn _RCUTILS_LOG_SEVERITY(comptime severity: rcl_c.RCUTILS_LOG_SEVERITY) fn (message: [*c]const u8) void {
    const T = struct {
        fn log_func(message: [*c]const u8) void {
            log_cond_named(severity, RCUTILS_LOG_CONDITION.EMPTY, RCUTILS_LOG_CONDITION.EMPTY, null, message);
        }
    };
    return T.log_func;
}

fn _RCUTILS_LOG_SEVERITY_NAMED(comptime severity: rcl_c.RCUTILS_LOG_SEVERITY) fn (name: [*c]const u8, message: [*c]const u8) void {
    const T = struct {
        fn log_func(name: [*c]const u8, message: [*c]const u8) void {
            log_cond_named(severity, RCUTILS_LOG_CONDITION.EMPTY, RCUTILS_LOG_CONDITION.EMPTY, name, message);
        }
    };
    return T.log_func;
}

test "RCUTILS_LOG_FATAL" {
    RCUTILS_LOG_FATAL("fatal");
}

test "RCUTILS_LOG_FATAL_NAMED" {
    RCUTILS_LOG_FATAL_NAMED("name", "fatal");
}

test "RCUTILS_LOG_ERROR" {
    RCUTILS_LOG_ERROR("error");
}

test "RCUTILS_LOG_ERROR_NAMED" {
    RCUTILS_LOG_ERROR_NAMED("name", "error");
}

test "RCUTILS_LOG_WARN" {
    RCUTILS_LOG_WARN("warn");
}

test "RCUTILS_LOG_WARN_NAMED" {
    RCUTILS_LOG_WARN_NAMED("name", "warn");
}

test "RCUTILS_LOG_INFO" {
    RCUTILS_LOG_INFO("info");
}

test "RCUTILS_LOG_INFO_NAMED" {
    RCUTILS_LOG_INFO_NAMED("name", "info");
}

test "RCUTILS_LOG_DEBUG" {
    RCUTILS_LOG_DEBUG("debug");
}

test "RCUTILS_LOG_DEBUG_NAMED" {
    RCUTILS_LOG_DEBUG_NAMED("name", "debug");
}
