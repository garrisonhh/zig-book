//! Listing 2.7 Pointer mutability

// (this is not supposed to compile)

const std = @import("std");

pub fn main() void {
    var a: i32 = 123;
    const b: i32 = 456; // (1) Two variables, one mutable and one immutable.

    const a_ptr = &a; // (2) This will take the type *i32.
    const b_ptr = &b; // (3) This will take the type *const i32, read as pointer to a const i32.

    a_ptr.* = 25; // (4) a_ptr points to mutable memory, so this is perfectly valid.
    b_ptr.* = 50; // (5) Whoops — b_ptr points to constant memory!

    a = b_ptr.*; // (6) Dereferencing a const pointer is A-OK!

    std.debug.print("a = {}, b = {}\n", .{ a, b });
}
