//! Listing 4.3 Compile-time duck typing

const std = @import("std");

fn sum(comptime T: type, values: []const T) T {
    var total: T = 0;
    for (values) |value| {
        total += value;
    }
    return total;
}

pub fn main() void {
    const result = sum(i32, &.{1, 2, 3});
    std.debug.print("sum: {}\n", .{result});
}