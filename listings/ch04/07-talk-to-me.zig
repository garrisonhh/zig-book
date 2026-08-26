//! Listing 4.7 Input and output

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdin_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    var stdin_reader = std.Io.File.stdin().reader(io, &stdin_buffer);
    const stdout = &stdout_writer.interface;
    const stdin = &stdin_reader.interface;

    while (true) {
        try stdout.print("> ", .{});
        try stdout.flush();

        const input =
            try stdin.takeDelimiter('\n') orelse {
                continue;
            };

        if (std.mem.eql(u8, input, "end")) {
            try stdout.print("bye bye!\n", .{});
            break;
        }

        try stdout.print("you said: {s}\n", .{input});
    }

    try stdout.flush();
}
