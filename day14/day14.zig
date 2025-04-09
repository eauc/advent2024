const std = @import("std");
const br = @import("bathroom_robots.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const robots = try br.parseBathroomRobotsFile(allocator, "data/day14/input.txt");
    br.moveRobots(.{ .width = 101, .height = 103 }, robots, 100);
    std.debug.print("day14/safetyFactor: {d}\n", .{br.safetyFactor(.{ .width = 101, .height = 103 }, robots)});

    const tree_robots = try br.parseBathroomRobotsFile(allocator, "data/day14/input.txt");
    const max_score_index = br.maximalSymetryScore(.{ .width = 101, .height = 103 }, tree_robots);

    const check_robots = try br.parseBathroomRobotsFile(allocator, "data/day14/input.txt");
    br.moveRobots(.{ .width = 101, .height = 103 }, check_robots, max_score_index);
    for (0..103) |row| {
        var line = [1]u8{' '} ** 101;
        update_col: for (0..101) |col| {
            for (check_robots) |robot| {
                if (robot.position.row == row and robot.position.col == col) {
                    line[col] = '#';
                    continue :update_col;
                }
            }
        }
        std.debug.print("{s}\n", .{line});
    }
    std.debug.print("max_score_index: {d}\n", .{max_score_index});
}

test {
    _ = std.testing.refAllDecls(@This());
}
