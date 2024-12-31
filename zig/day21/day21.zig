const std = @import("std");
const lk = @import("lock_keypad.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const codes = try lk.parseDoorLockCodesFile(allocator, "data/day21/input.txt");
    // _ = codes;
    const complexities_sum = try lk.sumCodeComplexities(allocator, codes.items, 2);
    std.debug.print("2 layers complexities sum={d}\n", .{complexities_sum});
    const complexities_sum_25 = try lk.sumCodeComplexities(allocator, codes.items, 25);
    std.debug.print("25 layers complexities sum={}\n", .{complexities_sum_25});
}

test {
    _ = std.testing.refAllDecls(@This());
}
