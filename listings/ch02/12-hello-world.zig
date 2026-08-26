//! Listing 2.12 Hello world, with buffers explained

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const stdout_file = std.Io.File.stdout();
    var stdout_buffer: [1024]u8 = undefined; // (1) Creating a buffer.
    var stdout_writer = stdout_file.writer(io, &stdout_buffer); // (2) The writer will use the buffer for any future operations.
    const stdout = &stdout_writer.interface;

    try stdout.print("All your codebase still belong to us!\n", .{}); // (3) Writes data to the buffer.
    try stdout.flush(); // (4) "Empties" the buffer by actually writing all of the stored data to stdout!
}