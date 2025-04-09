const std = @import("std");
const wr = @import("warehouse_robots.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const parse_result = try wr.parseWarehouseMapFile(allocator, "data/day15/input.txt");
    var warehouse_map = parse_result.warehouse_map;
    const robot = parse_result.robot;
    const moves = parse_result.moves;
    defer warehouse_map.deinit(allocator);
    defer allocator.free(parse_result.moves);

    const last_robot_position = wr.moveRobotSequence(warehouse_map, robot, moves);

    std.debug.print("last robot position: {}\n", .{last_robot_position});
    std.debug.print("sum of all boxes gps coordinates: {}\n", .{wr.sumBoxGpsCoordinates(warehouse_map)});

    const parse_result_wide = try wr.parseWideWarehouseMapFile(allocator, "data/day15/input.txt");
    var wide_warehouse_map = parse_result_wide.warehouse_map;
    const wide_robot = parse_result_wide.robot;
    const wide_moves = parse_result_wide.moves;
    defer wide_warehouse_map.deinit(allocator);
    defer allocator.free(parse_result_wide.moves);

    const last_robot_position_wide = wr.moveRobotWideSequence(wide_warehouse_map, wide_robot, wide_moves);

    std.debug.print("last robot position wide: {}\n", .{last_robot_position_wide});
    std.debug.print("sum of all boxes gps coordinates wide: {}\n", .{wr.sumBoxGpsCoordinates(wide_warehouse_map)});
}

test {
    _ = std.testing.refAllDecls(@This());
}
