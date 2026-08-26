//! Listing 3.2 Fibonacci but checked

const std = @import("std");

const FibonacciError = error{OverFibonacciLimit};

const fibonacci_limit = 30;

fn fibonacci(n: usize) FibonacciError!i32 { // (1) This function can either return a FibonacciError or an i32
    if (n == 0) {
        return 0;
    } else if (n == 1) {
        return 1;
    } else if (n > fibonacci_limit) {
        return error.OverFibonacciLimit; // (2) Errors are returned just like any other value.
    }
    return try fibonacci(n - 1) + try fibonacci(n - 2); // (3) Try is a way to unwrap error unions, which we’ll explore momentarily.
}

test "fibonacci" {
    try std.testing.expectError(error.OverFibonacciLimit, fibonacci(31));
    try std.testing.expectError(error.OverFibonacciLimit, fibonacci(3005));
    try std.testing.expectEqual(0, fibonacci(0));
    try std.testing.expectEqual(1, fibonacci(1));
    try std.testing.expectEqual(1, fibonacci(2));
    try std.testing.expectEqual(2, fibonacci(3));
    try std.testing.expectEqual(3, fibonacci(4));
    try std.testing.expectEqual(5, fibonacci(5));
    try std.testing.expectEqual(8, fibonacci(6));
    try std.testing.expectEqual(13, fibonacci(7));
    try std.testing.expectEqual(21, fibonacci(8));
}
