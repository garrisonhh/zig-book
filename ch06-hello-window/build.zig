const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });

    const app_mod = b.createModule(.{
        .root_source_file = b.path("src/app.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "raylib", .module = raylib.module("raylib") },
        },
    });
    app_mod.linkLibrary(raylib.artifact("raylib"));

    const app = b.addExecutable(.{
        .name = "hello-window",
        .root_module = app_mod,
    });
    b.installArtifact(app);

    const run_app = b.addRunArtifact(app);
    const run_app_cmd = b.step("run", "Run the app");
    run_app_cmd.dependOn(&run_app.step);
}
