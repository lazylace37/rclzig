const std = @import("std");
const testing = std.testing;
const rcl_c = @import("rcl.zig").rcl_c;
const convert_camel_case_to_lower_case_underscore = @import("utils.zig").convert_camel_case_to_lower_case_underscore;

fn get_msg_typesupport_handle(comptime package: []const u8, comptime name: []const u8) fn () callconv(.c) [*c]const rcl_c.rosidl_message_type_support_t {
    const field_name = "rosidl_typesupport_c" ++ "__" ++ "get_message_type_support_handle" ++ "__" ++ package ++ "__msg__" ++ name;
    const get_type_support_func = @field(rcl_c, field_name);
    return get_type_support_func;
}

const GenerateMessageError = error{UnsupportedType};

fn gen_msg_type(comptime package: []const u8, comptime name: []const u8) GenerateMessageError!type {
    comptime {
        const header_file_name = package ++ "/" ++ "msg" ++ "/" ++ convert_camel_case_to_lower_case_underscore(name) ++ ".h";
        const msg_header = @cImport({
            @cInclude(header_file_name);
        });

        const msg_struct_name = package ++ "__" ++ "msg" ++ "__" ++ name;
        const msg_struct = @field(msg_header, msg_struct_name);

        const msg_struct_fields = std.meta.fields(msg_struct);
        var fields: [msg_struct_fields.len]std.builtin.Type.StructField = undefined;

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
                msg_header.rosidl_runtime_c__String => {
                    fields[i] = .{
                        .name = f.name,
                        // .type = [*c]const u8,
                        .type = []const u8,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                },
                else => return GenerateMessageError.UnsupportedType,
            }
        }

        const Type = @Type(.{
            .@"struct" = .{
                // .layout = .@"extern",
                .layout = .auto,
                .fields = fields[0..],
                .decls = &[_]std.builtin.Type.Declaration{},
                .is_tuple = false,
            },
        });
        return Type;
    }
}

const RosMessageError = error{MessageInit};
pub fn RosMessage(comptime package: []const u8, comptime name: []const u8) type {
    const header_file_name = package ++ "/" ++ "msg" ++ "/" ++ convert_camel_case_to_lower_case_underscore(name) ++ ".h";
    const msg_header = @cImport({
        @cInclude(header_file_name);
    });

    const msg_struct_name = package ++ "__" ++ "msg" ++ "__" ++ name;
    const msg_struct = @field(msg_header, msg_struct_name);

    const msg_init_func = @field(msg_header, msg_struct_name ++ "__init");
    const msg_fini_func = @field(msg_header, msg_struct_name ++ "__fini");

    const wrapper_msg_type: type = try gen_msg_type(package, name);

    return struct {
        var c_type: msg_struct = .{};
        pub const ros_package_name = package;
        pub const ros_message_name = name;

        const Self = @This();

        m: wrapper_msg_type = std.mem.zeroInit(wrapper_msg_type, .{}),

        pub fn init() RosMessageError!Self {
            if (!msg_init_func(&c_type)) return RosMessageError.MessageInit;
            return .{};
        }

        pub fn fini(self: *const Self) void {
            _ = self;
            msg_fini_func(&c_type);
        }
    };
}

test "test_int32" {
    const StringMessage = RosMessage("std_msgs", "Int32");

    var str_msg = try StringMessage.init();
    defer str_msg.fini();

    str_msg.m.data = 7;
    try testing.expect(@TypeOf(str_msg.m.data) == i32);
    try testing.expectEqual(str_msg.m.data, 7);
}

test "test_string" {
    const StringMessage = RosMessage("std_msgs", "String");

    var str_msg = try StringMessage.init();
    defer str_msg.fini();

    str_msg.m.data = "my string";
    try testing.expect(@TypeOf(str_msg.m.data) == []const u8);
    try testing.expectEqual(str_msg.m.data, "my string");
}
