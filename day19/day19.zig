const std = @import("std");
const ll = @import("linen_layout.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const parse_result = try ll.parseLinenLayoutFile(allocator, "data/day19/input.txt");
    const patterns = parse_result.patterns;
    const designs = parse_result.designs;

    std.debug.print("nb possible designs = {d}\n", .{ll.countPossibleDesigns(designs, patterns)});
    std.debug.print("total design arrangements = {d}\n", .{try ll.countTotalDesignArrangements(allocator, designs, patterns)});
}

test {
    _ = std.testing.refAllDecls(@This());
}
