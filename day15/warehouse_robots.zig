const std = @import("std");

const Position = struct {
    row: usize,
    col: usize,
};

const WarehouseMap = struct {
    width: usize,
    height: usize,
    map: [][]u8,
    pub fn clone(warehouse_map: *const WarehouseMap, allocator: std.mem.Allocator) !WarehouseMap {
        const map = try allocator.alloc([]u8, warehouse_map.map.len);
        for (warehouse_map.map, 0..) |line, i| {
            map[i] = try allocator.dupe(u8, line);
        }
        return .{
            .width = warehouse_map.width,
            .height = warehouse_map.height,
            .map = map,
        };
    }
    pub fn deinit(warehouse_map: *WarehouseMap, allocator: std.mem.Allocator) void {
        for (warehouse_map.map) |line| {
            allocator.free(line);
        }
        allocator.free(warehouse_map.map);
    }
};

pub fn parseWarehouseMapFile(allocator: std.mem.Allocator, file_name: []const u8) !struct { warehouse_map: WarehouseMap, robot: Position, moves: []const u8 } {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var map_list = std.ArrayList([]u8).init(allocator);
    defer map_list.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |line| {
        if (line.len == 0) break;
        const map_line = try allocator.dupe(u8, line);
        try map_list.append(map_line);
    }

    const robot: Position = find_robot: for (map_list.items, 0..) |line, row| {
        for (line, 0..) |c, col| {
            if (c == '@') {
                map_list.items[row][col] = '.';
                break :find_robot Position{ .row = row, .col = col };
            }
        }
    } else return error.NoRobotFound;

    var moves_buf: ?[]u8 = null;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |line| {
        if (moves_buf) |moves| {
            moves_buf = try allocator.realloc(moves, moves.len + line.len);
            std.mem.copyForwards(u8, moves_buf.?[moves.len..], line);
        } else {
            moves_buf = try allocator.dupe(u8, line);
        }
    }

    return .{
        .warehouse_map = .{
            .width = map_list.items[0].len,
            .height = map_list.items.len,
            .map = try map_list.toOwnedSlice(),
        },
        .robot = robot,
        .moves = moves_buf.?,
    };
}

test parseWarehouseMapFile {
    const allocator = std.testing.allocator;

    std.debug.print("day15/parseWarehouseMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    var parse_result = try parseWarehouseMapFile(allocator, "data/day15/test.txt");
    defer parse_result.warehouse_map.deinit(allocator);
    defer allocator.free(parse_result.moves);

    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##########"),
            @constCast("#..O..O.O#"),
            @constCast("#......O.#"),
            @constCast("#.OO..O.O#"),
            @constCast("#..O...O.#"),
            @constCast("#O#..O...#"),
            @constCast("#O..O..O.#"),
            @constCast("#.OO.O.OO#"),
            @constCast("#....O...#"),
            @constCast("##########"),
        }),
    }, parse_result.warehouse_map);
    try std.testing.expectEqualDeep(Position{
        .row = 4,
        .col = 4,
    }, parse_result.robot);
    try std.testing.expectEqualDeep(
        "<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^",
        parse_result.moves,
    );
}

pub fn moveCrates(warehouse_map: WarehouseMap, starting_position: Position, move: u8) void {
    var map = warehouse_map.map;
    if (map[starting_position.row][starting_position.col] != 'O') {
        return;
    }
    switch (move) {
        '^' => {
            const next_empty_space = for (0..starting_position.row) |i| {
                if (map[starting_position.row - i - 1][starting_position.col] == '.') {
                    break i + 1;
                }
            } else unreachable;
            map[starting_position.row - next_empty_space][starting_position.col] = 'O';
        },
        'v' => {
            const next_empty_space = for (0..map.len - starting_position.row - 1) |i| {
                if (map[starting_position.row + i + 1][starting_position.col] == '.') {
                    break i + 1;
                }
            } else unreachable;
            map[starting_position.row + next_empty_space][starting_position.col] = 'O';
        },
        '>' => {
            const next_empty_space = for (0..map[starting_position.row].len - starting_position.col - 1) |i| {
                if (map[starting_position.row][starting_position.col + i + 1] == '.') {
                    break i + 1;
                }
            } else unreachable;
            map[starting_position.row][starting_position.col + next_empty_space] = 'O';
        },
        '<' => {
            const next_empty_space = for (0..starting_position.col) |i| {
                if (map[starting_position.row][starting_position.col - i - 1] == '.') {
                    break i + 1;
                }
            } else unreachable;
            map[starting_position.row][starting_position.col - next_empty_space] = 'O';
        },
        else => unreachable,
    }
    map[starting_position.row][starting_position.col] = '.';
}

fn moveIsBlocked(warehouse_map: WarehouseMap, next_position: Position, move: u8) bool {
    const map = warehouse_map.map;
    switch (move) {
        '^' => {
            for (0..next_position.row + 1) |i| {
                if (map[next_position.row - i][next_position.col] == '.') {
                    return false;
                }
                if (map[next_position.row - i][next_position.col] == '#') {
                    return true;
                }
            }
        },
        'v' => {
            for (0..map.len - next_position.row) |i| {
                if (map[next_position.row + i][next_position.col] == '.') {
                    return false;
                }
                if (map[next_position.row + i][next_position.col] == '#') {
                    return true;
                }
            }
        },
        '>' => {
            for (0..map[next_position.row].len - next_position.col) |i| {
                if (map[next_position.row][next_position.col + i] == '.') {
                    return false;
                }
                if (map[next_position.row][next_position.col + i] == '#') {
                    return true;
                }
            }
        },
        '<' => {
            for (0..next_position.col + 1) |i| {
                if (map[next_position.row][next_position.col - i] == '.') {
                    return false;
                }
                if (map[next_position.row][next_position.col - i] == '#') {
                    return true;
                }
            }
        },
        else => return false,
    }
    return false;
}

fn nextPosition(robot: Position, move: u8) Position {
    var next_position = robot;
    switch (move) {
        '^' => {
            next_position.row -= 1;
        },
        'v' => {
            next_position.row += 1;
        },
        '<' => {
            next_position.col -= 1;
        },
        '>' => {
            next_position.col += 1;
        },
        else => unreachable,
    }
    return next_position;
}

fn moveRobot(warehouse_map: WarehouseMap, robot: Position, move: u8) Position {
    const next_position = nextPosition(robot, move);
    if (moveIsBlocked(warehouse_map, next_position, move)) {
        // std.debug.print("isBlocked {}\n", .{next_position});
        return robot;
    }
    // std.debug.print("move {}\n", .{next_position});
    moveCrates(warehouse_map, next_position, move);
    return next_position;
}

test moveRobot {
    const allocator = std.testing.allocator;

    std.debug.print("day15/moveRobot\n", .{});
    var warehouse_map = try (WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#..O.O.#"),
            @constCast("##..O..#"),
            @constCast("#...O..#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#......#"),
            @constCast("########"),
        }),
    }).clone(allocator);
    defer warehouse_map.deinit(allocator);

    std.debug.print("\tmove #1: '<' blocked by wall -> no move\n", .{});
    var next_robot_position = moveRobot(warehouse_map, .{ .row = 2, .col = 2 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 2, .col = 2 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#..O.O.#"),
            @constCast("##..O..#"),
            @constCast("#...O..#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#......#"),
            @constCast("########"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #2: '^' no obstruction -> move up\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 2, .col = 2 }, '^');
    try std.testing.expectEqualDeep(Position{ .row = 1, .col = 2 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#..O.O.#"),
            @constCast("##..O..#"),
            @constCast("#...O..#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#......#"),
            @constCast("########"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #3: '^' blocked by wall -> no move\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 1, .col = 2 }, '^');
    try std.testing.expectEqualDeep(Position{ .row = 1, .col = 2 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#..O.O.#"),
            @constCast("##..O..#"),
            @constCast("#...O..#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#......#"),
            @constCast("########"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #4: '>' blocked by crate -> move right and move crate\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 1, .col = 2 }, '>');
    try std.testing.expectEqualDeep(Position{ .row = 1, .col = 3 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#...OO.#"),
            @constCast("##..O..#"),
            @constCast("#...O..#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#......#"),
            @constCast("########"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #5: '>' blocked by 2 crates -> move right with both crates\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 1, .col = 3 }, '>');
    try std.testing.expectEqualDeep(Position{ .row = 1, .col = 4 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#....OO#"),
            @constCast("##..O..#"),
            @constCast("#...O..#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#......#"),
            @constCast("########"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #6: '>' blocked by 2 crates and wall -> no move\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 1, .col = 4 }, '>');
    try std.testing.expectEqualDeep(Position{ .row = 1, .col = 4 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#....OO#"),
            @constCast("##..O..#"),
            @constCast("#...O..#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#......#"),
            @constCast("########"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #7: 'v' blocked by 4 crates -> move down with four crates\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 1, .col = 4 }, 'v');
    try std.testing.expectEqualDeep(Position{ .row = 2, .col = 4 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#....OO#"),
            @constCast("##.....#"),
            @constCast("#...O..#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#...O..#"),
            @constCast("########"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #8: 'v' blocked by 4 crates and wall -> no move\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 2, .col = 4 }, 'v');
    try std.testing.expectEqualDeep(Position{ .row = 2, .col = 4 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#....OO#"),
            @constCast("##.....#"),
            @constCast("#...O..#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#...O..#"),
            @constCast("########"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #8: '<' empty space -> move left\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 2, .col = 4 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 2, .col = 3 }, next_robot_position);

    std.debug.print("\tmove #9: 'v' empty space -> move down\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 2, .col = 3 }, 'v');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 3 }, next_robot_position);

    std.debug.print("\tmove #10: '>' blocked by 1 create -> move right with crate\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 3, .col = 3 }, '>');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 4 }, next_robot_position);

    std.debug.print("\tmove #11: '>' blocked by 1 create -> move right with crate\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 3, .col = 4 }, '>');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 5 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#....OO#"),
            @constCast("##.....#"),
            @constCast("#.....O#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#...O..#"),
            @constCast("########"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #12: 'v' empty space -> move down\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 3, .col = 5 }, 'v');
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 5 }, next_robot_position);

    std.debug.print("\tmove #13: '<' blocked by 1 create -> move left with crate\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 4, .col = 5 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 4 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#....OO#"),
            @constCast("##.....#"),
            @constCast("#.....O#"),
            @constCast("#.#O...#"),
            @constCast("#...O..#"),
            @constCast("#...O..#"),
            @constCast("########"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #14: '<' blocked by 1 create and a wall -> no move\n", .{});
    next_robot_position = moveRobot(warehouse_map, .{ .row = 4, .col = 4 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 4 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#....OO#"),
            @constCast("##.....#"),
            @constCast("#.....O#"),
            @constCast("#.#O...#"),
            @constCast("#...O..#"),
            @constCast("#...O..#"),
            @constCast("########"),
        }),
    }, warehouse_map);
}

pub fn moveRobotSequence(warehouse_map: WarehouseMap, starting_position: Position, moves: []const u8) Position {
    var current_position = starting_position;
    for (moves) |move| {
        current_position = moveRobot(warehouse_map, current_position, move);
    }
    return current_position;
}

test moveRobotSequence {
    const allocator = std.testing.allocator;

    std.debug.print("day15/moveRobotSequence\n", .{});
    var small_warehouse_map = try (WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#..O.O.#"),
            @constCast("##..O..#"),
            @constCast("#...O..#"),
            @constCast("#.#.O..#"),
            @constCast("#...O..#"),
            @constCast("#......#"),
            @constCast("########"),
        }),
    }).clone(allocator);
    defer small_warehouse_map.deinit(allocator);

    std.debug.print("\texecute all moves in sequences\n", .{});
    std.debug.print("\tsmall test\n", .{});
    var last_robot_position = moveRobotSequence(small_warehouse_map, .{ .row = 2, .col = 2 }, "<^^>>>vv<v>>v<<");
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 4 }, last_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#....OO#"),
            @constCast("##.....#"),
            @constCast("#.....O#"),
            @constCast("#.#O...#"),
            @constCast("#...O..#"),
            @constCast("#...O..#"),
            @constCast("########"),
        }),
    }, small_warehouse_map);

    std.debug.print("\tbig test\n", .{});
    var parse_result = try parseWarehouseMapFile(allocator, "data/day15/test.txt");
    defer parse_result.warehouse_map.deinit(allocator);
    defer allocator.free(parse_result.moves);

    last_robot_position = moveRobotSequence(parse_result.warehouse_map, parse_result.robot, parse_result.moves);
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 3 }, last_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##########"),
            @constCast("#.O.O.OOO#"),
            @constCast("#........#"),
            @constCast("#OO......#"),
            @constCast("#OO......#"),
            @constCast("#O#.....O#"),
            @constCast("#O.....OO#"),
            @constCast("#O.....OO#"),
            @constCast("#OO....OO#"),
            @constCast("##########"),
        }),
    }, parse_result.warehouse_map);
}

fn gpsCoordinate(position: Position) usize {
    return position.row * 100 + position.col;
}

test gpsCoordinate {
    std.debug.print("day15/gpsCoordinate\n", .{});
    try std.testing.expectEqual(104, gpsCoordinate(.{ .row = 1, .col = 4 }));
}

pub fn sumBoxGpsCoordinates(warehouse_map: WarehouseMap) usize {
    var sum: usize = 0;
    for (warehouse_map.map, 0..) |line, row| {
        for (line, 0..) |cell, col| {
            if (cell == 'O' or cell == '[') {
                sum += gpsCoordinate(.{ .row = row, .col = col });
            }
        }
    }
    return sum;
}

test sumBoxGpsCoordinates {
    std.debug.print("day15/sumBoxGpsCoordinates\n", .{});
    std.debug.print("\tsmall test\n", .{});
    try std.testing.expectEqual(2028, sumBoxGpsCoordinates(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("########"),
            @constCast("#....OO#"),
            @constCast("##.....#"),
            @constCast("#.....O#"),
            @constCast("#.#O...#"),
            @constCast("#...O..#"),
            @constCast("#...O..#"),
            @constCast("########"),
        }),
    }));
    std.debug.print("\tbig test\n", .{});
    try std.testing.expectEqual(10092, sumBoxGpsCoordinates(WarehouseMap{
        .width = 10,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##########"),
            @constCast("#.O.O.OOO#"),
            @constCast("#........#"),
            @constCast("#OO......#"),
            @constCast("#OO......#"),
            @constCast("#O#.....O#"),
            @constCast("#O.....OO#"),
            @constCast("#O.....OO#"),
            @constCast("#OO....OO#"),
            @constCast("##########"),
        }),
    }));
}

pub fn parseWideWarehouseMapFile(allocator: std.mem.Allocator, file_name: []const u8) !struct { warehouse_map: WarehouseMap, robot: Position, moves: []const u8 } {
    var parse_result = try parseWarehouseMapFile(allocator, file_name);
    defer parse_result.warehouse_map.deinit(allocator);
    const wide_map = try allocator.alloc([]u8, parse_result.warehouse_map.height);
    for (wide_map, 0..) |_, row| {
        wide_map[row] = try allocator.alloc(u8, parse_result.warehouse_map.width * 2);
        for (parse_result.warehouse_map.map[row], 0..) |cell, col| {
            switch (cell) {
                'O' => {
                    wide_map[row][2 * col] = '[';
                    wide_map[row][2 * col + 1] = ']';
                },
                else => {
                    wide_map[row][2 * col] = cell;
                    wide_map[row][2 * col + 1] = cell;
                },
            }
        }
    }
    return .{
        .warehouse_map = .{
            .width = parse_result.warehouse_map.width * 2,
            .height = parse_result.warehouse_map.height,
            .map = wide_map,
        },
        .robot = .{
            .row = parse_result.robot.row,
            .col = parse_result.robot.col * 2,
        },
        .moves = parse_result.moves,
    };
}

test parseWideWarehouseMapFile {
    const allocator = std.testing.allocator;

    std.debug.print("day15/parseWideWarehouseMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    var parse_result = try parseWideWarehouseMapFile(allocator, "data/day15/test.txt");
    defer parse_result.warehouse_map.deinit(allocator);
    defer allocator.free(parse_result.moves);

    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("####################"),
            @constCast("##....[]....[]..[]##"),
            @constCast("##............[]..##"),
            @constCast("##..[][]....[]..[]##"),
            @constCast("##....[]......[]..##"),
            @constCast("##[]##....[]......##"),
            @constCast("##[]....[]....[]..##"),
            @constCast("##..[][]..[]..[][]##"),
            @constCast("##........[]......##"),
            @constCast("####################"),
        }),
    }, parse_result.warehouse_map);
    try std.testing.expectEqualDeep(Position{
        .row = 4,
        .col = 8,
    }, parse_result.robot);
    try std.testing.expectEqualDeep(
        "<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^",
        parse_result.moves,
    );
}

fn crateOtherHalf(warehouse_map: WarehouseMap, position: Position) Position {
    const map = warehouse_map.map;
    const cell = map[position.row][position.col];
    return if (cell == '[')
        .{ .row = position.row, .col = position.col + 1 }
    else
        .{ .row = position.row, .col = position.col - 1 };
}

fn moveCrateHalf(warehouse_map: WarehouseMap, crate_position: Position, move: u8) void {
    var map = warehouse_map.map;
    const next_position = nextPosition(crate_position, move);

    moveCratesWide(warehouse_map, next_position, move);

    // const cell = map[crate_position.row][crate_position.col];
    // std.debug.print("moving '{c}' from {any} to {any}\n", .{ cell, crate_position, next_position });
    map[next_position.row][next_position.col] = map[crate_position.row][crate_position.col];
    map[crate_position.row][crate_position.col] = '.';
}

pub fn moveCratesWide(warehouse_map: WarehouseMap, starting_position: Position, move: u8) void {
    var map = warehouse_map.map;
    // std.debug.print("moveCratesWide '{c}' {any}='{c}'\n", .{ move, starting_position, map[starting_position.row][starting_position.col] });
    if (map[starting_position.row][starting_position.col] != '[' and map[starting_position.row][starting_position.col] != ']') {
        return;
    }
    switch (move) {
        '^', 'v' => {
            const other_half = crateOtherHalf(warehouse_map, starting_position);
            moveCrateHalf(warehouse_map, starting_position, move);
            moveCrateHalf(warehouse_map, other_half, move);
        },
        '>' => {
            const next_empty_space = for (0..map[starting_position.row].len - starting_position.col - 1) |i| {
                if (map[starting_position.row][starting_position.col + i + 1] == '.') {
                    break i + 1;
                }
            } else unreachable;
            std.mem.copyBackwards(
                u8,
                map[starting_position.row][starting_position.col + 1 .. starting_position.col + next_empty_space + 1],
                map[starting_position.row][starting_position.col .. starting_position.col + next_empty_space],
            );
            map[starting_position.row][starting_position.col] = '.';
        },
        '<' => {
            const next_empty_space = for (0..starting_position.col) |i| {
                if (map[starting_position.row][starting_position.col - i - 1] == '.') {
                    break i + 1;
                }
            } else unreachable;
            std.mem.copyForwards(
                u8,
                map[starting_position.row][starting_position.col - next_empty_space .. starting_position.col],
                map[starting_position.row][starting_position.col - next_empty_space + 1 .. starting_position.col + 1],
            );
            map[starting_position.row][starting_position.col] = '.';
        },
        else => unreachable,
    }
}

fn moveIsBlockedWide(warehouse_map: WarehouseMap, next_position: Position, move: u8) bool {
    const map = warehouse_map.map;
    // std.debug.print("moveIsBlockedWide '{c}' {any}='{c}'\n", .{ move, next_position, map[next_position.row][next_position.col] });
    if (map[next_position.row][next_position.col] == '.') {
        return false;
    }
    if (map[next_position.row][next_position.col] == '#') {
        return true;
    }
    switch (move) {
        '^', 'v' => {
            const other_half = crateOtherHalf(warehouse_map, next_position);
            return moveIsBlockedWide(warehouse_map, nextPosition(next_position, move), move) or
                moveIsBlockedWide(warehouse_map, nextPosition(other_half, move), move);
        },
        '>' => {
            for (0..map[next_position.row].len - next_position.col) |i| {
                if (map[next_position.row][next_position.col + i] == '.') {
                    return false;
                }
                if (map[next_position.row][next_position.col + i] == '#') {
                    return true;
                }
            }
        },
        '<' => {
            for (0..next_position.col + 1) |i| {
                if (map[next_position.row][next_position.col - i] == '.') {
                    return false;
                }
                if (map[next_position.row][next_position.col - i] == '#') {
                    return true;
                }
            }
        },
        else => return false,
    }
    return false;
}

fn moveRobotWide(warehouse_map: WarehouseMap, robot: Position, move: u8) Position {
    const next_position = nextPosition(robot, move);
    if (moveIsBlockedWide(warehouse_map, next_position, move)) {
        // std.debug.print("isBlocked {}\n", .{next_position});
        return robot;
    }
    // std.debug.print("move {}\n", .{next_position});
    moveCratesWide(warehouse_map, next_position, move);
    return next_position;
}

test moveRobotWide {
    const allocator = std.testing.allocator;

    std.debug.print("day15/moveRobotWide\n", .{});
    var warehouse_map = try (WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##############"),
            @constCast("##......##..##"),
            @constCast("##..........##"),
            @constCast("##....[][]..##"),
            @constCast("##....[]....##"),
            @constCast("##..........##"),
            @constCast("##############"),
        }),
    }).clone(allocator);
    defer warehouse_map.deinit(allocator);
    var warehouse_map_right = try warehouse_map.clone(allocator);
    defer warehouse_map_right.deinit(allocator);
    var warehouse_map_left = try warehouse_map.clone(allocator);
    defer warehouse_map_left.deinit(allocator);
    var warehouse_map_down = try warehouse_map.clone(allocator);
    defer warehouse_map_down.deinit(allocator);

    std.debug.print("\tmove #1: '<' blocked by 2 crates -> move left with the 2 crates\n", .{});
    var next_robot_position = moveRobotWide(warehouse_map, .{ .row = 3, .col = 10 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 9 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##############"),
            @constCast("##......##..##"),
            @constCast("##..........##"),
            @constCast("##...[][]...##"),
            @constCast("##....[]....##"),
            @constCast("##..........##"),
            @constCast("##############"),
        }),
    }, warehouse_map);

    std.debug.print("\tmoves #2-5: 'vv<<' empty -> move robot\n", .{});
    next_robot_position = moveRobotWide(warehouse_map, .{ .row = 3, .col = 9 }, 'v');
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 9 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map, .{ .row = 4, .col = 9 }, 'v');
    try std.testing.expectEqualDeep(Position{ .row = 5, .col = 9 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map, .{ .row = 5, .col = 9 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 5, .col = 8 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map, .{ .row = 5, .col = 8 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 5, .col = 7 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##############"),
            @constCast("##......##..##"),
            @constCast("##..........##"),
            @constCast("##...[][]...##"),
            @constCast("##....[]....##"),
            @constCast("##..........##"),
            @constCast("##############"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #6: '^' blocked by 3 crates -> move up with the 3 crates\n", .{});
    next_robot_position = moveRobotWide(warehouse_map, .{ .row = 5, .col = 7 }, '^');
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 7 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##############"),
            @constCast("##......##..##"),
            @constCast("##...[][]...##"),
            @constCast("##....[]....##"),
            @constCast("##..........##"),
            @constCast("##..........##"),
            @constCast("##############"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #6: '^' blocked by 3 crates and a wall -> no move\n", .{});
    next_robot_position = moveRobotWide(warehouse_map, .{ .row = 4, .col = 7 }, '^');
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 7 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##############"),
            @constCast("##......##..##"),
            @constCast("##...[][]...##"),
            @constCast("##....[]....##"),
            @constCast("##..........##"),
            @constCast("##..........##"),
            @constCast("##############"),
        }),
    }, warehouse_map);

    std.debug.print("\tmoves #7-9: '<<^' empty -> move robot\n", .{});
    next_robot_position = moveRobotWide(warehouse_map, .{ .row = 4, .col = 7 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 6 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map, .{ .row = 4, .col = 6 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 4, .col = 5 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map, .{ .row = 4, .col = 5 }, '^');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 5 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##############"),
            @constCast("##......##..##"),
            @constCast("##...[][]...##"),
            @constCast("##....[]....##"),
            @constCast("##..........##"),
            @constCast("##..........##"),
            @constCast("##############"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove #10: '^' blocked by 1 crate -> move up with crate\n", .{});
    next_robot_position = moveRobotWide(warehouse_map, .{ .row = 3, .col = 5 }, '^');
    try std.testing.expectEqualDeep(Position{ .row = 2, .col = 5 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##############"),
            @constCast("##...[].##..##"),
            @constCast("##.....[]...##"),
            @constCast("##....[]....##"),
            @constCast("##..........##"),
            @constCast("##..........##"),
            @constCast("##############"),
        }),
    }, warehouse_map);

    std.debug.print("\tmove right: '>' blocked by 2 crates -> move right with the 2 crates until blocked by wall\n", .{});
    next_robot_position = moveRobotWide(warehouse_map_right, .{ .row = 3, .col = 5 }, '>');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 6 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map_right, .{ .row = 3, .col = 6 }, '>');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 7 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map_right, .{ .row = 3, .col = 7 }, '>');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 7 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##############"),
            @constCast("##......##..##"),
            @constCast("##..........##"),
            @constCast("##......[][]##"),
            @constCast("##....[]....##"),
            @constCast("##..........##"),
            @constCast("##############"),
        }),
    }, warehouse_map_right);

    std.debug.print("\tmove left: '<' blocked by 2 crates -> move left with the 2 crates until blocked by wall\n", .{});
    next_robot_position = moveRobotWide(warehouse_map_left, .{ .row = 3, .col = 10 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 9 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map_left, .{ .row = 3, .col = 9 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 8 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map_left, .{ .row = 3, .col = 8 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 7 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map_left, .{ .row = 3, .col = 7 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 6 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map_left, .{ .row = 3, .col = 6 }, '<');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 6 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##############"),
            @constCast("##......##..##"),
            @constCast("##..........##"),
            @constCast("##[][]......##"),
            @constCast("##....[]....##"),
            @constCast("##..........##"),
            @constCast("##############"),
        }),
    }, warehouse_map_left);

    std.debug.print("\tmove down: 'v' blocked by 2 crates -> move down with the 2 crates until blocked by wall\n", .{});
    next_robot_position = moveRobotWide(warehouse_map_down, .{ .row = 2, .col = 6 }, 'v');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 6 }, next_robot_position);
    next_robot_position = moveRobotWide(warehouse_map_down, .{ .row = 3, .col = 6 }, 'v');
    try std.testing.expectEqualDeep(Position{ .row = 3, .col = 6 }, next_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("##############"),
            @constCast("##......##..##"),
            @constCast("##..........##"),
            @constCast("##......[]..##"),
            @constCast("##....[]....##"),
            @constCast("##....[]....##"),
            @constCast("##############"),
        }),
    }, warehouse_map_down);
}

pub fn moveRobotWideSequence(warehouse_map: WarehouseMap, starting_position: Position, moves: []const u8) Position {
    var current_position = starting_position;
    for (moves) |move| {
        current_position = moveRobotWide(warehouse_map, current_position, move);
    }
    return current_position;
}

test moveRobotWideSequence {
    const allocator = std.testing.allocator;

    std.debug.print("day15/moveRobotWideSequence\n", .{});
    std.debug.print("\tparse input file\n", .{});
    var parse_result = try parseWideWarehouseMapFile(allocator, "data/day15/test.txt");
    defer parse_result.warehouse_map.deinit(allocator);
    defer allocator.free(parse_result.moves);

    std.debug.print("\texecute all moves in sequences\n", .{});
    const last_robot_position = moveRobotWideSequence(parse_result.warehouse_map, parse_result.robot, parse_result.moves);
    try std.testing.expectEqualDeep(Position{ .row = 7, .col = 4 }, last_robot_position);
    try std.testing.expectEqualDeep(WarehouseMap{
        .width = 20,
        .height = 10,
        .map = @constCast(&[_][]u8{
            @constCast("####################"),
            @constCast("##[].......[].[][]##"),
            @constCast("##[]...........[].##"),
            @constCast("##[]........[][][]##"),
            @constCast("##[]......[]....[]##"),
            @constCast("##..##......[]....##"),
            @constCast("##..[]............##"),
            @constCast("##.........[].[][]##"),
            @constCast("##......[][]..[]..##"),
            @constCast("####################"),
        }),
    }, parse_result.warehouse_map);
    try std.testing.expectEqual(9021, sumBoxGpsCoordinates(parse_result.warehouse_map));
}
