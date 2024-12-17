const std = @import("std");
const xx = @import("xx_xx.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const xxx = try xx.parseXXFile(allocator, "data/dayXX/input.txt");
    _ = xxx;
}

test {
    _ = std.testing.refAllDecls(@This());
}
