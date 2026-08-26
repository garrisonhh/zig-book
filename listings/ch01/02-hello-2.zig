//! Listing 1.2 All your codebase still belong to us

const std = @import("std");

pub fn main(init: std.process.Init) !void { // (1)
    const io = init.io;

    const stdout = std.Io.File.stdout(); // (2)
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = stdout.writer(io, &stdout_buffer); // (3)
    const writer = &stdout_writer.interface; // (4)

    try writer.print("All your codebase still belong to us!\n", .{}); // (5)
    try writer.flush(); // (6)
}