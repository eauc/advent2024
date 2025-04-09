const std = @import("std");
const rc = @import("resonant_colinearity.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const antenna_map = try rc.parseAntennaMapFile(allocator, "data/day08/input.txt");
    const antinodes = try rc.findAllAntiNodes(allocator, antenna_map);
    const antinodes_map = try rc.antiNodesMap(allocator, antenna_map, antinodes);
    for (antinodes_map) |row| {
        std.debug.print("{s}\n", .{row});
    }
    std.debug.print("{{ antinodes = {d} }}\n", .{antinodes.len});
}

test {
    _ = std.testing.refAllDecls(@This());
}
