const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const translate_c = b.dependency("translate_c", .{});

    const translator: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
        .link_system_libs = &.{
            .{ .name = "glfw3" },
        },
    });
    translator.addIncludePath(b.path("glad/include"));

    const c = translator.mod;
    c.addCSourceFile(.{ .file = b.path("glad/src/glad.c") });

    const exes = &[_][]const u8{
        "window",
        "triangle",
    };

    for (exes) |name| {
        const mod = b.createModule(.{
            .root_source_file = b.path(b.fmt("src/{s}.zig", .{name})),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "c", .module = c },
            },
        });

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
