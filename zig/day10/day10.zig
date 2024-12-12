const std = @import("std");
const df = @import("hiking_trails.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const hiking_map = try df.parseHikingMapFile(allocator, "data/day10/input.txt");
    const score = try df.scoreTrailHeads(allocator, hiking_map);
    std.debug.print("score = {d}\n", .{score});
    const rate = try df.rateTrailHeads(allocator, hiking_map);
    std.debug.print("rate = {d}\n", .{rate});
}

test {
    _ = std.testing.refAllDecls(@This());
}
