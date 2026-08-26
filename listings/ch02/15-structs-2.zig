//! Listing 2.15 Structs can have declarations

const std = @import("std");

// (1) This struct has no fields, which is not an issue in Zig.
const animal_noises = struct {
    // (2) Declarations have the same syntax inside of a struct as they do outside of a struct.
    fn moo() void {
        std.debug.print("moo!\n", .{});
    }

    fn woof() void {
        std.debug.print("woof!\n", .{});
    }
};

pub fn main() void {
    // (3) The struct type is also a namespace.
    animal_noises.moo();
    animal_noises.woof();
}