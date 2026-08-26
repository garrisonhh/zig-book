const std = @import("std");

fn countWordlist(text: []const u8) usize {
    var count: usize = 0;
    var word_iter = std.mem.tokenizeScalar(u8, text, '\n');
    while (word_iter.next()) |_| {
        count += 1;
    }

    return count;
}

fn parseWordlist(
    comptime wordlist: []const u8,
) [countWordlist(wordlist)][4]u8 {
    var list: [countWordlist(wordlist)][4]u8 = undefined;
    var i: usize = 0;

    var word_iter = std.mem.tokenizeScalar(u8, wordlist, '\n');
    while (word_iter.next()) |word| : (i += 1) {
        if (word.len != 4) {
            @compileError(std.fmt.comptimePrint(
                "the word '{s}' is not four characters long.",
                .{word},
            ));
        }
        list[i] = word[0..4].*;
    }

    return list;
}

const words = blk: {
    @setEvalBranchQuota(1_000_000);
    break :blk parseWordlist(@embedFile("words.txt"));
};

fn validateWord(input: []const u8, last_word: [4]u8) ![4]u8 {
    if (input.len != 4) {
        return error.BadLength;
    }

    const word = input[0..4].*;

    for (words) |wordlist_word| {
        if (std.mem.eql(u8, &wordlist_word, &word)) {
            break;
        }
    } else {
        return error.NotInWordlist;
    }

    var difference: u32 = 0;
    for (word, last_word) |a, b| {
        if (a != b) {
            difference += 1;
        }
    }

    if (difference != 1) {
        return error.NotWordLadder;
    }

    return word;
}

fn validateLadder(ladder: []const u8) !void {
    var word_iter = std.mem.tokenizeScalar(u8, ladder, '\n');

    const first_word = word_iter.next() orelse {
        return error.EmptyLadder;
    };
    if (first_word.len != 4) return error.BadLength;

    var last_word: [4]u8 = first_word[0..4].*;
    while (word_iter.next()) |raw_word| {
        const word =
            try validateWord(raw_word, last_word);
        last_word = word;
    }
}

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

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var seed: u64 = undefined;
    io.random(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

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

        handleConnection(io, random, stream) catch |e| {
            std.log.err("handleConnection: {}", .{e});
        };
    }
}
