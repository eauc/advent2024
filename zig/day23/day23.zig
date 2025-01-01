const std = @import("std");
const lp = @import("lan_party.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const network_map = try lp.parseNetworkMapFile(allocator, "data/day23/input.txt");
    const candidates = try lp.chiefHistorianThreesomeCandidates(allocator, network_map);
    std.debug.print("threesome candidates count = {d}\n", .{candidates.threes.items.len});
    try lp.lanParty(allocator, network_map);
}

test {
    _ = std.testing.refAllDecls(@This());
}
