//! Listing 4.13 Echo but web worthy

const std = @import("std");

fn handleConnection(io: std.Io, stream: std.Io.net.Stream) !void {
    var stream_reader_buf: [1024]u8 = undefined;
    var stream_writer_buf: [1024]u8 = undefined;
    var stream_reader = stream.reader(io, &stream_reader_buf);
    var stream_writer = stream.writer(io, &stream_writer_buf);

    var http_server = std.http.Server.init( 
        &stream_reader.interface,
        &stream_writer.interface,
    );

    var request = try http_server.receiveHead(); 
    if (request.head.method != .POST) { 
        request.respond("", .{ .status = .bad_request }) catch {};
        return error.BadRequest;
    }

    errdefer request.respond("", .{ 
        .status = .internal_server_error,
    }) catch {};

    var reader_buf: [1024]u8 = undefined;
    const reader =
        try request.readerExpectContinue(&reader_buf); 

    const text = try reader.takeDelimiterExclusive(0); 

    var body_writer_buf: [1024]u8 = undefined;
    var body_writer = try request.respondStreaming(&body_writer_buf, .{});
    const body = &body_writer.writer; 

    try body.print("You said: {s}\n", .{text});
    try body.flush();

    try body_writer.end(); 
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const addr = try std.Io.net.IpAddress.parse(
        "127.0.0.1",
        8000,
    );
    var tcp_server = try addr.listen(io, .{ .reuse_address = true });
    defer tcp_server.deinit(io);

    serve: while (true) {
        const stream = tcp_server.accept(io) catch |e| {
            std.log.err("accept: {}", .{e});
            continue :serve;
        };
        defer stream.close(io);

        handleConnection(io, stream) catch |e| { 
            std.log.err("handleConnection: {}", .{e});
        };
    }
}