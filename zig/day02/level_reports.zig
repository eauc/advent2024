const std = @import("std");

const Level = isize;
const LevelReport = []const Level;
const LevelReportsList = []const LevelReport;

pub fn parseLevelReportsFile(allocator: std.mem.Allocator, file_name: []const u8) !LevelReportsList {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();
    var lineBuf: [1024]u8 = undefined;
    var reportBuf = [_]Level{0} ** 1024;
    var reportsList = std.ArrayList([]const isize).init(allocator);
    defer reportsList.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |line| {
        var i: usize = 0;
        var it = std.mem.splitScalar(u8, line, ' ');

        while (it.next()) |token| {
            if (token.len == 0) continue;
            const level = try std.fmt.parseInt(Level, token, 10);
            reportBuf[i] = level;
            i += 1;
            if (i == reportBuf.len) break;
        }

        const report = try allocator.alloc(Level, i);
        std.mem.copyForwards(Level, report, reportBuf[0..i]);

        try reportsList.append(report);
    }

    return reportsList.toOwnedSlice();
}

fn reportIsSafeStrict(level_report: LevelReport, skip_index: ?usize) bool {
    var increasing: ?bool = null;
    for (level_report, 0..) |level, i| {
        if (i == level_report.len - 1) break;
        var delta: isize = level_report[i + 1] - level;
        if (skip_index) |skip| {
            if (i == skip) continue;
            if (skip > 0 and i == skip - 1) {
                if (i == level_report.len - 2) break;
                delta = level_report[i + 2] - level;
            }
        }
        const current_increasing = delta > 0;
        if (increasing) |previous_increasing| {
            if (previous_increasing != current_increasing) return false;
        } else {
            increasing = current_increasing;
        }
        if (delta == 0) return false;
        if (@abs(delta) > 3) return false;
    }
    return true;
}

fn reportIsSafe(level_report: LevelReport) bool {
    if (reportIsSafeStrict(level_report, null)) return true;
    for (0..level_report.len) |skip_index| {
        if (reportIsSafeStrict(level_report, skip_index)) return true;
    }
    return false;
}

test reportIsSafe {
    std.debug.print("day02/reportIsSafe\n", .{});

    // a report only counts as safe if both of the following are true:
    // - The levels are either all increasing or all decreasing.
    // - Any two adjacent levels differ by at least one and at most three.

    std.debug.print("\tlevels are all decreasing -> safe\n", .{});
    try std.testing.expectEqual(true, reportIsSafe(&[_]Level{ 7, 6, 4, 2, 1 }));

    std.debug.print("\tlevels are all increasing -> safe\n", .{});
    try std.testing.expectEqual(true, reportIsSafe(&[_]Level{ 1, 3, 6, 7, 9 }));

    std.debug.print("\tlevels are not all decreasing -> unsafe\n", .{});
    try std.testing.expectEqual(false, reportIsSafe(&[_]Level{ 9, 4, 7, 2, 1 }));

    std.debug.print("\t2 7 is an increase of 5 -> unsafe\n", .{});
    try std.testing.expectEqual(false, reportIsSafe(&[_]Level{ 1, 2, 7, 8, 9 }));

    // The Problem Dampener is a reactor-mounted module that
    //  lets the reactor safety systems tolerate a single bad level in what would otherwise be a safe report.

    std.debug.print("\tlevels are not all increasing -> safe by removing the second level, 3\n", .{});
    try std.testing.expectEqual(true, reportIsSafe(&[_]Level{ 1, 3, 2, 4, 5 }));

    std.debug.print("\t4 4 is neither increase nor decrease -> safe by removing the third level, 4\n", .{});
    try std.testing.expectEqual(true, reportIsSafe(&[_]Level{ 8, 6, 4, 4, 1 }));
}

const SafeLevelReportsCountResult = struct { safe_reports: usize, unsafe_reports: usize };

pub fn safeLevelReportsCount(level_reports: LevelReportsList) SafeLevelReportsCountResult {
    var result = SafeLevelReportsCountResult{ .safe_reports = 0, .unsafe_reports = 0 };
    for (level_reports) |level_report| {
        if (reportIsSafe(level_report)) {
            result.safe_reports += 1;
        } else {
            result.unsafe_reports += 1;
        }
    }
    return result;
}

test safeLevelReportsCount {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day02/safeLevelReportsCount\n", .{});
    std.debug.print("\treading test input\n", .{});
    const levelReports = try parseLevelReportsFile(allocator, "data/day02/test.txt");
    try std.testing.expectEqualDeep(
        &[_][]const Level{
            &[_]Level{ 7, 6, 4, 2, 1 },
            &[_]Level{ 1, 2, 7, 8, 9 },
            &[_]Level{ 9, 7, 6, 2, 1 },
            &[_]Level{ 1, 3, 2, 4, 5 },
            &[_]Level{ 8, 6, 4, 4, 1 },
            &[_]Level{ 1, 3, 6, 7, 9 },
        },
        levelReports,
    );

    std.debug.print("\tcounting safe reports\n", .{});
    try std.testing.expectEqual(
        SafeLevelReportsCountResult{ .safe_reports = 4, .unsafe_reports = 2 },
        safeLevelReportsCount(levelReports),
    );
}
