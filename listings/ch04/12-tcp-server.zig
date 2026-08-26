//! Listing 4.12 TCP echo server

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const addr = try std.Io.net.IpAddress.parse(
        "127.0.0.1",
        8000,
    );

    var tcp_server = try addr.listen(io, .{
        .reuse_address = true,
    });
    defer tcp_server.deinit(io);

    serve: while (true) {
        const stream = tcp_server.accept(io) catch |e| {
            std.log.err("accept: {}", .{e});
            continue :serve;
        };
        defer stream.close(io);

        while (true) {
            var reader_buf: [1024]u8 = undefined;
            var stream_reader = stream.reader(io, &reader_buf);
            const reader = &stream_reader.interface;

            const msg = reader.takeDelimiter('\n') catch |e| {
                std.log.err("read: {}", .{e});
                continue :serve;
            } orelse &.{};

            var writer_buf: [1024]u8 = undefined;
            var stream_writer = stream.writer(io, &writer_buf);
            const writer = &stream_writer.interface;

            writer.print("you said: {s}\n", .{msg}) catch |e| {
                std.log.err("write: {}", .{e});
                continue :serve;
            };
            writer.flush() catch |e| {
                std.log.err("flush: {}", .{e});
                continue :serve;
            };
        }
    }
}
