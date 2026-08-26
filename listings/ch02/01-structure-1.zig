//! Listing 2.1 A simple program

const std = @import("std"); // (1) std is what we call the Zig standard library.

pub fn main() void { // (2) Our main function.
    const x: i32 = 42; // (3) Setting x to the value 42.
    std.debug.print("{}\n", .{x}); // (4) Printing x to stderr.
}