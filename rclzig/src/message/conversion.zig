const std = @import("std");
const testing = std.testing;
const rcl_c = @import("../rcl.zig").rcl_c;
const RosMessage = @import("../message.zig").RosMessage;
const convert_camel_case_to_lower_case_underscore = @import("../utils.zig").convert_camel_case_to_lower_case_underscore;
const c_cast = @import("std").zig.c_translation.cast;

pub fn ros_msg_to_c(comptime c: type, comptime RosMessageT: type, comptime RosMessageC: type, msg: RosMessageT, msg_c: *RosMessageC) void {
    inline for (std.meta.fields(RosMessageC)) |field_c| {
        switch (field_c.type) {
            bool, f32, f64, i8, u8, i16, u16, i32, u32, i64, u64 => {
                const field = @field(msg, field_c.name);
                const field_type = @TypeOf(field);

                if (field_type != field_c.type) @compileError("Types don't match");
                @field(msg_c, field_c.name) = field;
            },
            c.rosidl_runtime_c__String => { // The String type is uniquely handled
                const field = @field(msg, field_c.name);
                const field_type = @TypeOf(field);
                if (field_type != []const u8) @compileError("[ros_msg_to_c] converting to cString but didn't find a []const u8");

                const msg_val: []const u8 = field;

                const allocator = c.rcutils_get_default_allocator();
                const allocate = allocator.allocate.?;

                const str_data_ptr = allocate(msg_val.len + 1, allocator.state);
                const str_data_c_ptr = c_cast([*c]u8, str_data_ptr);
                var str: c.rosidl_runtime_c__String = .{
                    .data = str_data_c_ptr,
                    .size = msg_val.len,
                    .capacity = msg_val.len + 1,
                };

                _ = c.memcpy(str.data, msg_val.ptr, msg_val.len);
                str.data[msg_val.len] = 0;

                @field(msg_c, field_c.name) = str;
            },
            c.rosidl_runtime_c__float__Sequence,
            c.rosidl_runtime_c__double__Sequence,
            c.rosidl_runtime_c__long_double__Sequence,
            c.rosidl_runtime_c__char__Sequence,
            c.rosidl_runtime_c__wchar__Sequence,
            c.rosidl_runtime_c__boolean__Sequence,
            c.rosidl_runtime_c__octet__Sequence,
            c.rosidl_runtime_c__uint8__Sequence,
            c.rosidl_runtime_c__int8__Sequence,
            c.rosidl_runtime_c__uint16__Sequence,
            c.rosidl_runtime_c__int16__Sequence,
            c.rosidl_runtime_c__uint32__Sequence,
            c.rosidl_runtime_c__int32__Sequence,
            c.rosidl_runtime_c__uint64__Sequence,
            c.rosidl_runtime_c__int64__Sequence,
            => {
                const fields = @field(msg, field_c.name);

                const sub_msg_c_T = @typeInfo(@typeInfo(field_c.type).@"struct".fields[0].type).pointer.child;

                const allocator = c.rcutils_get_default_allocator();
                const zero_allocate = allocator.zero_allocate.?;

                const seq_data_ptr = zero_allocate(fields.len, @sizeOf(sub_msg_c_T), allocator.state);
                const seq_data_c_ptr = c_cast([*c]sub_msg_c_T, seq_data_ptr);
                const seq: field_c.type = .{
                    .data = seq_data_c_ptr,
                    .size = fields.len,
                    .capacity = fields.len,
                };

                for (fields, 0..) |sub_msg, i| {
                    const sub_msg_c_ptr = seq_data_c_ptr + i;
                    sub_msg_c_ptr.* = sub_msg;
                }
                @field(msg_c, field_c.name) = seq;
            },
            else => {
                const type_name = @typeName(field_c.type);
                if (comptime (std.mem.endsWith(u8, type_name, "__Sequence"))) {
                    const fields = @field(msg, field_c.name);
                    const field_type = @TypeOf(fields);
                    const sub_msg_T = @typeInfo(field_type).pointer.child;

                    const sub_msg_c_T = @typeInfo(@typeInfo(field_c.type).@"struct".fields[0].type).pointer.child;

                    const allocator = c.rcutils_get_default_allocator();
                    const zero_allocate = allocator.zero_allocate.?;

                    const seq_data_ptr = zero_allocate(fields.len, @sizeOf(sub_msg_c_T), allocator.state);
                    const seq_data_c_ptr = c_cast([*c]sub_msg_c_T, seq_data_ptr);
                    const seq: field_c.type = .{
                        .data = seq_data_c_ptr,
                        .size = fields.len,
                        .capacity = fields.len,
                    };

                    for (fields, 0..) |sub_msg, i| { // field = MultiArrayDimension
                        const sub_msg_c_ptr = seq_data_c_ptr + i;
                        ros_msg_to_c(c, sub_msg_T, sub_msg_c_T, sub_msg, sub_msg_c_ptr);
                    }
                    @field(msg_c, field_c.name) = seq;
                } else {
                    const sub_msg_T = @TypeOf(@field(msg, field_c.name));
                    const sub_msg = @field(msg, field_c.name);
                    const sub_msg_c_T = @TypeOf(@field(msg_c, field_c.name));
                    const sub_msg_c = &@field(msg_c, field_c.name);

                    ros_msg_to_c(c, sub_msg_T, sub_msg_c_T, sub_msg, sub_msg_c);
                }
            },
        }
    }
}
