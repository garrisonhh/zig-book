//! Listing 2.13 What’s the type of a string literal?

const std = @import("std");

pub fn main() void {
    const T = @TypeOf("I am a string literal"); // (1) T will have the type type.
    std.debug.print("{}\n", .{T}); // (2) Types can be printed like any other value.
}