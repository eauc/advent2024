const std = @import("std");
const gm = @import("guard_map.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const guard_map = try gm.parseGuardMapFile(allocator, "data/day06/input.txt");
    const visited_map = try gm.visitGuardMap(allocator, guard_map);
    for (visited_map.map) |line| {
        std.debug.print("{s}\n", .{line});
    }
    std.debug.print("Guard visited {} positions\n", .{gm.countVisitedPositions(visited_map)});
}

test {
    _ = std.testing.refAllDecls(@This());
}
