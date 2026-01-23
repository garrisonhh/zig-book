const std = @import("std");
const testing = std.testing;
const vm = @import("vm");

const Context = struct {
    const Self = @This();

    memory: vm.Memory,
    display: vm.Display,
    keypad: vm.Keypad,

    fn init(program: []const u8) error{WriteOutOfBounds}!Self {
        var self: Self = undefined;
        try self.memory.loadProgram(program);
        return self;
    }

    fn step(self: *Self) vm.Error!void {
        try vm.step(&self.memory, &self.display, &self.keypad);
    }
};

test "jump" {
    var ctx = try Context.init(&[_]u8{
        0x1F, 0xFF, // jump to 0xFFF
    });
    try ctx.step();
    try testing.expectEqual(0xFFF, ctx.memory.pc);
}

test "jump in a loop" {
    var ctx = try Context.init(&[_]u8{
        0x12, 0x00, // jump to 0x200 (program load addr)
    });
    try ctx.step();
    try testing.expectEqual(0x200, ctx.memory.pc);
    try ctx.step();
    try testing.expectEqual(0x200, ctx.memory.pc);
    try ctx.step();
    try testing.expectEqual(0x200, ctx.memory.pc);
}

test "set pointer" {
    var ctx = try Context.init(&[_]u8{
        0xAF, 0xFF, // set I to 0xFFF
        0xAA, 0xAA, // set I to 0xAAA
    });
    try ctx.step();
    try testing.expectEqual(0xFFF, ctx.memory.i);
    try ctx.step();
    try testing.expectEqual(0xAAA, ctx.memory.i);
}

test "set register to constant" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x42, // set V0 = 0x42
        0x60, 0x00, // set V0 = 0x00
        0x6A, 0xFF, // set VA = 0xFF
    });
    try ctx.step();
    try testing.expectEqual(0x42, ctx.memory.vars[0]);
    try ctx.step();
    try testing.expectEqual(0x00, ctx.memory.vars[0]);
    try ctx.step();
    try testing.expectEqual(0x00, ctx.memory.vars[0]);
    try testing.expectEqual(0xFF, ctx.memory.vars[0xA]);
}

test "set register to random byte" {
    // no guaranteed way to check this without knowing the random algorithm, so
    // this just tests that the instruction happens and doesn't violate the mask
    const mask: u8 = 0b1010_1010;
    var ctx = try Context.init(&[_]u8{
        0xC0, mask,
    });
    try ctx.step();
    // if these aren't equal, the mask was violated
    try testing.expectEqual(ctx.memory.vars[0] & mask, ctx.memory.vars[0]);
}

test "add constant to register" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x42, // set V0 = 0x42
        0x70, 0x10, // add 0x10 to V0
        0x70, 0x10, // add 0x10 to V0
        0x70, 0xFF, // add 0xFF to V0
    });
    try ctx.step();
    try testing.expectEqual(0x42, ctx.memory.vars[0]);
    try ctx.step();
    try testing.expectEqual(0x52, ctx.memory.vars[0]);
    try ctx.step();
    try testing.expectEqual(0x62, ctx.memory.vars[0]);
    try ctx.step();
    try testing.expectEqual(0x61, ctx.memory.vars[0]);
}

test "set register to register" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x42, // set V0 = 0x42
        0x81, 0x00, // set V1 = V0
        0x82, 0x10, // set V2 = V1
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x42, ctx.memory.vars[0]);
    try testing.expectEqual(0x42, ctx.memory.vars[1]);
    try testing.expectEqual(0x42, ctx.memory.vars[2]);
}

test "bitor and bitand" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0b1010_1010, // set V0 = 0b10101010
        0x61, 0b0101_0101, // set V1 = 0b01010101
        0x82, 0x00, // set V2 = V0
        0x83, 0x10, // set V3 = V1
        0x80, 0x11, // set V0 = V0 | V1
        0x82, 0x32, // set V2 = V2 & V3
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0xAA, ctx.memory.vars[0]);
    try testing.expectEqual(0x55, ctx.memory.vars[1]);
    try testing.expectEqual(0xAA, ctx.memory.vars[2]);
    try testing.expectEqual(0x55, ctx.memory.vars[3]);
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0xFF, ctx.memory.vars[0]);
    try testing.expectEqual(0x00, ctx.memory.vars[2]);
}

test "add to register" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x0A, // set V0 = 0x0A
        0x61, 0x0B, // set V1 = 0x0B
        0x6F, 0xFF, // set VF = 0xFF
        0x80, 0x14, // set V0 = V0 + V1
        0x61, 0xFF, // set V1 = 0xFF
        0x80, 0x14, // set V0 = V0 + V1
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x15, ctx.memory.vars[0]);
    try testing.expectEqual(0x00, ctx.memory.vars[0xF]);
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x14, ctx.memory.vars[0]);
    try testing.expectEqual(0x01, ctx.memory.vars[0xF]);
}

test "subtract from register" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x0A, // set V0 = 0x0A
        0x61, 0x06, // set V1 = 0x06
        0x6F, 0xFF, // set VF = 0xFF
        0x80, 0x15, // set V0 = V0 - V1
        0x80, 0x15, // set V0 = V0 - V1
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x04, ctx.memory.vars[0]);
    try testing.expectEqual(0x00, ctx.memory.vars[0xF]);
    try ctx.step();
    try testing.expectEqual(0xFE, ctx.memory.vars[0]);
    try testing.expectEqual(0x01, ctx.memory.vars[0xF]);
}

test "set pointer with offset" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x10, // set V0 = 0x10
        0xAF, 0xEF, // set I to 0xFEF
        0xF0, 0x1E, // add V0 to I
        0xF0, 0x1E, // add V0 to I again (should overflow)
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0xFFF, ctx.memory.i);
    try ctx.step();
    try testing.expectEqual(0x00F, ctx.memory.i);
}

test "jump with offset" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x10, // set V0 = 0x10
        0xBF, 0xEF, // jump to 0xFEF + V0
    });
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0xFFF, ctx.memory.pc);
}

test "clear display" {
    var ctx = try Context.init(&[_]u8{
        0x00, 0xE0, // clear display
    });
    @memset(&ctx.display.pixels, [1]u1{1} ** 64);
    try ctx.step();
    const empty_pixels = std.mem.zeroes([32][64]u1);
    try testing.expectEqual(empty_pixels, ctx.display.pixels);
}

test "call a subroutine" {
    var ctx = try Context.init(&[_]u8{
        0x22, 0x04, // call subroutine at 0x204
        0x12, 0x02, // loops on itself (dummy instruction)
        0x00, 0xEE, // return from subroutine
    });
    try ctx.step();
    try testing.expectEqual(0x204, ctx.memory.pc);
    try ctx.step();
    try testing.expectEqual(0x202, ctx.memory.pc);
}

test "skip if var == const" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x42, // set v0 to 0x42
        0x30, 0x00, // if v0 is 0, skip next instruction
        0x30, 0x42, // if v0 is 0x42, skip next instruction
        0x12, 0x02, // loop infinitely (should be skipped)
    });
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x204, ctx.memory.pc);
    try ctx.step();
    try testing.expectEqual(0x208, ctx.memory.pc);
}

test "skip if var != const" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x42, // set v0 to 0x42
        0x40, 0x42, // if v0 is not 0x42, skip next instruction
        0x40, 0x00, // if v0 is not 0x00, skip next instruction
        0x12, 0x02, // loop infinitely (should be skipped)
    });
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x204, ctx.memory.pc);
    try ctx.step();
    try testing.expectEqual(0x208, ctx.memory.pc);
}

test "skip if var == var" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x42, // set v0 to 0x42
        0x61, 0x67, // set v1 to 0x67
        0x50, 0x10, // if v0 == v1, skip next instruction
        0x61, 0x42, // set v1 to 0x42
        0x50, 0x10, // if v0 == v1, skip next instruction
        0x12, 0x02, // loop infinitely (should be skipped)
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x206, ctx.memory.pc);
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x20C, ctx.memory.pc);
}

test "skip if var != var" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x42, // set v0 to 0x42
        0x61, 0x42, // set v1 to 0x42
        0x90, 0x10, // if v0 != v1, skip next instruction
        0x61, 0x67, // set v1 to 0x67
        0x90, 0x10, // if v0 != v1, skip next instruction
        0x12, 0x02, // loop infinitely (should be skipped)
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x206, ctx.memory.pc);
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x20C, ctx.memory.pc);
}

test "draw an 8 (manually) and erase it" {
    // taken (almost) straight from the COSMAC VIP manual :)
    var ctx = try Context.init(&[_]u8{
        0x00, 0xE0, // clear display
        0xA2, 0x0C, // I=020C
        0x61, 0x03, // V1=03
        0x62, 0x03, // V2=03
        0xD1, 0x25, // SHOW 5MI@V1V2
        0x00, 0xE0, // clear display again
        // display bytes
        0xF0, 0x90,
        0xF0, 0x90,
        0xF0,
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();

    // check for pattern at 3, 3
    const pattern = [_]u8{ 0xF0, 0x90, 0xF0, 0x90, 0xF0 };
    for (0..32) |y| {
        for (0..64) |x| {
            if (y >= 3 and y < 8 and x >= 3 and x < 11) {
                const bity = y - 3;
                const bitx = x - 3;
                const exp_bit: u1 = @truncate(pattern[bity] >> (7 - @as(u3, @intCast(bitx))));
                try testing.expectEqual(exp_bit, ctx.display.pixels[y][x]);
            } else {
                try testing.expectEqual(@as(u1, 0), ctx.display.pixels[y][x]);
            }
        }
    }

    // ensure display is erased
    try ctx.step();
    for (0..32) |y| {
        for (0..64) |x| {
            try testing.expectEqual(@as(u1, 0), ctx.display.pixels[y][x]);
        }
    }
}

test "wait for next hex key" {
    var ctx = try Context.init(&[_]u8{
        0xF0, 0x0A, // wait for hex key
        0xF0, 0x0A, // wait for hex key
    });
    try ctx.step();
    try testing.expectEqual(0x200, ctx.memory.pc);
    try ctx.step();
    try testing.expectEqual(0x200, ctx.memory.pc);
    ctx.keypad.keys[0xE] = true;
    try ctx.step();
    try testing.expectEqual(0x202, ctx.memory.pc);
    try testing.expectEqual(0xE, ctx.memory.vars[0]);
    ctx.keypad.keys[0xE] = false;
    try ctx.step();
    try testing.expectEqual(0x202, ctx.memory.pc);
    ctx.keypad.keys[3] = true;
    try ctx.step();
    try testing.expectEqual(0x204, ctx.memory.pc);
    try testing.expectEqual(0x3, ctx.memory.vars[0]);
}

test "copy to and from registers" {
    var ctx = try Context.init(&[_]u8{
        0xAF, 0x00, // set I to 0xF00
        0x60, 0xF0, // set V0 to 0xF0
        0x61, 0xF1, // set V1 to 0xF1
        0x62, 0xF2, // set V2 to 0xF2
        0xF2, 0x55, // save registers at MI
        0x60, 0x00, // set V0 to 0
        0x61, 0x00, // set V1 to 0
        0x62, 0x00, // set V2 to 0
        0xF2, 0x65, // load registers from MI
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0xF0, ctx.memory.vars[0]);
    try testing.expectEqual(0xF1, ctx.memory.vars[1]);
    try testing.expectEqual(0xF2, ctx.memory.vars[2]);
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0, ctx.memory.vars[0]);
    try testing.expectEqual(0, ctx.memory.vars[1]);
    try testing.expectEqual(0, ctx.memory.vars[2]);
    try ctx.step();
    try testing.expectEqual(0xF0, ctx.memory.vars[0]);
    try testing.expectEqual(0xF1, ctx.memory.vars[1]);
    try testing.expectEqual(0xF2, ctx.memory.vars[2]);
}

test "set and get delay timer" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x02, // set V0 to 0x02
        0xF0, 0x15, // set delay timer to V0
        0xF1, 0x07, // set V1 to delay timer value
        0x12, 0x04, // jump to 0x204
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x02, ctx.memory.vars[1]);
    ctx.memory.tickTimers();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x01, ctx.memory.vars[1]);
    ctx.memory.tickTimers();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x00, ctx.memory.vars[1]);
    ctx.memory.tickTimers();
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x00, ctx.memory.vars[1]);
    ctx.memory.tickTimers();
    try ctx.step();
    try ctx.step();
}

test "set sound timer" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x02, // set V0 to 0x02
        0xF0, 0x18, // set sound timer to V0
    });
    try ctx.step();
    try ctx.step();
    try testing.expectEqual(0x02, ctx.memory.st);
    ctx.memory.tickTimers();
    try testing.expectEqual(0x01, ctx.memory.st);
    ctx.memory.tickTimers();
    try testing.expectEqual(0, ctx.memory.st);
    ctx.memory.tickTimers();
    try testing.expectEqual(0, ctx.memory.st);
}

test "write out decimal of register" {
    var ctx = try Context.init(&[_]u8{
        0x60, 0x7B, // set V0 to 0x7B (123)
        0x61, 0xFF, // set V1 to 0xFF (255)
        0xAF, 0x00, // set I to 0xF00
        0xF0, 0x33, // write out V0
        0xF1, 0x33, // write out V1
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3 }, ctx.memory.data[0xF00..0xF03]);
    try ctx.step();
    try testing.expectEqualSlices(u8, &[_]u8{ 2, 5, 5 }, ctx.memory.data[0xF00..0xF03]);
}

test "draw an 8 (from font) and erase it" {
    // taken (almost) straight from the COSMAC VIP manual :)
    var ctx = try Context.init(&[_]u8{
        0x00, 0xE0, // clear display
        0x60, 0xF8, // set V0 to 0xF8
        0xF0, 0x29, // load font for LSD of V0 (8)
        0x61, 0x03, // V1=03
        0x62, 0x03, // V2=03
        0xD1, 0x25, // SHOW 5MI@V1V2
        0x00, 0xE0, // clear display again
        // display bytes
        0xF0, 0x90,
        0xF0, 0x90,
        0xF0,
    });
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();
    try ctx.step();

    // check for pattern at 3, 3
    const pattern = [_]u8{ 0xF0, 0x90, 0xF0, 0x90, 0xF0 };
    for (0..32) |y| {
        for (0..64) |x| {
            if (y >= 3 and y < 8 and x >= 3 and x < 11) {
                const bity = y - 3;
                const bitx = x - 3;
                const exp_bit: u1 = @truncate(pattern[bity] >> (7 - @as(u3, @intCast(bitx))));
                try testing.expectEqual(exp_bit, ctx.display.pixels[y][x]);
            } else {
                try testing.expectEqual(@as(u1, 0), ctx.display.pixels[y][x]);
            }
        }
    }

    // ensure display is erased
    try ctx.step();
    for (0..32) |y| {
        for (0..64) |x| {
            try testing.expectEqual(@as(u1, 0), ctx.display.pixels[y][x]);
        }
    }
}
