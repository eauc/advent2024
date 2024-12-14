const std = @import("std");
const cm = @import("claw_machines.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const claw_machines = try cm.parseClawMachinesFile(allocator, "data/day13/input.txt");
    std.debug.print("total price: {}\n", .{cm.totalPrice(claw_machines)});
    std.debug.print("total price: {}\n", .{cm.trueTotalPrice(claw_machines)});
}

test {
    _ = std.testing.refAllDecls(@This());
}
