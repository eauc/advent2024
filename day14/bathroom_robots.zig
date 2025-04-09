const std = @import("std");

const Position = struct {
    row: isize,
    col: isize,
};

const Velocity = struct {
    row: isize,
    col: isize,
};

const Robot = struct {
    position: Position,
    velocity: Velocity,
};

pub fn parseBathroomRobotsFile(allocator: std.mem.Allocator, file_name: []const u8) ![]Robot {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var robots_list = std.ArrayList(Robot).init(allocator);
    defer robots_list.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |robot_line| {
        var it = std.mem.splitScalar(u8, robot_line, ' ');
        const position_str = it.next().?;
        const velocity_str = it.next().?;

        it = std.mem.splitScalar(u8, position_str, ',');
        const pos_col_str = it.next().?;
        const pos_col = try std.fmt.parseInt(isize, pos_col_str[2..], 10);
        const pos_row_str = it.next().?;
        const pos_row = try std.fmt.parseInt(isize, pos_row_str, 10);

        it = std.mem.splitScalar(u8, velocity_str, ',');
        const vel_col_str = it.next().?;
        const vel_col = try std.fmt.parseInt(isize, vel_col_str[2..], 10);
        const vel_row_str = it.next().?;
        const vel_row = try std.fmt.parseInt(isize, vel_row_str, 10);

        try robots_list.append(.{
            .position = .{ .row = pos_row, .col = pos_col },
            .velocity = .{ .row = vel_row, .col = vel_col },
        });
    }

    return try robots_list.toOwnedSlice();
}

test parseBathroomRobotsFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day14/parseBathroomRobotsFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    const robots = try parseBathroomRobotsFile(allocator, "data/day14/test.txt");
    std.debug.print("\tcheck robots\n", .{});
    try std.testing.expectEqualDeep(&[_]Robot{
        .{ .position = .{ .col = 0, .row = 4 }, .velocity = .{ .col = 3, .row = -3 } },
        .{ .position = .{ .col = 6, .row = 3 }, .velocity = .{ .col = -1, .row = -3 } },
        .{ .position = .{ .col = 10, .row = 3 }, .velocity = .{ .col = -1, .row = 2 } },
        .{ .position = .{ .col = 2, .row = 0 }, .velocity = .{ .col = 2, .row = -1 } },
        .{ .position = .{ .col = 0, .row = 0 }, .velocity = .{ .col = 1, .row = 3 } },
        .{ .position = .{ .col = 3, .row = 0 }, .velocity = .{ .col = -2, .row = -2 } },
        .{ .position = .{ .col = 7, .row = 6 }, .velocity = .{ .col = -1, .row = -3 } },
        .{ .position = .{ .col = 3, .row = 0 }, .velocity = .{ .col = -1, .row = -2 } },
        .{ .position = .{ .col = 9, .row = 3 }, .velocity = .{ .col = 2, .row = 3 } },
        .{ .position = .{ .col = 7, .row = 3 }, .velocity = .{ .col = -1, .row = 2 } },
        .{ .position = .{ .col = 2, .row = 4 }, .velocity = .{ .col = 2, .row = -3 } },
        .{ .position = .{ .col = 9, .row = 5 }, .velocity = .{ .col = -3, .row = -3 } },
    }, robots);
}

const Map = struct {
    width: isize,
    height: isize,
};

fn robotPosition(map: Map, robot: Robot, time: isize) Position {
    return .{
        .row = @mod(robot.position.row + robot.velocity.row * time, map.height),
        .col = @mod(robot.position.col + robot.velocity.col * time, map.width),
    };
}

test robotPosition {
    std.debug.print("day14/robotPosition\n", .{});
    std.debug.print("\tcheck robot position at t=0\n", .{});
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 2 }, robotPosition(
        .{ .width = 11, .height = 7 },
        .{ .position = .{ .row = 4, .col = 2 }, .velocity = .{ .row = -3, .col = 2 } },
        0,
    ));
    std.debug.print("\tcheck robot position at t=1\n", .{});
    try std.testing.expectEqualDeep(Position{ .row = 1, .col = 4 }, robotPosition(
        .{ .width = 11, .height = 7 },
        .{ .position = .{ .row = 4, .col = 2 }, .velocity = .{ .row = -3, .col = 2 } },
        1,
    ));
    std.debug.print("\tcheck robot position at t=2 - wrap top\n", .{});
    try std.testing.expectEqualDeep(Position{ .row = 5, .col = 6 }, robotPosition(
        .{ .width = 11, .height = 7 },
        .{ .position = .{ .row = 4, .col = 2 }, .velocity = .{ .row = -3, .col = 2 } },
        2,
    ));
    std.debug.print("\tcheck robot position at t=3\n", .{});
    try std.testing.expectEqualDeep(Position{ .row = 2, .col = 8 }, robotPosition(
        .{ .width = 11, .height = 7 },
        .{ .position = .{ .row = 4, .col = 2 }, .velocity = .{ .row = -3, .col = 2 } },
        3,
    ));
    std.debug.print("\tcheck robot position at t=4 - wrap top\n", .{});
    try std.testing.expectEqualDeep(Position{ .row = 6, .col = 10 }, robotPosition(
        .{ .width = 11, .height = 7 },
        .{ .position = .{ .row = 4, .col = 2 }, .velocity = .{ .row = -3, .col = 2 } },
        4,
    ));
    std.debug.print("\tcheck robot position at t=5 - wrap right\n", .{});
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 1 }, robotPosition(
        .{ .width = 11, .height = 7 },
        .{ .position = .{ .row = 4, .col = 2 }, .velocity = .{ .row = -3, .col = 2 } },
        5,
    ));
}

pub fn moveRobots(map: Map, robots: []Robot, time: isize) void {
    for (robots, 0..) |robot, i| {
        robots[i].position = robotPosition(map, robot, time);
    }
}

test moveRobots {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day14/robotPositions\n", .{});
    std.debug.print("\tread input file\n", .{});
    const robots = try parseBathroomRobotsFile(allocator, "data/day14/test.txt");
    std.debug.print("\tmove robot time=100\n", .{});
    moveRobots(.{ .width = 11, .height = 7 }, robots, 100);
    std.debug.print("\tcheck robots positions at t=100\n", .{});
    try std.testing.expectEqualDeep(
        &[_]Robot{
            .{ .position = .{ .row = 5, .col = 3 }, .velocity = .{ .col = 3, .row = -3 } },
            .{ .position = .{ .row = 4, .col = 5 }, .velocity = .{ .col = -1, .row = -3 } },
            .{ .position = .{ .row = 0, .col = 9 }, .velocity = .{ .col = -1, .row = 2 } },
            .{ .position = .{ .row = 5, .col = 4 }, .velocity = .{ .col = 2, .row = -1 } },
            .{ .position = .{ .row = 6, .col = 1 }, .velocity = .{ .col = 1, .row = 3 } },
            .{ .position = .{ .row = 3, .col = 1 }, .velocity = .{ .col = -2, .row = -2 } },
            .{ .position = .{ .row = 0, .col = 6 }, .velocity = .{ .col = -1, .row = -3 } },
            .{ .position = .{ .row = 3, .col = 2 }, .velocity = .{ .col = -1, .row = -2 } },
            .{ .position = .{ .row = 2, .col = 0 }, .velocity = .{ .col = 2, .row = 3 } },
            .{ .position = .{ .row = 0, .col = 6 }, .velocity = .{ .col = -1, .row = 2 } },
            .{ .position = .{ .row = 5, .col = 4 }, .velocity = .{ .col = 2, .row = -3 } },
            .{ .position = .{ .row = 6, .col = 6 }, .velocity = .{ .col = -3, .row = -3 } },
        },
        robots,
    );
}

pub fn safetyFactor(map: Map, robots: []const Robot) usize {
    const width_half = @divFloor(map.width, 2);
    const height_half = @divFloor(map.height, 2);
    var quadrants = [_]usize{ 0, 0, 0, 0 };
    for (robots) |robot| {
        const position = robot.position;
        if (position.row < height_half and position.col < width_half) {
            quadrants[0] += 1;
        } else if (position.row > height_half and position.col < width_half) {
            quadrants[1] += 1;
        } else if (position.row < height_half and position.col > width_half) {
            quadrants[2] += 1;
        } else if (position.row > height_half and position.col > width_half) {
            quadrants[3] += 1;
        }
    }
    var safety_factor: usize = 1;
    for (quadrants) |quadrant| {
        safety_factor *= quadrant;
    }
    return safety_factor;
}

test safetyFactor {
    std.debug.print("day14/safetyFactor\n", .{});
    try std.testing.expectEqualDeep(12, safetyFactor(
        .{ .width = 11, .height = 7 },
        &[_]Robot{
            .{ .position = .{ .row = 5, .col = 3 }, .velocity = .{ .col = 3, .row = -3 } },
            .{ .position = .{ .row = 4, .col = 5 }, .velocity = .{ .col = -1, .row = -3 } },
            .{ .position = .{ .row = 0, .col = 9 }, .velocity = .{ .col = -1, .row = 2 } },
            .{ .position = .{ .row = 5, .col = 4 }, .velocity = .{ .col = 2, .row = -1 } },
            .{ .position = .{ .row = 6, .col = 1 }, .velocity = .{ .col = 1, .row = 3 } },
            .{ .position = .{ .row = 3, .col = 1 }, .velocity = .{ .col = -2, .row = -2 } },
            .{ .position = .{ .row = 0, .col = 6 }, .velocity = .{ .col = -1, .row = -3 } },
            .{ .position = .{ .row = 3, .col = 2 }, .velocity = .{ .col = -1, .row = -2 } },
            .{ .position = .{ .row = 2, .col = 0 }, .velocity = .{ .col = 2, .row = 3 } },
            .{ .position = .{ .row = 0, .col = 6 }, .velocity = .{ .col = -1, .row = 2 } },
            .{ .position = .{ .row = 5, .col = 4 }, .velocity = .{ .col = 2, .row = -3 } },
            .{ .position = .{ .row = 6, .col = 6 }, .velocity = .{ .col = -3, .row = -3 } },
        },
    ));
}

fn symetryScore(map: Map, robots: []const Robot) usize {
    const width_half = @divFloor(map.width, 2);
    var score: usize = 0;
    for (robots) |robot| {
        if (robot.position.col >= width_half) {
            continue;
        }
        for (robots) |other_robot| {
            if (other_robot.position.row == robot.position.row and
                other_robot.position.col == map.width - robot.position.col - 1)
            {
                score += 1;
                break;
            }
        }
    }
    return score;
}

pub fn maximalSymetryScore(map: Map, robots: []Robot) isize {
    const max_iterations = map.width * map.height;
    var max_score: usize = 0;
    var max_score_index: usize = 0;
    for (0..@intCast(max_iterations + 1)) |i| {
        moveRobots(map, robots, 1);
        const score = symetryScore(map, robots);
        if (score > max_score) {
            max_score = score;
            max_score_index = i + 1;
            // std.debug.print("{d:0>5} score={d}\n", .{ i + 1, score });
        }
    }
    return @intCast(max_score_index);
}
