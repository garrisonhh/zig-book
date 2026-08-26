//! Listing 3.1 Our first cat

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const filepath = "meow.txt"; // (1) The relative filepath we are reading.

    const cwd = std.Io.Dir.cwd(); // (2) A handle to the current working directory.
    const text = try cwd.readFileAlloc(io, filepath, arena, .unlimited); // (3) Read all the text!

    const stdout_file = std.Io.File.stdout();
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = stdout_file.writer(io, &stdout_buffer); // (4) We need io to actually write anything.
    const stdout = &stdout_writer.interface; // (5) A generic interface for writing.

    try stdout.writeAll(text);
    try stdout.flush();
}
