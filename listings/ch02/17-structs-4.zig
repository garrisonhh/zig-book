//! Listing 2.17 Pseudo-method syntax with mutation

const std = @import("std");

const Rectangle = struct {
    width: i32,
    height: i32,

    fn quadruple(rect: *Rectangle) void {    // (1) This function takes a reference to a mutable Rectangle.
        rect.width = rect.width * 2;    // (2) You can use dot syntax to access fields on pointers to structs. Implicitly, this is equivalent to self.*.width.
        rect.height *= 2;    // (3) The *= syntax is the same operation as the line above, just a little terser.
    }

    fn size(rect: Rectangle) i32 {
        return rect.width * rect.height;
    }
};

pub fn main() void {
    var rect: Rectangle = .{ .width = 10, .height = 20 }; // (4) Our rect must be var this time so that we can modify it through a pointer.
    rect.quadruple(); // (5) Method syntax with a pointer.
    std.debug.print("quadrupled rect: {}\n", .{rect.size()});
    Rectangle.quadruple(&rect); // (6) Equivalent function call.
    std.debug.print("quadrupled rect again: {}\n", .{rect.size()});
}