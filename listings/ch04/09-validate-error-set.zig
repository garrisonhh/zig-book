//! Listing 4.9 Invalid word errors

const InvalidWordError = error {
    BadLength,
    NotInWordlist,
    NotWordLadder,
};

fn validateWord(
    input: []const u8,
    last_word: [4]u8,
) InvalidWordError![4]u8 { 
    // validation code ...
}