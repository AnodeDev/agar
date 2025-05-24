const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/root.zig");

    const agar_mod = b.addModule("agar", .{
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
    });

    const Example = enum {
        hello,
        block,
        paragraph,
    };

    const example_option = b.option(Example, "example", "Example to run (default: hello)") orelse .hello;
    const example_step = b.step("example", "Run example");
    const example = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path(b.fmt("examples/{s}.zig", .{@tagName(example_option)})),
        .target = target,
        .optimize = optimize,
    });
    example.root_module.addImport("agar", agar_mod);

    const example_run = b.addRunArtifact(example);
    example_step.dependOn(&example_run.step);
}
