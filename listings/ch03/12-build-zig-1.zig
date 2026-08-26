//! Listing 3.12 build.zig

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{}); // (1) Allowing for targets and optimize modes to be configured with command line options. By default, this will compile in Debug mode and target the computer executing the build.
    const optimize = b.standardOptimizeOption(.{}); // (1) Allowing for targets and optimize modes to be configured with command line options. By default, this will compile in Debug mode and target the computer executing the build.

    const mod = b.createModule(.{ // (2) Our module starts with our main.zig file, and should be compiled to the specified target and optimization mode.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{ // (3) Creating a compilation step to build the cat executable from the module.
        .name = "cat",
        .root_module = mod,
    });
    b.installArtifact(exe); // (4) Telling the build system to compile the executable when zig build is executed.
}