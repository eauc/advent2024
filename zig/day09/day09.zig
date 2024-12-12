const std = @import("std");
const df = @import("disk_fragmenter.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const disk_map = try df.parseDiskMapFile(allocator, "data/day09/input.txt");
    const fragmented_map = try df.fragmentDisk(allocator, disk_map);
    const defragmented_map = try df.defragmentDisk(allocator, disk_map);
    std.debug.print("checksum fragmented = {d}\n", .{df.checksum(fragmented_map)});
    std.debug.print("checksum defragmented = {d}\n", .{df.checksum(defragmented_map)});
}

test {
    _ = std.testing.refAllDecls(@This());
}
