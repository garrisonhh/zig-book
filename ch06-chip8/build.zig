const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vm_mod = b.createModule(.{
        .root_source_file = b.path("src/vm.zig"),
        .target = target,
        .optimize = optimize,
    });

    // tests
    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_mod.addImport("vm", vm_mod);

    const tests = b.addTest(.{
        .root_module = test_mod,
    });
    const run_tests = b.addRunArtifact(tests);

    const test_cmd = b.step("test", "Run the vm tests");
    test_cmd.dependOn(&run_tests.step);

    // raylib
    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib_lib = raylib.artifact("raylib");

    // runtime
    const app_mod = b.createModule(.{
        .root_source_file = b.path("src/app.zig"),
        .target = target,
        .optimize = optimize,
    });
    app_mod.addImport("vm", vm_mod);
    app_mod.linkLibrary(raylib_lib);

    const app = b.addExecutable(.{
        .name = "chip8-runtime",
        .root_module = app_mod,
    });
    b.installArtifact(app);

    const run_app = b.addRunArtifact(app);
    const run_app_cmd = b.step("run", "Run the chip8 runtime");
    run_app_cmd.dependOn(&run_app.step);
}
