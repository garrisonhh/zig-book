//! Listing 3.16 Using the buffering option

const std = @import("std");
const options = @import("options"); // (1) Importing the options module.

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    const cwd = std.Io.Dir.cwd();

    var stdout_buffer: [options.writer_buffer_size]u8 = // (2) Stdout will use the writer buffer size.
        undefined;
    var stderr_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    const stdout = &stdout_writer.interface;
    const stderr = &stderr_writer.interface;

    for (args[1..]) |filepath| {
        const file = cwd.openFile(io, filepath, .{}) catch {
            stderr.print("could not open: {s}\n", .{filepath}) catch {};
            stderr.flush() catch {};
            continue;
        };
        defer file.close(io);

        var file_buffer: [options.reader_buffer_size]u8 = undefined;
        var file_reader = file.reader(io, &file_buffer);
        const reader = &file_reader.interface; // (3) File reader uses the reader buffer size.

        _ = try reader.streamRemaining(stdout);
    }

    try stdout.flush();
}