pub const rcl_c = @cImport({
    @cInclude("rcl/rcl.h");
    @cInclude("rcl/logging.h");
    @cInclude("rcl/logging_rosout.h");
    @cInclude("rcl/subscription.h");
    @cInclude("rcutils/logging_macros.h");
    @cInclude("rmw/qos_policy_kind.h");
    @cInclude("rmw/qos_string_conversions.h");

    @cInclude("rosidl_runtime_c/message_type_support_struct.h");
    @cInclude("std_msgs/msg/string.h");
    @cInclude("std_msgs/msg/int32.h");
});
