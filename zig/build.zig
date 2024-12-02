const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_step = b.step("test", "Run unit tests");

    const day01_exe = b.addExecutable(.{
        .name = "day01",
        .root_source_file = b.path("day01/day01.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_day01_cmd = b.addRunArtifact(day01_exe);
    if (b.args) |args| {
        run_day01_cmd.addArgs(args);
    }
    const run_day01_step = b.step("day01", "Run day01");
    run_day01_step.dependOn(&run_day01_cmd.step);

    const day01_tests = b.addTest(.{
        .root_source_file = b.path("day01/location_list.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_day01_tests = b.addRunArtifact(day01_tests);
    test_step.dependOn(&run_day01_tests.step);

    const day02_exe = b.addExecutable(.{
        .name = "day02",
        .root_source_file = b.path("day02/day02.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_day02_cmd = b.addRunArtifact(day02_exe);
    if (b.args) |args| {
        run_day02_cmd.addArgs(args);
    }
    const run_day02_step = b.step("day02", "Run day02");
    run_day02_step.dependOn(&run_day02_cmd.step);

    const day02_tests = b.addTest(.{
        .root_source_file = b.path("day02/level_reports.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_day02_tests = b.addRunArtifact(day02_tests);
    test_step.dependOn(&run_day02_tests.step);
}
