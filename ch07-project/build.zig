const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exes = &[_][]const u8{
        "window",
        "triangle",
    };

    for (exes) |name| {
        const mod = b.createModule(.{
            .root_source_file = b.path(b.fmt("src/{s}.zig", .{name})),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        mod.addIncludePath(b.path("glad/include"));
        mod.addCSourceFile(.{ .file = b.path("glad/src/glad.c") });
        mod.linkSystemLibrary("glfw3", .{});

        const exe = b.addExecutable(.{
            .name = name,
            .root_module = mod,
        });
        b.installArtifact(exe);

        const run_exe = b.addRunArtifact(exe);
        const run_exe_cmd = b.step(b.fmt("run-{s}", .{name}), "");
        run_exe_cmd.dependOn(&run_exe.step);
    }
}
