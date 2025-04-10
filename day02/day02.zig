const std = @import("std");
const lr = @import("level_reports.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lists = try lr.parseLevelReportsFile(allocator, "day02/input.txt");
    const report = lr.safeLevelReportsCount(lists);

    std.debug.print("{}\n", .{report});
    try std.testing.expectEqual(308, report.safe_reports);
}

test {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
