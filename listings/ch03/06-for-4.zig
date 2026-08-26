//! Listing 3.6 Finding the index of a value

const std = @import("std");

fn indexOf(items: []const i32, value: i32) error{NotFound}!usize {
    return for (items, 0..) |item, i| { // (1) Looping through items, with an index.
        if (item == value) {
            break i; // (2) Using break to return a value.
        }
    } else error.NotFound; // (3) If an item isn’t found, return an error.
}

test {
    try std.testing.expectEqual(0, indexOf(&.{ 42, 56, 60 }, 42));
    try std.testing.expectEqual(1, indexOf(&.{ 42, 56, 60 }, 56));
    try std.testing.expectEqual(2, indexOf(&.{ 42, 56, 60 }, 60));
    try std.testing.expectError(error.NotFound, indexOf(&.{ 42, 56, 60 }, 72));
}
