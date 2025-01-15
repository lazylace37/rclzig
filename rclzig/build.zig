const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "rclzig",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/rclzig.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibC();

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/service_msgs/" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/builtin_interfaces" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_runtime_c" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_typesupport_interface" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rcutils" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_runtime_cpp" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_typesupport_fastrtps_c" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_typesupport_fastrtps_cpp" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rmw" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_typesupport_c" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_typesupport_cpp" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rcpputils" });

    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_typesupport_introspection_c" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_typesupport_introspection_cpp" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/std_msgs" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rcl" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rcl_interfaces" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rcl_logging_interface" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rcl_yaml_param_parser" });

    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rcutils" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rmw" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_runtime_c" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/type_description_interfaces" });
    lib_unit_tests.addIncludePath(.{ .cwd_relative = "/opt/ros/jazzy/include/rosidl_dynamic_typesupport" });

    lib_unit_tests.addIncludePath(.{ .cwd_relative = "./src/" });
    lib_unit_tests.addLibraryPath(.{ .cwd_relative = "/opt/ros/jazzy/lib/" });
    lib_unit_tests.linkSystemLibrary("rcl");
    lib_unit_tests.linkSystemLibrary("rcutils");
    lib_unit_tests.linkSystemLibrary("rmw");
    lib_unit_tests.linkSystemLibrary("std_msgs__rosidl_generator_c");
    lib_unit_tests.linkLibC();

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
