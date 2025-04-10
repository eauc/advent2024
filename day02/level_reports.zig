//! # Day 2: Red-Nosed Reports
//! Fortunately, the first location The Historians want to search isn't a long walk from the Chief Historian's office.
//!
//! While the Red-Nosed Reindeer nuclear fusion/fission plant appears to contain no sign of the Chief Historian, the engineers there run up to you as soon as they see you. Apparently, they still talk about the time Rudolph was saved through molecular synthesis from a single electron.
//!
//! They're quick to add that - since you're already here - they'd really appreciate your help analyzing some unusual data from the Red-Nosed reactor. You turn to check if The Historians are waiting for you, but they seem to have already divided into groups that are currently searching every corner of the facility. You offer to help with the unusual data.
//!
//! The unusual data (your puzzle input) consists of many reports, one report per line. Each report is a list of numbers called levels that are separated by spaces. For example:
//!
//! ```
//! 7 6 4 2 1
//! 1 2 7 8 9
//! 9 7 6 2 1
//! 1 3 2 4 5
//! 8 6 4 4 1
//! 1 3 6 7 9
//! ```
//!
//! This example data contains six reports each containing five levels.
//!
//! The engineers are trying to figure out which reports are safe. The Red-Nosed reactor safety systems can only tolerate levels that are either gradually increasing or gradually decreasing. So, a report only counts as safe if both of the following are true:
//!
//! The levels are either all increasing or all decreasing.
//! Any two adjacent levels differ by at least one and at most three.
//! In the example above, the reports can be found safe or unsafe by checking those rules:
//!
//! - [7 6 4 2 1] Safe because the levels are all decreasing by 1 or 2.
//! - [1 2 7 8 9] Unsafe because 2 7 is an increase of 5.
//! - [9 7 6 2 1] Unsafe because 6 2 is a decrease of 4.
//! - [1 3 2 4 5] Unsafe because 1 3 is increasing but 3 2 is decreasing.
//! - [8 6 4 4 1] Unsafe because 4 4 is neither an increase or a decrease.
//! - [1 3 6 7 9] Safe because the levels are all increasing by 1, 2, or 3.
//!
//! So, in this example, 2 reports are safe.
//!
//! The engineers are surprised by the low number of safe reports until they realize they forgot to tell you about the Problem Dampener.
//!
//! The Problem Dampener is a reactor-mounted module that lets the reactor safety systems tolerate a single bad level in what would otherwise be a safe report. It's like the bad level never happened!
//!
//! Now, the same rules apply as before, except if removing a single level from an unsafe report would make it safe, the report instead counts as safe.
//!
//! More of the above example's reports are now safe:
//!
//! - [7 6 4 2 1] Safe without removing any level.
//! - [1 2 7 8 9] Unsafe regardless of which level is removed.
//! - [9 7 6 2 1] Unsafe regardless of which level is removed.
//! - [1 3 2 4 5] Safe by removing the second level, 3.
//! - [8 6 4 4 1] Safe by removing the third level, 4.
//! - [1 3 6 7 9] Safe without removing any level.
//!
//! Thanks to the Problem Dampener, 4 reports are actually safe!

const std = @import("std");

const Level = isize;
const LevelReport = []const Level;
const LevelReportsList = []const LevelReport;

fn freeLevelReportsList(allocator: std.mem.Allocator, level_reports: LevelReportsList) void {
    for (level_reports) |level_report| {
        allocator.free(level_report);
    }
    allocator.free(level_reports);
}

pub fn parseLevelReportsFile(allocator: std.mem.Allocator, file_name: []const u8) !LevelReportsList {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();
    var lineBuf: [1024]u8 = undefined;
    var reportBuf = [_]Level{0} ** 1024;
    var reportsList = std.ArrayList([]const Level).init(allocator);
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

        const report = allocator.alloc(Level, i) catch unreachable;
        std.mem.copyForwards(Level, report, reportBuf[0..i]);

        reportsList.append(report) catch unreachable;
    }

    return reportsList.toOwnedSlice();
}

test parseLevelReportsFile {
    const allocator = std.testing.allocator;

    const levelReports = try parseLevelReportsFile(allocator, "day02/test.txt");
    defer freeLevelReportsList(allocator, levelReports);

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
}

/// Checks is a report is safe, optionnally skeeping the level at skip_index.
pub fn reportIsSafeStrict(level_report: LevelReport, skip_index: ?usize) bool {
    var increasing: ?bool = null;
    for (level_report, 0..) |level, i| {
        if (i == level_report.len - 1) break;
        var delta: isize = level_report[i + 1] - level;
        if (skip_index) |skip| {
            // The Problem Dampener is a reactor-mounted module that
            // lets the reactor safety systems tolerate a single bad level in what would otherwise be a safe report.
            if (i == skip) continue;
            if (skip > 0 and i == skip - 1) {
                if (i == level_report.len - 2) break;
                delta = level_report[i + 2] - level;
            }
        }
        // a report only counts as safe if both of the following are true:
        // - The levels are either all increasing or all decreasing.
        const current_increasing = delta > 0;
        if (increasing) |previous_increasing| {
            if (previous_increasing != current_increasing) return false;
        } else {
            increasing = current_increasing;
        }
        if (delta == 0) return false;
        // - Any two adjacent levels differ by at least one and at most three.
        if (@abs(delta) > 3) return false;
    }
    return true;
}

/// Checks if a report is safe, taking into account the Problem Dampener.
pub fn reportIsSafe(level_report: LevelReport) bool {
    if (reportIsSafeStrict(level_report, null)) return true;
    for (0..level_report.len) |skip_index| {
        if (reportIsSafeStrict(level_report, skip_index)) return true;
    }
    return false;
}

test "reportIsSafe/levels are all decreasing -> safe" {
    try std.testing.expectEqual(true, reportIsSafe(&[_]Level{ 7, 6, 4, 2, 1 }));
}

test "reportIsSafe/levels are all increasing -> safe" {
    try std.testing.expectEqual(true, reportIsSafe(&[_]Level{ 1, 3, 6, 7, 9 }));
}

test "reportIsSafe/levels are not all decreasing -> unsafe" {
    try std.testing.expectEqual(false, reportIsSafe(&[_]Level{ 9, 4, 7, 2, 1 }));
}

test "reportIsSafe/2 7 is an increase of 5 -> unsafe" {
    try std.testing.expectEqual(false, reportIsSafe(&[_]Level{ 1, 2, 7, 8, 9 }));
}

test "reportIsSafe/levels are not all increasing -> safe by removing the second level, 3" {
    try std.testing.expectEqual(true, reportIsSafe(&[_]Level{ 1, 3, 2, 4, 5 }));
}

test "reportIsSafe/4 4 is neither increase nor decrease -> safe by removing the third level, 4" {
    try std.testing.expectEqual(true, reportIsSafe(&[_]Level{ 8, 6, 4, 4, 1 }));
}

const SafeLevelReportsCountResult = struct { safe_reports: usize, unsafe_reports: usize };

/// Counts the number of safe and unsafe reports.
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
    const allocator = std.testing.allocator;

    const levelReports = try parseLevelReportsFile(allocator, "day02/test.txt");
    defer freeLevelReportsList(allocator, levelReports);

    try std.testing.expectEqual(
        SafeLevelReportsCountResult{ .safe_reports = 4, .unsafe_reports = 2 },
        safeLevelReportsCount(levelReports),
    );
}
