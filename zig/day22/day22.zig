const std = @import("std");
const mm = @import("monkey_market.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const buyer_secrets = try mm.parseBuyerSecretsFile(allocator, "data/day22/input.txt");
    const part1_checksum = mm.part1Checksum(buyer_secrets);
    std.debug.print("day22/part1: {d}\n", .{part1_checksum});
    const optimal_price = try mm.optimalSell(allocator, buyer_secrets);
    std.debug.print("day22/part2: {d}\n", .{optimal_price});
}

test {
    _ = std.testing.refAllDecls(@This());
}
