//! Listing 2.9 Arrays

const std = @import("std");

pub fn main() void {
    const arr = [3]i32{ 1, 2, 3 }; // (1) Declaring and initializing an array.
    var arr_copy = arr; // (2) Copying an array, just like any value.
    arr_copy[2] = 5; // (3) Mutating the copy.

    std.debug.print("arr:      {any}\n", .{arr});
    std.debug.print("arr_copy: {any}\n", .{arr_copy}); // (4) Printing our arrays.
}