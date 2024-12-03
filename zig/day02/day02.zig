const std = @import("std");
const lr = @import("level_reports.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lists = try lr.parseLevelReportsFile(allocator, "data/day02/input.txt");

    std.debug.print("{}\n", .{lr.safeLevelReportsCount(lists)});
}
