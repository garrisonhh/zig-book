//! Listing 2.18 An empty stack

pub const Stack = struct { // (1) A stack data structure.
    pub const empty: Stack = .{ // (2) An empty stack.
        .data = undefined,
        .count = 0,
    };

    data: [256]u8,
    count: usize,
};

pub fn main() void {
    const my_stack: Stack = .empty; // (3) Creating a stack.

    // ... using my_stack ...
}