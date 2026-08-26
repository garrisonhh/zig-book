//! Listing 2.6 Single-item pointers

const std = @import("std");

pub fn main() void {
    var x: i32 = 123; // (1) x is a var because we’re going to mutate it.
    std.debug.print("{}\n", .{x});

    const x_ptr: *i32 = &x; // (2) This type could be inferred, but I’m annotating it for clarity.
    x_ptr.* = 456; // (3) Dereferencing and assigning a new value to whatever x_ptr points to.

    std.debug.print("{}\n", .{x_ptr.*}); // (4) Reading what x_ptr points to.
    std.debug.print("{}\n", .{x});
}