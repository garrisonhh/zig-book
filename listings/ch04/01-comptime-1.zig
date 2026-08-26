//! Listing 4.1 Counting the dictionary words

const std = @import("std");

fn countWordlist(text: []const u8) usize {
    var count: usize = 0;
    var word_iter = std.mem.tokenizeScalar(u8, text, '\n');
    while (word_iter.next()) |_| {
        count += 1;
    }

    return count;
}

test "countWordlist" {
    try std.testing.expectEqual(1, countWordlist("hello"));
    try std.testing.expectEqual(1, countWordlist("hello\n"));
    try std.testing.expectEqual(2, countWordlist("hello\nworld\n"));
    try std.testing.expectEqual(0, countWordlist(""));
    try std.testing.expectEqual(0, countWordlist("\n\n\n"));
    try std.testing.expectEqual(3, countWordlist("bing\nbong\nboom"));
}
