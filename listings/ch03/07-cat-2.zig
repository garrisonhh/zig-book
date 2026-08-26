//! Listing 3.7 Cat with arguments and more files

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena); // (1) Acquiring cli args in a cross-platform manner.
    const cwd = std.Io.Dir.cwd();

    const stdout_file = std.Io.File.stdout();
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = stdout_file.writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (args[1..]) |filepath| { // (2) Looping over the filepaths.
        const text = try cwd.readFileAlloc(
            io,
            filepath,
            arena,
            .unlimited,
        );
        try stdout.writeAll(text);
    }

    try stdout.flush(); // (3) Flush at the end!
}
