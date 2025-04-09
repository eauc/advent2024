const std = @import("std");
const gg = @import("garden_groups.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const garden_map = try gg.parseGardenMapFile(allocator, "data/day12/input.txt");
    const garden_plots = try gg.gardenPlots(allocator, garden_map);
    const garden_areas = try gg.gardenAreas(allocator, garden_plots);
    std.debug.print("day12: total fence price: {d}\n", .{gg.totalFencePrice(garden_areas)});
    std.debug.print("day12: total fence price discount: {d}\n", .{gg.totalFencePriceDiscount(garden_areas)});
}

test {
    _ = std.testing.refAllDecls(@This());
}
