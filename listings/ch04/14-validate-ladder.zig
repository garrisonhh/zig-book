//! Listing 4.14 Validate ladder

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
