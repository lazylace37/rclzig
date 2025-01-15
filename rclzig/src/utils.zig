const std = @import("std");
const testing = std.testing;

pub fn contains(comptime T: type, array: []const T, value: T) bool {
    for (array) |item| {
        if (item == value) {
            return true;
        }
    }
    return false;
}

/// This is used to convert a package + message name to the corresponding generated .h header file.
/// This is the equivalent to https://github.com/ros2/rosidl/blob/bf5682e4747843d1d5133b9a2b54ce6f12f166c7/rosidl_pycommon/rosidl_pycommon/__init__.py#L35
pub fn convert_camel_case_to_lower_case_underscore(comptime value: []const u8) []const u8 {
    comptime {
        var n_uppercase_letters: u8 = 0;
        var i = 0;
        while (i < value.len - 1) {
            if (i > 0 and i < value.len - 1) {
                if (std.ascii.isUpper(value[i]) and std.ascii.isLower(value[i + 1])) {
                    n_uppercase_letters += 1;
                } else if (std.ascii.isLower(value[i]) and std.ascii.isUpper(value[i + 1])) {
                    n_uppercase_letters += 1;
                    i += 1;
                }
            }

            i += 1;
        }
        var result: [value.len + n_uppercase_letters]u8 = undefined;

        i = 0;
        var j = 0;
        while (i < value.len) {
            if (i > 0 and i < value.len - 1) {
                if (std.ascii.isUpper(value[i]) and std.ascii.isLower(value[i + 1])) {
                    // result[j] = "_"; // I can't do this I don't know why
                    result[j] = 95; // 95 is '_'
                    j += 1;

                    result[j] = std.ascii.toLower(value[i]);
                    j += 1;
                } else if (std.ascii.isLower(value[i]) and std.ascii.isUpper(value[i + 1])) {
                    result[j] = std.ascii.toLower(value[i]);
                    j += 1;

                    // result[j] = "_"; // I can't do this I don't know why
                    result[j] = 95; // 95 is '_'
                    j += 1;

                    i += 1;
                    result[j] = std.ascii.toLower(value[i]);
                    j += 1;
                } else {
                    result[j] = std.ascii.toLower(value[i]);
                    j += 1;
                }
            } else {
                result[j] = std.ascii.toLower(value[i]);
                j += 1;
            }

            i += 1;
        }

        // https://github.com/pseudocc/pal/issues/1
        const res = result[0..result.len].*;
        return &res;
    }
}

test "convert_camel_case_to_lower_case_underscore_int32_multi_array" {
    const res = comptime convert_camel_case_to_lower_case_underscore("Int32MultiArray");
    try testing.expectEqualStrings("int32_multi_array", res);
}

test "convert_camel_case_to_lower_case_underscore_color_rgba" {
    const res = comptime convert_camel_case_to_lower_case_underscore("ColorRGBA");
    try testing.expectEqualStrings("color_rgba", res);
}
