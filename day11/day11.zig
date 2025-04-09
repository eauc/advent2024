const std = @import("std");
const ss = @import("stones_sets.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stones_set = try ss.parseStonesSetFile(allocator, "data/day11/input.txt");
    var blink_stones_count = try ss.blinkStonesSet(allocator, stones_set, 25);
    std.debug.print("blink_stones_set 25: {d}\n", .{blink_stones_count});
    blink_stones_count = try ss.blinkStonesSet(allocator, stones_set, 75);
    std.debug.print("blink_stones_set 75: {d}\n", .{blink_stones_count});
}

test {
    _ = std.testing.refAllDecls(@This());
}
