//! Listing 3.15 Adding buffer size options

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const reader_buffer_size = b.option( // (1) Adding buffer size options to zig build.
        usize,
        "reader-buffer-size",
        "Reader buffer bytes",
    ) orelse 1024; // (2) By default, use 1024 bytes (1 KiB).
    const writer_buffer_size = b.option( // (1) Adding buffer size options to zig build.
        usize,
        "writer-buffer-size",
        "Writer buffer bytes",
    ) orelse 1024; // (2) By default, use 1024 bytes (1 KiB).

    const options = b.addOptions(); // (3) Creating an options data structure, and adding buffer sizes to it.
    options.addOption(usize, "reader_buffer_size", reader_buffer_size);
    options.addOption(usize, "writer_buffer_size", writer_buffer_size);

    const options_mod = options.createModule(); // (4) Creates a build module from the options.

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addImport("options", options_mod); // (5) Allowing the options module to be imported from our program under the name options.

    const exe = b.addExecutable(.{
        .name = "cat",
        .root_module = mod,
    });
    b.installArtifact(exe);
}