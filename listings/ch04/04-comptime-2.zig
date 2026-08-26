//! Listing 4.4 Parsing the wordlist into an array

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
