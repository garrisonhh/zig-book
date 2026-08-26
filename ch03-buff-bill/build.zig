const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const reader_buffer_size = b.option(
        usize,
        "reader-buffer-size",
        "Reader buffer bytes",
    ) orelse 1024;
    const writer_buffer_size = b.option(
        usize,
        "writer-buffer-size",
        "Writer buffer bytes",
    ) orelse 1024;

    const options = b.addOptions();
    options.addOption(usize, "reader_buffer_size", reader_buffer_size);
    options.addOption(usize, "writer_buffer_size", writer_buffer_size);

    const options_mod = options.createModule();

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addImport("options", options_mod);

    const exe = b.addExecutable(.{
        .name = "cat",
        .root_module = mod,
    });
    b.installArtifact(exe);
}
