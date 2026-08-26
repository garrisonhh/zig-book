const std = @import("std");

fn countWordlist(text: []const u8) usize {
    @setEvalBranchQuota(1_000_000);
    var count: usize = 0;
    var word_iter = std.mem.tokenizeScalar(u8, text, '\n');
    while (word_iter.next()) |_| {
        count += 1;
    }

    return count;
}

fn parseWordlist(comptime wordlist: []const u8) [countWordlist(wordlist)][4]u8 {
    var list: [countWordlist(wordlist)][4]u8 = undefined;
    var i: usize = 0;

    var word_iter = std.mem.tokenizeScalar(u8, wordlist, '\n');
    while (word_iter.next()) |word| : (i += 1) {
        list[i] = @as(*const [word.len]u8, @ptrCast(word.ptr)).*;
    }

    return list;
}

const words = parseWordlist(@embedFile("words.txt"));

fn diff(word_a: [4]u8, word_b: [4]u8) u32 {
    var count: u32 = 0;
    for (word_a, word_b) |a, b| {
        if (a != b) {
            count += 1;
        }
    }

    return count;
}

const InvalidWordError = error{
    BadLength,
    NotInWordlist,
    NotWordLadder,
};

fn validateWord(input: []const u8, last_word: [4]u8) InvalidWordError![4]u8 {
    if (input.len != 4) {
        return error.BadLength;
    }

    const word = @as(*const [4]u8, @ptrCast(input.ptr)).*;

    for (words) |wordlist_word| {
        if (std.mem.eql(u8, &wordlist_word, &word)) {
            break;
        }
    } else {
        return error.NotInWordlist;
    }

    if (diff(last_word, word) != 1) {
        return error.NotWordLadder;
    }

    return word;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const ally = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdin_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    var stdin_reader = std.Io.File.stdin().reader(io, &stdin_buffer);
    const stdout = &stdout_writer.interface;
    const stdin = &stdin_reader.interface;

    var seed: u64 = undefined;
    io.random(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    const start_index =
        random.intRangeLessThan(usize, 0, words.len);
    const start = words[start_index];

    var ladder = std.ArrayList([4]u8).empty;
    defer ladder.deinit(ally);

    try ladder.append(ally, start);

    try stdout.print("Let's make a word ladder! Say `end` to exit.\n", .{});
    try stdout.flush();

    while (true) {
        try stdout.print(
            "The ladder is {d} words long. The last word was {s}.\n",
            .{ ladder.items.len, ladder.getLast() },
        );
        try stdout.print("> ", .{});
        try stdout.flush();

        const input = try stdin.takeDelimiter('\n') orelse &.{};

        if (std.mem.eql(u8, input, "end")) {
            try stdout.print("Bye bye!\n", .{});
            break;
        }

        const word = validateWord(input, ladder.getLast()) catch |e| {
            const msg: []const u8 = switch (e) {
                error.BadLength => "Hey, that's not four characters!",
                error.NotInWordlist => "I don't think that's a word.",
                error.NotWordLadder => "That doesn't make a word ladder.",
            };

            try stdout.print("{s}\n", .{msg});

            continue;
        };
        try ladder.append(ally, word);
    }

    try stdout.flush();
}
