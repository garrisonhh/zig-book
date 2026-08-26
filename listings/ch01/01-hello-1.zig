//! Listing 1.1 All your codebase are belong to us

const std = @import("std"); // (1)

pub fn main() void { // (2)
    std.debug.print("All your codebase are belong to us!\n", .{}); // (3)
}
