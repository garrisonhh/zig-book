//! Listing 2.11 Slices

const std = @import("std");

pub fn main() void {
    const arr = [_]i32{ 11, 22, 33, 44, 55 };
    const range: []const i32 = arr[1..4]; // (1) From index 1 up to index 4!

    std.debug.print("range: {any}\n", .{range});
}
