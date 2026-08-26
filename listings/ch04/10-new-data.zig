//! Listing 4.10 New data

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const ally = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdin_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    var stdin_reader = std.fs.File.stdin().reader(io, &stdin_buffer);
    const stdout = &stdout_writer.interface;
    const stdin = &stdin_reader.interface;
    _ = stdin;

    var seed: u64 = undefined;
    io.random(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    const start_index =
        random.intRangeLessThan(usize, 0, words.len);
    const start = words[start_index];

    var ladder = std.ArrayList([4]u8).empty;
    defer ladder.deinit(ally);

    try ladder.append(ally, start);

    try stdout.print("Let's make a word ladder! Say `end` to exit.\n", .{});
    try stdout.flush();

    // Game loop ...
}
