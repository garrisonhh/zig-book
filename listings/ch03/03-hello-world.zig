//! Listing 3.3 Hello world, in context

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const stdout_file = std.Io.File.stdout(); // (1) Acquiring a file handle.
    var stdout_buffer: [1024]u8 = undefined; // (2) An uninitialized array that the writer will use as a buffer.
    var stdout_writer = stdout_file.writer(io, &stdout_buffer); // (3) Creating a std.Io.File.Writer with the buffer.
    const stdout = &stdout_writer.interface; // (4) Referencing a the file writer’s std.Io.Writer interface.

    try stdout.writeAll("All your codebase belong to us yet again!"); // (5) Writing data into the writer.
    try stdout.flush(); // (6) Flushing the buffer.
}
