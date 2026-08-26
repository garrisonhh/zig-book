//! Listing 4.11 Switch

pub fn main() !void {
    // Initialization code ...

    while (true) {
        try stdout.print( 
            "The ladder is {d} words long. The last word was {s}.\n",
            .{ladder.items.len, ladder.getLast()},
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