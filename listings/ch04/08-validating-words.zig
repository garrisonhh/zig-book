//! Listing 4.8 Validating words

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
    for (word, last_word) |char_a, char_b| {
        if (char_a != char_b) {
            difference += 1;
        }
    }

    if (difference != 1) {
        return error.NotWordLadder;
    }

    return word;
}
