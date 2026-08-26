//! Listing 3.5 Taking stock of our produce

const produce = [_][]const u8{ "carrots", "peas", "dragonfruit", "avocados" };
const counts = [_]i32{ 32, 96, 7, 0 };

for (0..produce.len) |i| {
    const name = produce[i];
    const count = counts[i];
    std.debug.print("{s}: {}\n", .{name, count});
}