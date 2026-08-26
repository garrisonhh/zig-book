//! Listing 3.9 Collatz convenience

const std = @import("std");

fn collatzIterations(start: usize) usize {
    var count: usize = 0;
    var n = start;
    while (n != 1) : (count += 1) { // (1) Looping with an effect!
        if (n % 2 == 0) {
            n = @divExact(n, 2);
        } else {
            n = 3 * n + 1;
        }
    }

    return count;
}

test {
    try std.testing.expectEqual(0, collatzIterations(1));
    try std.testing.expectEqual(16, collatzIterations(7));
    try std.testing.expectEqual(17, collatzIterations(15));
    try std.testing.expectEqual(184, collatzIterations(9_663));
    try std.testing.expectEqual(307, collatzIterations(26_623));
}
