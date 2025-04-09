const std = @import("std");
const pa = @import("pushdown_automaton.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const bytes_list = try pa.parseBytesListFile(allocator, "data/day18/input.txt");
    const optimal_cost = try pa.findOptimalPathCost(71, 71, bytes_list[0..1024]);
    std.debug.print("optimal cost: {}\n", .{optimal_cost});
    const first_no_exit_byte = try pa.firstNoExitByte(71, 71, bytes_list);
    std.debug.print("first no exit byte: [{d}, {d}]\n\n", .{ first_no_exit_byte.row, first_no_exit_byte.col });
}

test {
    _ = std.testing.refAllDecls(@This());
}
