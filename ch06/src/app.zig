const std = @import("std");
const vm = @import("vm");

const c = @cImport({
    @cInclude("raylib.h");
});

const keypad_keys = [16]c_int{
    c.KEY_KP_0, c.KEY_KP_1, c.KEY_KP_2,   c.KEY_KP_3,
    c.KEY_KP_4, c.KEY_KP_5, c.KEY_KP_6,   c.KEY_KP_7,
    c.KEY_KP_8, c.KEY_KP_9, c.KEY_KP_ADD, c.KEY_KP_ENTER,
    c.KEY_Q,    c.KEY_W,    c.KEY_E,      c.KEY_R,
};

pub fn main() !void {
    var keypad: vm.Keypad = undefined;
    var display: vm.Display = undefined;
    var memory: vm.Memory = undefined;
    try memory.loadProgram(@embedFile("programs/kaleidoscope.ch8"));

    display.clear();

    c.InitWindow(640, 320, "chip8 console");
    defer c.CloseWindow();
    c.SetTargetFPS(60);

    c.InitAudioDevice();
    defer c.CloseAudioDevice();

    const sound = c.LoadSound("res/tone.wav");
    defer c.UnloadSound(sound);

    while (!c.WindowShouldClose()) {
        // update keypad
        for (keypad_keys, 0..) |key, i| {
            keypad.keys[i] = c.IsKeyPressed(key);
        }

        // run vm
        for (0..1000) |_| {
            vm.step(&memory, &display, &keypad) catch |e| {
                if (e != error.UnknownInstruction) return e;
                const bytecode = try memory.readBytes(memory.pc - 2, 2);
                const op: u16 = (@as(u16, bytecode[0]) << 8) + bytecode[1];
                std.debug.print("unknown instruction: {X:04} (at {X:03})\n", .{ op, memory.pc - 2 });
                break;
            };
        }

        // play sound
        if (memory.st > 0) {
            if (!c.IsSoundPlaying(sound)) {
                c.PlaySound(sound);
            }
        } else if (c.IsSoundPlaying(sound)) {
            c.StopSound(sound);
        }

        memory.tickTimers();

        // draw graphics
        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.BLACK);

        const pix_h = 32;
        const pix_w = 64;
        const cell_h = @divFloor(c.GetRenderHeight(), pix_h);
        const cell_w = @divFloor(c.GetRenderWidth(), pix_w);
        for (0..pix_h) |y| {
            for (0..pix_w) |x| {
                if (display.pixels[y][x] == 0) continue;
                c.DrawRectangle(
                    @as(c_int, @intCast(x)) * cell_w,
                    @as(c_int, @intCast(y)) * cell_h,
                    cell_w,
                    cell_h,
                    c.WHITE,
                );
            }
        }
    }
}
