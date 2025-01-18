const std = @import("std");
const testing = std.testing;
const rcl_c = @import("rcl.zig").rcl_c;
const convert_camel_case_to_lower_case_underscore = @import("utils.zig").convert_camel_case_to_lower_case_underscore;

const conversions = @import("message/conversion.zig");
const ros_msg_to_c = conversions.ros_msg_to_c;
const ros_msg_c_free = conversions.ros_msg_c_free;

const ConversionError = error{InitError};

fn RosMessageFromStruct(comptime RosMessageT: type, comptime c: type) type {
    comptime {
        const msg_struct_fields = std.meta.fields(RosMessageT);
        var fields: [msg_struct_fields.len]std.builtin.Type.StructField = undefined;

        var is_c_compatible = true;

        for (msg_struct_fields, 0..) |f, i| {
            switch (f.type) {
                bool, f32, f64, i8, u8, i16, u16, i32, u32, i64, u64 => {
                    fields[i] = .{
                        .name = f.name,
                        .type = f.type,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__String => { // The String type is uniquely handled
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const u8,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__float__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const f32,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__double__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const f64,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__long_double__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const f80,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__char__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const i8,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__wchar__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const u16,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__boolean__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const bool,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__octet__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const u8,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__uint8__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const u8,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__int8__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const i8,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__uint16__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const u16,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__int16__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const i16,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__uint32__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const u32,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__int32__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const i32,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__uint64__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const u64,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                c.rosidl_runtime_c__int64__Sequence => {
                    is_c_compatible = false;
                    fields[i] = .{
                        .name = f.name,
                        .type = []const i64,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                else => { // This is probably a nested ROS message
                    const type_name = @typeName(f.type);
                    if (std.mem.endsWith(u8, type_name, "__Sequence")) {
                        // This is a Sequence of non-primitive ROS messages
                        is_c_compatible = false;

                        // Get the underlying type
                        const sub_msg_fields = @typeInfo(f.type).@"struct".fields;
                        const sub_msg_data_field = sub_msg_fields[0];
                        const sub_msg_data_ptr_type = sub_msg_data_field.type;
                        const sub_msg_data_type = @typeInfo(sub_msg_data_ptr_type).pointer.child;

                        const sub_msg_type = RosMessageFromStruct(sub_msg_data_type, c);
                        fields[i] = .{
                            .name = f.name,
                            .type = []sub_msg_type,
                            .default_value = null,
                            .is_comptime = false,
                            .alignment = 0,
                        };
                    } else {
                        const sub_msg_type = RosMessageFromStruct(f.type, c);
                        fields[i] = .{
                            .name = f.name,
                            .type = sub_msg_type,
                            .default_value = null,
                            .is_comptime = false,
                            .alignment = 0,
                        };
                    }
                },
            }
        }

        const Type = @Type(.{
            .@"struct" = .{
                .layout = if (!is_c_compatible) .auto else .@"extern",
                .fields = fields[0..],
                .decls = &[_]std.builtin.Type.Declaration{},
                .is_tuple = false,
            },
        });
        return Type;
    }
}

pub fn RosMessage(comptime package: []const u8, comptime name: []const u8) type {
    comptime {
        const header_file_name = package ++ "/" ++ "msg" ++ "/" ++ convert_camel_case_to_lower_case_underscore(name) ++ ".h";
        const c = @cImport({
            @cInclude(header_file_name);
            @cInclude("string.h");
        });

        const c_struct_name = package ++ "__" ++ "msg" ++ "__" ++ name;
        const RosMessageC = @field(c, c_struct_name);
        const RosMessageT = RosMessageFromStruct(RosMessageC, c);

        const msg_init = @field(c, c_struct_name ++ "__init");
        const msg_fini = @field(c, c_struct_name ++ "__fini");

        const get_type_support_name = "rosidl_typesupport_c" ++ "__" ++ "get_message_type_support_handle" ++ "__" ++ package ++ "__msg__" ++ name;
        const get_type_support_func = @field(c, get_type_support_name);

        return struct {
            pub const package_name: []const u8 = package;
            pub const message_name: []const u8 = name;
            pub const get_type_support_handle = get_type_support_func;
            pub const cImport: type = c;

            const Self = @This();

            m: RosMessageT = std.mem.zeroInit(RosMessageT, .{}),

            pub fn to_c(m: *const Self) ConversionError!RosMessageC {
                var c_msg = std.mem.zeroInit(RosMessageC, .{});
                if (!msg_init(&c_msg)) {
                    msg_fini(&c_msg);
                    return error.InitError;
                }

                ros_msg_to_c(c, RosMessageT, RosMessageC, m.m, &c_msg);
                return c_msg;
            }

            pub fn free_c(_: *const Self, c_msg: *RosMessageC) void {
                msg_fini(c_msg);
            }

            pub fn init() Self {
                return .{};
            }

            pub fn fini(self: *Self) void {
                _ = self;
                return;
            }
        };
    }
}

test "test_Bool" {
    var msg = RosMessage("std_msgs", "Bool"){};
    msg.m.data = true;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, true);
}

test "test_Byte" {
    var msg = RosMessage("std_msgs", "Byte"){};
    msg.m.data = 123;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 123);
}

test "test_Char" {
    var msg = RosMessage("std_msgs", "Char"){};
    msg.m.data = 123;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 123);
}

test "test_ColorRGBA" {
    var msg = RosMessage("std_msgs", "ColorRGBA"){};
    msg.m = .{ .r = 0.69, .g = 0.420, .b = 42.001, .a = 0.1 };

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.r, 0.69);
    try testing.expectEqual(msg_c.g, 0.420);
    try testing.expectEqual(msg_c.b, 42.001);
    try testing.expectEqual(msg_c.a, 0.1);
}

test "test_Float32" {
    var msg = RosMessage("std_msgs", "Float32"){};
    msg.m.data = 123.456;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 123.456);
}

test "test_Float64" {
    var msg = RosMessage("std_msgs", "Float64"){};
    msg.m.data = 123.456;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 123.456);
}

test "test_Int8" {
    var msg = RosMessage("std_msgs", "Int8"){};
    msg.m.data = 127;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 127);
}

test "test_Int16" {
    var msg = RosMessage("std_msgs", "Int16"){};
    msg.m.data = 42;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 42);
}

test "test_Int32" {
    var msg = RosMessage("std_msgs", "Int32"){};
    msg.m.data = 42;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 42);
}

test "test_Int64" {
    var msg = RosMessage("std_msgs", "Int64"){};
    msg.m.data = 42;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 42);
}

test "test_UInt8" {
    var msg = RosMessage("std_msgs", "UInt8"){};
    msg.m.data = 42;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 42);
}

test "test_UInt16" {
    var msg = RosMessage("std_msgs", "UInt16"){};
    msg.m.data = 42;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 42);
}

test "test_UInt32" {
    var msg = RosMessage("std_msgs", "UInt32"){};
    msg.m.data = 42;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 42);
}

test "test_UInt64" {
    var msg = RosMessage("std_msgs", "UInt64"){};
    msg.m.data = 42;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.data, 42);
}

test "test_String" {
    var msg = RosMessage("std_msgs", "String"){};
    msg.m.data = "ciaociao";

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    const data: [:0]const u8 = std.mem.span(msg_c.data.data);
    try testing.expect(std.mem.eql(u8, data, "ciaociao"));
    try testing.expectEqual(msg_c.data.size, 8);
    try testing.expectEqual(msg_c.data.capacity, 9);
}

test "test_Pose" {
    var msg = RosMessage("geometry_msgs", "Pose"){};
    msg.m.position = .{ .x = 8, .y = 9, .z = 10 };
    msg.m.orientation = .{ .x = 0, .y = 1, .z = 0, .w = 1 };

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.position.x, 8);
    try testing.expectEqual(msg_c.position.y, 9);
    try testing.expectEqual(msg_c.position.z, 10);
    try testing.expectEqual(msg_c.orientation.x, 0);
    try testing.expectEqual(msg_c.orientation.y, 1);
    try testing.expectEqual(msg_c.orientation.z, 0);
    try testing.expectEqual(msg_c.orientation.w, 1);
}

test "test_MultiArrayLayout" {
    const T = RosMessage("std_msgs", "MultiArrayLayout");
    var msg = T{};

    var dim: [3]@typeInfo(@TypeOf(msg.m.dim)).pointer.child = .{
        .{ .label = "height", .size = 480, .stride = 3 * 640 * 480 },
        .{ .label = "width", .size = 640, .stride = 3 * 640 },
        .{ .label = "channel", .size = 3, .stride = 3 },
    };
    msg.m.dim = dim[0..];
    msg.m.data_offset = 420;

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.dim.data[0].size, 480);
    try testing.expectEqual(msg_c.dim.data[0].stride, 3 * 640 * 480);
    try testing.expectEqual(msg_c.dim.data[1].size, 640);
    try testing.expectEqual(msg_c.dim.data[1].stride, 3 * 640);
    try testing.expectEqual(msg_c.dim.data[2].size, 3);
    try testing.expectEqual(msg_c.dim.data[2].stride, 3);
    try testing.expectEqual(msg_c.data_offset, 420);
}

test "test_UInt8MultiArray" {
    var msg = RosMessage("std_msgs", "UInt8MultiArray"){};

    var dim: [3]@typeInfo(@TypeOf(msg.m.layout.dim)).pointer.child = .{
        .{ .label = "height", .size = 480, .stride = 3 * 640 * 480 },
        .{ .label = "width", .size = 640, .stride = 3 * 640 },
        .{ .label = "channel", .size = 3, .stride = 3 },
    };
    msg.m.layout = .{
        .dim = &dim,
        .data_offset = 0,
    };
    msg.m.data = &[_]u8{ 1, 2, 3, 4, 5 };

    var msg_c = try msg.to_c();
    defer msg.free_c(&msg_c);

    try testing.expectEqual(msg_c.layout.dim.data[0].size, 480);
    try testing.expectEqual(msg_c.layout.dim.data[0].stride, 3 * 640 * 480);
    try testing.expectEqual(msg_c.layout.dim.data[1].size, 640);
    try testing.expectEqual(msg_c.layout.dim.data[1].stride, 3 * 640);
    try testing.expectEqual(msg_c.layout.dim.data[2].size, 3);
    try testing.expectEqual(msg_c.layout.dim.data[2].stride, 3);
    try testing.expectEqual(msg_c.layout.data_offset, 0);

    const data: *[5]u8 = @constCast(@ptrCast(msg.m.data));
    try testing.expect(std.mem.eql(u8, data, &[_]u8{ 1, 2, 3, 4, 5 }));
    try testing.expectEqual(msg_c.data.size, 5);
    try testing.expectEqual(msg_c.data.capacity, 5);
}
