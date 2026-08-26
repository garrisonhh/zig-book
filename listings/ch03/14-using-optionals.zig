//! Listing 3.14 Using optionals

const std = @import("std");

// from 13-optionals
fn indexOf(items: []const i32, value: i32) ?usize {
    return for (items, 0..) |item, i| {
        if (item == value) {
            break i;
        }
    } else null;
}

pub fn main() !void {
    const numbers = [_]i32{ 45, 23, 64 };

    if (indexOf(&numbers, 35)) |index_of_35| { // (1) If statement with a capture group
        std.debug.print("index of 35: {}\n", .{index_of_35});
    } else {
        std.debug.print("35 not found.\n", .{});
    }

    const index_of_64 = indexOf(&numbers, 64).?; // (2) Asserting that null won’t happen!
    std.debug.print("index of 64: {}\n", .{index_of_64});

    const index_of_23 = indexOf(&numbers, 23) orelse { // (3) Acts just like catch.
        return error.TwentyNotFound;
    };
    std.debug.print("index of 23: {}\n", .{index_of_23});
}
