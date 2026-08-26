//! Listing 2.19 A taller stack

pub const Stack = struct {
    data: []u8,
    count: usize,

    pub fn init(buf: []u8) Stack { // (1) Creating a stack, but with configuration.
        return .{
            .data = buf,
            .count = 0,
        };
    }
};

pub fn main() void {
    var my_stack_buf: [256]u8 = undefined; // (2) We need a buffer now.
    const my_stack: Stack = .init(&my_stack_buf); // (3) Creating a stack but with a function.

    // ... using my_stack ...
}