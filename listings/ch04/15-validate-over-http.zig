//! Listing 4.15 Validate over http

fn handleConnection(
    io: std.Io,
    random: std.Random,
    stream: std.Io.net.Stream,
) !void {
    var stream_reader_buf: [1024]u8 = undefined;
    var stream_writer_buf: [1024]u8 = undefined;
    var stream_reader = stream.reader(io, &stream_reader_buf);
    var stream_writer = stream.writer(io, &stream_writer_buf);

    var http_server = std.http.Server.init(
        &stream_reader.interface,
        &stream_writer.interface,
    );

    var request = try http_server.receiveHead();
    errdefer request.respond("", .{
        .status = .internal_server_error,
    }) catch {};

    if (request.head.method == .GET and
        std.mem.eql(u8, request.head.target, "/"))
    {
        try request.respond(@embedFile("ladder.html"), .{ 
            .extra_headers = &.{
                .{
                    .name = "Content-Type",
                    .value = "text/html", 
                },
            },
        });
    } else if (request.head.method == .GET and
        std.mem.eql(u8, request.head.target, "/first"))
    {
        const start_index = random.intRangeLessThan(usize, 0, words.len);
        const start = words[start_index];
        try request.respond(&start, .{}); 
    } else if (request.head.method == .POST and
        std.mem.eql(u8, request.head.target, "/ladder"))
    {
        var reader_buf: [1024]u8 = undefined;
        const reader = try request.readerExpectContinue(&reader_buf);
        const text = try reader.takeDelimiterExclusive(0);

        validateLadder(text) catch |e| { 
            try request.respond(@errorName(e), .{ 
                .status = .bad_request,
            });
            return;
        };

        try request.respond("", .{}); 
    } else {
        try request.respond("", .{ 
            .status = .not_found,
        });
    }
}
