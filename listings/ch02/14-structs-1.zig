//! Listing 2.14 Declaring, instantiating, and using a struct

const std = @import("std");

const Point = struct { // (1) Declaring a struct.
    x: i32,
    y: i32,
};

pub fn main() void {
    const a: Point = .{ .x = 3, .y = -1 }; // (2) Instantiating the struct.
    std.debug.print("x = {}, y = {}\n", .{a.x, a.y}); // (3) Accessing struct fields.
}