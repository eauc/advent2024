const std = @import("std");
const rc = @import("race_condition.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const race_map = try rc.parseRaceMapFile(allocator, "data/day20/input.txt");
    const path = try rc.getPath(allocator, race_map);
    const cheats_2 = rc.countCheats(path, 2, 100);
    std.debug.print("cheats gaining more than 100ps with max 2 cheats: {d}\n", .{cheats_2});
    const cheats_20 = rc.countCheats(path, 20, 100);
    std.debug.print("cheats gaining more than 100ps with max 20 cheats: {d}\n", .{cheats_20});
}

test {
    _ = std.testing.refAllDecls(@This());
}
