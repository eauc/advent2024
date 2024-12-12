const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_step = b.step("test", "Run unit tests");

    var file_name_buf: [100]u8 = undefined;
    for ([_][]const u8{
        "day01",
        "day02",
        "day03",
        "day04",
        "day05",
        "day06",
        "day07",
        "day08",
        "day09",
    }) |day| {
        const root_file = try std.fmt.bufPrint(&file_name_buf, "{s}/{s}.zig", .{ day, day });
        const exe = b.addExecutable(.{
            .name = day,
            .root_source_file = b.path(root_file),
            .target = target,
            .optimize = optimize,
        });
        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step(day, "Run");
        run_step.dependOn(&run_cmd.step);

        const tests = b.addTest(.{
            .root_source_file = b.path(root_file),
            .target = target,
            .optimize = optimize,
        });
        const run_tests = b.addRunArtifact(tests);
        test_step.dependOn(&run_tests.step);
    }
}
