const std = @import("std");
const co = @import("computer.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var print_buf = [1]u8{0} ** 1024;

    var program_state = try co.parseComputerStateFile(allocator, "data/day17/input.txt");
    defer program_state.deinit();

    for (program_state.instructions) |instruction| {
        std.debug.print("{s}\n", .{instruction.bufPrint(&print_buf)});
    }
    const a = try program_state.fixA(null);
    std.debug.print("fix_a={d}\n", .{a});
}

test {
    _ = std.testing.refAllDecls(@This());
}
