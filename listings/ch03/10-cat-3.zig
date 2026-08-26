//! Listing 3.10 Cat errors

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena); // (1) Cat can’t work without accessing the process arguments.
    const cwd = std.Io.Dir.cwd();

    const stdout_file = std.Io.File.stdout();
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = stdout_file.writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (args[1..]) |filepath| {
        const text = try cwd.readFileAlloc(
            io,
            filepath,
            arena,
            .unlimited,
        ); // (2) How would this fail, and should it fail here?
        try stdout.writeAll(text); // (3) Writes to stdout.
    }

    try stdout.flush(); // (4) May write to stdout.
}
