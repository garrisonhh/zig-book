//! Listing 2.16 Pseudo-method syntax

const std = @import("std");

const Rectangle = struct {
    width: i32,
    height: i32,

    fn size(rect: Rectangle) i32 { // (1) Since the first parameter to this function is a Rectangle, Rectangle instances can call it with the dot syntax.
        return rect.width * rect.height;
    }
};

pub fn main() void {
    const rect: Rectangle = .{ .width = 20, .height = 30 };
    const rect_size = rect.size(); // (2) Method syntax in action.
    std.debug.print("rect size using method syntax: {}\n", .{rect_size});
    const rect_size2 = Rectangle.size(rect); // (3) Equivalent to the method syntax.
    std.debug.print("rect size using function syntax: {}\n", .{rect_size2});
}