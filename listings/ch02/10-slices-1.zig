//! Listing 2.10 Slices

const std = @import("std");

pub fn main() void {
    const arr = [_]i32{ 11, 22, 33, 44, 55 };    // (1) An array.
    const slice: []const i32 = &arr;    // (2) A slice that references the array.
    const x = slice[2];    // (3) Accessing an element of the slice.

    std.debug.print("slice: {any}, x: {}\n", .{slice, x});
    std.debug.print("ptr: {*}, len: {}\n", .{slice.ptr, slice.len});
}