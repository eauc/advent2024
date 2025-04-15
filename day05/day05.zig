const std = @import("std");
const mu = @import("safety_manual_updates.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const safety_manual_updates = try mu.parseSafetyManualUpdatesFile(allocator, "day05/input.txt");
    const safety_manual_updates_check = try mu.checkSafetyManualUpdates(allocator, safety_manual_updates);
    std.debug.print("{}\n", .{safety_manual_updates_check});
    try std.testing.expectEqualDeep(mu.SafetyManualUpdatesCheck{
        .valid_updates_check = 5588,
        .invalid_updates_check = 5331,
    }, safety_manual_updates_check);
}

test {
    _ = std.testing.refAllDecls(@This());
}
