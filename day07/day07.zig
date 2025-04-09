const std = @import("std");
const bo = @import("bridge_operations.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const operations = try bo.parseBridgeOperationsFile(allocator, "data/day07/input.txt");
    const calibration_result = try bo.calibrationResult(allocator, operations);
    std.debug.print("day07/calibrationResult: {d}\n", .{calibration_result});
}

test {
    _ = std.testing.refAllDecls(@This());
}
