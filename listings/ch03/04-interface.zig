//! Listing 3.4 What is an interface?

const WriterInterface = struct {
    context: *const anyopaque, // (1) A pointer to any context needed to write things.
    vtable: *const VTable, // (2) A virtual table, containing functions of underlying functionality.

    const VTable = struct {
        write_bytes: *const fn(
            context: *const anyopaque,
            bytes: []const u8,
        ),
    };

    // methods like print can go here!

    fn writeAll(self: @This(), bytes: []const u8) void {
        self.vtable.write_bytes(self.context, bytes);
    }
}