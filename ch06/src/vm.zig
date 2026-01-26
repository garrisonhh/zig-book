const std = @import("std");

var prng: std.Random.DefaultPrng = undefined;
var prng_initialized = false;

const font_data = @embedFile("font.bin");

pub const Display = struct {
    pixels: [32][64]u1,

    pub fn clear(display: *Display) void {
        @memset(&display.pixels, [1]u1{0} ** 64);
    }
};

pub const Keypad = struct {
    keys: [16]bool,
};

pub const Memory = struct {
    const Self = @This();

    pub const program_load_addr = 0x200;
    pub const total_memory_bytes = 0x1000;
    pub const font_load_addr = 0x100;

    pc: u12,
    i: u12,
    vars: [16]u8,
    data: [total_memory_bytes]u8,

    sp: u12,
    dt: u8,
    st: u8,

    pub fn readBytes(
        self: *const Self,
        addr: u12,
        comptime nbytes: comptime_int,
    ) error{ReadOutOfBounds}![nbytes]u8 {
        if (addr + nbytes > total_memory_bytes) {
            return error.ReadOutOfBounds;
        }
        const bytes = self.data[addr .. addr + nbytes];
        return @as(*const [nbytes]u8, @ptrCast(bytes.ptr)).*;
    }

    pub fn writeBytes(
        self: *Self,
        addr: u12,
        data: []const u8,
    ) error{WriteOutOfBounds}!void {
        if (addr + data.len > total_memory_bytes) {
            return error.WriteOutOfBounds;
        }
        const target = self.data[addr .. addr + data.len];
        @memcpy(target, data);
    }

    pub fn loadProgram(
        self: *Self,
        program: []const u8,
    ) error{WriteOutOfBounds}!void {
        try self.writeBytes(program_load_addr, program);
        try self.writeBytes(font_load_addr, &font_data);
        self.pc = program_load_addr;
        self.sp = 0;
        self.dt = 0;
        self.st = 0;
    }

    pub fn tickTimers(self: *Self) void {
        self.dt = @max(self.dt, 1) - 1;
        self.st = @max(self.st, 1) - 1;
    }
};

pub const Error = error{
    UnknownInstruction,

    ReadOutOfBounds,
    WriteOutOfBounds,
    PcOverflow,
    StackUnderflow,
    InitPrngFailed,
};

pub fn step(memory: *Memory, display: *Display, keypad: *Keypad) Error!void {
    // read next instruction
    const bytecode = try memory.readBytes(memory.pc, 2);
    memory.pc += 2;

    const nibbles = [4]u4{
        @intCast(bytecode[0] >> 4),
        @truncate(bytecode[0]),
        @intCast(bytecode[1] >> 4),
        @truncate(bytecode[1]),
    };

    switch (nibbles[0]) {
        0x0 => {
            if (nibbles[1] == 0x0 and bytecode[1] == 0xE0) {
                // clear display
                display.clear();
                return;
            } else if (nibbles[1] == 0x0 and bytecode[1] == 0xEE) {
                // return from subroutine
                if (memory.sp < 2) return error.StackUnderflow;
                memory.sp -= 2;

                const ret_addr_bytes = try memory.readBytes(memory.sp, 2);
                memory.pc = (@as(u12, ret_addr_bytes[0]) << 8) + @as(u12, ret_addr_bytes[1]);
                return;
            }

            return error.UnknownInstruction;
        },
        0x1 => {
            // jump to address
            const addr: u12 = (@as(u12, nibbles[1]) << 8) + bytecode[1];
            memory.pc = addr;
        },
        0x2 => {
            // call a subroutine
            const hi: u8 = @intCast(memory.pc >> 8);
            const lo: u8 = @truncate(memory.pc);
            try memory.writeBytes(memory.sp, &[_]u8{ hi, lo });
            memory.sp += 2;
            memory.pc = (@as(u12, nibbles[1]) << 8) + bytecode[1];
        },
        0x3 => {
            // skip next instruction if var = const
            if (memory.vars[nibbles[1]] == bytecode[1]) {
                memory.pc += 2;
            }
        },
        0x4 => {
            // skip next instruction if var != const
            if (memory.vars[nibbles[1]] != bytecode[1]) {
                memory.pc += 2;
            }
        },
        0x5 => {
            if (nibbles[3] != 0) return error.UnknownInstruction;
            // skip next instruction if var == var
            if (memory.vars[nibbles[1]] == memory.vars[nibbles[2]]) {
                memory.pc += 2;
            }
        },
        0x6 => {
            // set var to const
            memory.vars[nibbles[1]] = bytecode[1];
        },
        0x7 => {
            // add const to var
            memory.vars[nibbles[1]] +%= bytecode[1];
        },
        0x8 => switch (nibbles[3]) {
            0 => {
                // set var to var
                memory.vars[nibbles[1]] = memory.vars[nibbles[2]];
            },
            1 => {
                // var = var bitor var
                memory.vars[nibbles[1]] |= memory.vars[nibbles[2]];
            },
            2 => {
                // var = var bitand var
                memory.vars[nibbles[1]] &= memory.vars[nibbles[2]];
            },
            4 => {
                // var += var; set VF to carry
                const res = @addWithOverflow(memory.vars[nibbles[1]], memory.vars[nibbles[2]]);
                memory.vars[nibbles[1]] = res[0];
                memory.vars[0xF] = res[1];
            },
            5 => {
                // var -= var; set VF to sign
                const res = @subWithOverflow(memory.vars[nibbles[1]], memory.vars[nibbles[2]]);
                memory.vars[nibbles[1]] = res[0];
                memory.vars[0xF] = res[1];
            },
            else => {
                return error.UnknownInstruction;
            },
        },
        0x9 => {
            if (nibbles[3] != 0) return error.UnknownInstruction;
            // skip next instruction if var != var
            if (memory.vars[nibbles[1]] != memory.vars[nibbles[2]]) {
                memory.pc += 2;
            }
        },
        0xA => {
            // set I to const
            const addr: u12 = (@as(u12, nibbles[1]) << 8) + bytecode[1];
            memory.i = addr;
        },
        0xB => {
            // jump to address + offset
            const addr: u12 = (@as(u12, nibbles[1]) << 8) + bytecode[1];
            memory.pc = addr +% memory.vars[0];
        },
        0xC => {
            // set var to random byte with const mask
            if (!prng_initialized) {
                var seed: u64 = undefined;
                std.posix.getrandom(std.mem.asBytes(&seed)) catch {
                    return error.InitPrngFailed;
                };
                prng = .init(seed);
            }

            const rand_val = prng.random().int(u8);
            memory.vars[nibbles[1]] = rand_val & bytecode[1];
        },
        0xD => {
            // display a pattern
            const x = memory.vars[nibbles[1]];
            const y = memory.vars[nibbles[2]];
            for (0..nibbles[3]) |n| {
                const addr = memory.i + @as(u12, @intCast(n));
                const byte = (try memory.readBytes(addr, 1))[0];
                for (0..8) |nbit| {
                    const bit: u1 = @truncate(byte >> (7 - @as(u3, @intCast(nbit))));
                    const bitx = @as(usize, x) + nbit;
                    const bity = @as(usize, y) + n;
                    if (bitx >= 64 or bity >= 32) continue;
                    display.pixels[bity][bitx] ^= bit;
                }
            }
        },
        0xF => switch (bytecode[1]) {
            0x07 => {
                // set var to value of delay timer
                memory.vars[nibbles[1]] = memory.dt;
            },
            0x0A => {
                // set var to next hex key pressed
                const key_code: u8 = for (&keypad.keys, 0..) |*key, i| {
                    if (key.*) {
                        key.* = false;
                        break @intCast(i);
                    }
                } else {
                    // wait until a key is pressed
                    memory.pc -= 2;
                    return;
                };

                memory.vars[nibbles[1]] = key_code;
            },
            0x15 => {
                // set delay timer to value of var
                memory.dt = memory.vars[nibbles[1]];
            },
            0x18 => {
                // set sound timer to value of var
                memory.st = memory.vars[nibbles[1]];
            },
            0x1E => {
                // add var to I
                memory.i +%= memory.vars[0];
            },
            0x29 => {
                // set I to location of font data
                const digit = memory.vars[nibbles[1]] % 16;
                memory.i = Memory.font_load_addr + 5 * @as(u12, digit);
            },
            0x33 => {
                // write out 3-digit decimal of var
                var value = memory.vars[nibbles[1]];
                for (0..3) |digit| {
                    const addr, const ov =
                        @addWithOverflow(memory.i, 2 - @as(u12, @intCast(digit)));

                    const decimal = value % 10;
                    value = @divFloor(value, 10);
                    if (ov != 0) continue;

                    memory.data[addr] = decimal;
                }
            },
            0x55 => {
                // copy registers into memory
                for (0..@as(usize, nibbles[1]) + 1) |n| {
                    const addr, const ov =
                        @addWithOverflow(memory.i, @as(u12, @intCast(n)));
                    if (ov != 0) break;
                    memory.data[addr] = memory.vars[n];
                }
            },
            0x65 => {
                // copy memory into registers
                for (0..@as(usize, nibbles[1]) + 1) |n| {
                    const addr, const ov =
                        @addWithOverflow(memory.i, @as(u12, @intCast(n)));
                    if (ov != 0) break;
                    memory.vars[n] = memory.data[addr];
                }
            },
            else => {
                return error.UnknownInstruction;
            },
        },
        else => {
            return error.UnknownInstruction;
        },
    }
}
