const std = @import("std");
const lr = @import("program_memory.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const programMemory = try lr.parseProgramMemoryFile(allocator, "day03/input.txt");
    const instructions = lr.parseAllInstructions(allocator, programMemory);
    const sum = lr.sumInstructions(instructions);

    std.debug.print("{{ sum = {d} }}\n", .{sum});
    try std.testing.expectEqual(127092535, sum);
}

test {
    _ = std.testing.refAllDecls(@This());
}
