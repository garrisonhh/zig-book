//! Listing 4.2 Comptime type parameters for fun and profit

pub fn tokenizeScalar(
    comptime T: type, 
    buffer: []const T, 
    delimiter: T, 
) TokenIterator(T, .scalar) 