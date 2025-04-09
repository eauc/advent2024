const std = @import("std");
const ll = @import("location_list.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lists = try ll.parseLocationListsFile(allocator, "day01/input.txt");

    const total_distance = ll.totalDistance(lists);
    std.debug.print("total_distance: {}\n", .{total_distance});
    try std.testing.expectEqual(1110981, total_distance);

    const total_similarity_score = ll.totalSimilarityScore(allocator, lists);
    std.debug.print("total_similarity_score: {}\n", .{total_similarity_score});
    try std.testing.expectEqual(24869388, total_similarity_score);
}

test {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
