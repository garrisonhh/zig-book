const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "recipe-book",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    const unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    const install_unit_tests = b.addInstallArtifact(unit_tests, .{});
    const install_tests_step = b.step("install-tests", "Build tests");
    install_tests_step.dependOn(&install_unit_tests.step);
}
