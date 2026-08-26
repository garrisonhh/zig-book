//! Listing 3.13 Optional

const std = @import("std");

fn indexOf(items: []const i32, value: i32) ?usize {
    return for (items, 0..) |item, i| {
        if (item == value) {
            break i; // (1) Return the index.
        }
    } else null; // (2) Nothing found!
}

test {
    try std.testing.expectEqual(0, indexOf(&.{ 42, 56, 60 }, 42));
    try std.testing.expectEqual(1, indexOf(&.{ 42, 56, 60 }, 56));
    try std.testing.expectEqual(2, indexOf(&.{ 42, 56, 60 }, 60));
    try std.testing.expectEqual(null, indexOf(&.{ 42, 56, 60 }, 72));
}
