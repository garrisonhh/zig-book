//! Listing 2.3 fibonacci.zig

const std = @import("std");

pub fn fibonacci(n: usize) i32 { // (1) The fibonacci function, made available for import.
    if (n == 0) {
        return 0;
    } else if (n == 1) {
        return 1;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "fibonacci" {
    try std.testing.expectEqual(0, fibonacci(0));
    try std.testing.expectEqual(1, fibonacci(1));
    try std.testing.expectEqual(1, fibonacci(2));
    try std.testing.expectEqual(2, fibonacci(3));
    try std.testing.expectEqual(3, fibonacci(4));
    try std.testing.expectEqual(5, fibonacci(5));
    try std.testing.expectEqual(8, fibonacci(6));
    try std.testing.expectEqual(13, fibonacci(7));
    try std.testing.expectEqual(21, fibonacci(8));
}
