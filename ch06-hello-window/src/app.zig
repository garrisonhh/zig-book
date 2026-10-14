const c = @import("raylib");

pub fn main() !void {
    c.InitWindow(640, 480, "hello, blank window!");
    defer c.CloseWindow();

    c.SetTargetFPS(60);

    while (!c.WindowShouldClose()) {
        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.BLACK);
    }
}
