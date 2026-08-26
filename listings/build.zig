const std = @import("std");

fn makeChapterStep(b: *std.Build, chapter: usize) *std.Build.Step {
    const ch_name = b.fmt("ch{d:0>2}", .{chapter});
    const ch_step = b.step(ch_name, b.fmt("Build code for chapter {d}", .{chapter}));
    b.getInstallStep().dependOn(ch_step);

    return ch_step;
}

/// creates an exe from chapter code
fn makeExe(
    b: *std.Build,
    chapter_step: *std.Build.Step,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const fullname = b.fmt("{s}-{s}", .{ chapter_step.name, name });

    const src_path = b.path(b.fmt("{s}/{s}.zig", .{ chapter_step.name, name }));
    const exe = b.addExecutable(.{
        .name = fullname,
        .root_module = b.createModule(.{
            .root_source_file = src_path,
            .target = target,
            .optimize = optimize,
        }),
    });

    const install_exe = b.addInstallArtifact(exe, .{});
    const install_cmd = b.step(fullname, b.fmt("Install {s}", .{fullname}));
    chapter_step.dependOn(&install_exe.step);
    install_cmd.dependOn(&install_exe.step);
}

/// creates an exe from a test written for chapter code
fn makeTest(
    b: *std.Build,
    chapter_step: *std.Build.Step,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const fullname = b.fmt("{s}-{s}", .{ chapter_step.name, name });

    const src_path = b.path(b.fmt("{s}/{s}.zig", .{ chapter_step.name, name }));
    const test_exe = b.addTest(.{
        .name = b.fmt("{s}-test", .{fullname}),
        .root_module = b.createModule(.{
            .root_source_file = src_path,
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_test = b.addRunArtifact(test_exe);
    const run_test_cmd = b.step(fullname, b.fmt("Test {s}", .{fullname}));
    chapter_step.dependOn(&run_test.step);
    run_test_cmd.dependOn(&run_test.step);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ch01 = makeChapterStep(b, 1);
    const ch02 = makeChapterStep(b, 2);
    const ch03 = makeChapterStep(b, 3);
    const ch04 = makeChapterStep(b, 4);

    makeExe(b, ch01, "01-hello-1", target, optimize);
    makeExe(b, ch01, "02-hello-2", target, optimize);

    makeExe(b, ch02, "01-structure-1", target, optimize);
    makeExe(b, ch02, "02-fibonacci-1", target, optimize);
    makeTest(b, ch02, "03-fibonacci-2", target, optimize);
    makeExe(b, ch02, "04-fibonacci-3", target, optimize);
    makeExe(b, ch02, "05-anatomy-main-1", target, optimize);
    makeExe(b, ch02, "06-pointers-1", target, optimize);
    // NOTE 07-pointers-2 is intended to demonstrate an error
    // NOTE 08-pointers-3 is an example
    makeExe(b, ch02, "09-arrays-1", target, optimize);
    makeExe(b, ch02, "10-slices-1", target, optimize);
    makeExe(b, ch02, "11-slices-2", target, optimize);
    makeExe(b, ch02, "12-hello-world", target, optimize);
    makeExe(b, ch02, "13-strings-1", target, optimize);
    makeExe(b, ch02, "14-structs-1", target, optimize);
    makeExe(b, ch02, "15-structs-2", target, optimize);
    makeExe(b, ch02, "16-structs-3", target, optimize);
    makeExe(b, ch02, "17-structs-4", target, optimize);
    // NOTE 18-stack-empty not intended to compile
    // NOTE 19-stack-init not intended to compile
    // NOTE 20-struct-pizza not intended to compile

    makeExe(b, ch03, "01-cat-1", target, optimize);
    makeTest(b, ch03, "02-error-sets-4", target, optimize);
    makeExe(b, ch03, "03-hello-world", target, optimize);
    // NOTE 04-interface is an example
    // NOTE 05-for-1 is an example
    makeTest(b, ch03, "06-for-4", target, optimize);
    makeExe(b, ch03, "07-cat-2", target, optimize);
    makeTest(b, ch03, "08-collatz-1", target, optimize);
    makeTest(b, ch03, "09-collatz-2", target, optimize);
    makeExe(b, ch03, "10-cat-3", target, optimize);
    makeExe(b, ch03, "11-reader", target, optimize);
    // NOTE 12-build-zig-1 is a build.zig
    makeTest(b, ch03, "13-optionals", target, optimize);
    makeExe(b, ch03, "14-using-optionals", target, optimize);
    // NOTE 15-buffer-option is a build.zig
    // NOTE 16-buffering is built as a project

    makeTest(b, ch04, "01-comptime-1", target, optimize);
    // NOTE 02-tokenize-scalar is not intended to compile
    makeExe(b, ch04, "03-duck-typing", target, optimize);
    // NOTE 04-duck-typing is part of project
    // NOTE 05-label-example is not intended to compile
    // NOTE 06-comptime-3 is part of project
    makeExe(b, ch04, "07-talk-to-me", target, optimize);
    // NOTE 08-validating-words is part of project
    // NOTE 09-validate-error-set is not intended to compile
    // NOTE 10-new-data is part of project
    // NOTE 11-check-it is part of project
    makeExe(b, ch04, "12-tcp-server", target, optimize);
    makeExe(b, ch04, "13-http-server", target, optimize);
    // NOTE 14-validate-ladder is part of project
    // NOTE 15-validate-over-http is part of project
}
