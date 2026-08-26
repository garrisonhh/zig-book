//! Listing 2.2 Recursive fibonacci

const std = @import("std");

fn fibonacci(n: usize) i32 { // (1) We declare the fibonacci function.
    // (2) Here we define our base cases.
    if (n == 0) {
        return 0;
    } else if (n == 1) {
        return 1;
    }
    return fibonacci(n - 1) + fibonacci(n - 2); // (3) If n isn’t 0 or 1, fibonacci recursively calls itself.
}

pub fn main() void {
    // (4) Usage of our function.
    const first = fibonacci(1);
    const second = fibonacci(2);
    const third = fibonacci(3);
    const fourth = fibonacci(4);
    std.debug.print("{} {} {} {}\n", .{ first, second, third, fourth });
}
