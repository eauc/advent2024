const std = @import("std");
const rm = @import("reindeer_maze.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var print_buf = [1]u8{0} ** 100000;

    const parse_result = try rm.parseReindeerMazeMapFile(allocator, "data/day16/input.txt");
    const maze_map = parse_result.maze_map;
    const start_position = parse_result.start_position;
    const exit_position = parse_result.exit_position;

    const optimal_paths = try rm.findAllOptimalPaths(allocator, maze_map, start_position, exit_position);
    std.debug.print("optimal_cost={d}\n", .{optimal_paths.paths.items[0].cost()});
    const unique_positions = try rm.uniquePositions(allocator, optimal_paths);
    std.debug.print("unique_positions.len={d}\n", .{unique_positions.len});
    std.debug.print("{s}\n", .{rm.bufPrintPositions(&print_buf, maze_map, unique_positions)});
}

test {
    _ = std.testing.refAllDecls(@This());
}
