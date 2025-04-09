const std = @import("std");
const cw = @import("crossed_wires.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parseResult = try cw.parseWiresFile(allocator, "data/day24/input.txt");
    std.debug.print("inputs {d}\n", .{parseResult.wire_values.map.count()});
    std.debug.print("gates {d}\n", .{parseResult.gates_map.map.count()});
    std.debug.print("output {d}\n", .{parseResult.outs.len});
    const output_value = try cw.outputValue(parseResult.outs, parseResult.gates_map, &parseResult.wire_values);
    std.debug.print("output_value = {d}\n", .{output_value});
}

test {
    _ = std.testing.refAllDecls(@This());
}
