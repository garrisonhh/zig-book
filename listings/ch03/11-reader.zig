//! Listing 3.11 Nuclear-grade cat with streaming

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    const cwd = std.Io.Dir.cwd();

    const stdout_file = std.Io.File.stdout();
    const stderr_file = std.Io.File.stderr();
    var stdout_buffer: [1024]u8 = undefined;
    var stderr_buffer: [1024]u8 = undefined;
    var stdout_writer = stdout_file.writer(io, &stdout_buffer);
    var stderr_writer = stderr_file.writer(io, &stderr_buffer);
    const stdout = &stdout_writer.interface;
    const stderr = &stderr_writer.interface; // (1) We need stderr now too.

    for (args[1..]) |filepath| {
        const file = cwd.openFile(io, filepath, .{}) catch {
            stderr.print( // (2) If we can’t open the file, print a helpful message.
                "could not open: {s}\n",
                .{filepath},
            ) catch {}; // (3) If this fails, there’s nothing to do about it.
            stderr.flush() catch {};
            continue;
        };
        defer file.close(io); // (4) Managing a resource with defer.

        var file_buffer: [1024]u8 = undefined;
        var file_reader = file.reader(io, &file_buffer);
        const reader = &file_reader.interface; // (5) A reader for the file.

        _ = try reader.streamRemaining(stdout); // (6) Stream from reader to writer.
    }

    try stdout.flush();
}
