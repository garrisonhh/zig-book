//! Listing 2.4 main.zig

const std = @import("std");
const fibonacci = @import("03-fibonacci-2.zig").fibonacci; // (1) Importing the fibonacci function.

pub fn main() void {
    const first = fibonacci(1);
    const second = fibonacci(2);
    const third = fibonacci(3);
    const fourth = fibonacci(4);
    std.debug.print("{} {} {} {}\n", .{ first, second, third, fourth });
}
