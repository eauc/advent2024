const std = @import("std");

const Line = []u8;
const GuardMap = struct {
    map: []Line,
    height: usize,
    width: usize,
    pub fn init(map: []Line) GuardMap {
        return .{
            .map = map,
            .height = map.len,
            .width = map[0].len,
        };
    }
    pub fn deinit(self: *GuardMap, allocator: std.mem.Allocator) void {
        for (self.map) |line| {
            allocator.free(line);
        }
        allocator.free(self.map);
    }
    pub fn clone(self: *const GuardMap, allocator: std.mem.Allocator) !GuardMap {
        var clone_map = try allocator.alloc(Line, self.height);
        for (self.map, 0..) |line, row| {
            clone_map[row] = try allocator.alloc(u8, self.width);
            std.mem.copyForwards(u8, clone_map[row], line);
        }
        return GuardMap.init(clone_map);
    }
    pub fn copy(self: *const GuardMap, src: GuardMap) void {
        for (self.map, 0..) |line, row| {
            std.mem.copyForwards(u8, line, src.map[row]);
        }
    }
};

pub fn parseGuardMapFile(allocator: std.mem.Allocator, file_name: []const u8) !GuardMap {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var lines_list = std.ArrayList(Line).init(allocator);
    defer lines_list.deinit();

    var lineBuf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |readLineBuf| {
        const line = try allocator.alloc(u8, readLineBuf.len);
        std.mem.copyForwards(u8, line, readLineBuf);
        try lines_list.append(line);
    }

    return GuardMap.init(try lines_list.toOwnedSlice());
}

test parseGuardMapFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day06/parseGuardMapFile\n", .{});
    std.debug.print("\tread test input file\n", .{});
    const guard_map = try parseGuardMapFile(allocator, "data/day06/test.txt");
    std.debug.print("\tcheck map\n", .{});
    for (&[_][]const u8{
        "....#.....",
        ".........#",
        "..........",
        "..#.......",
        ".......#..",
        "..........",
        ".#..^.....",
        "........#.",
        "#.........",
        "......#...",
    }, 0..) |expected, row| {
        std.debug.print("\t  {s}\n", .{expected});
        try std.testing.expectEqualStrings(expected, guard_map.map[row]);
    }
}

const GuardPosition = struct {
    direction: enum { UP, DOWN, LEFT, RIGHT },
    row: usize,
    col: usize,
};

fn extractInitialGuardPosition(guard_map: GuardMap) GuardPosition {
    for (guard_map.map, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == '^') {
                return .{
                    .direction = .UP,
                    .row = row,
                    .col = col,
                };
            }
        }
    } else unreachable;
}

const Obstruction = struct {
    row: usize,
    col: usize,
};

test extractInitialGuardPosition {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day06/extractInitialGuardPosition\n", .{});
    std.debug.print("\tread test input file\n", .{});
    const guard_map = try parseGuardMapFile(allocator, "data/day06/test.txt");
    std.debug.print("\tcheck initial position\n", .{});
    try std.testing.expectEqual(GuardPosition{
        .direction = .UP,
        .row = 6,
        .col = 4,
    }, extractInitialGuardPosition(guard_map));
}

const GuardPath = struct {
    positions: std.ArrayList(GuardPosition),
    pub fn init(allocator: std.mem.Allocator) GuardPath {
        return .{
            .positions = std.ArrayList(GuardPosition).init(allocator),
        };
    }
    pub fn deinit(self: *GuardPath) void {
        self.positions.deinit();
    }
    pub fn addPosition(self: *GuardPath, position: GuardPosition) !void {
        for (self.positions.items) |pos| {
            if (pos.row == position.row and pos.col == position.col and pos.direction == position.direction) {
                return error.LoopDetected;
            }
        }
        try self.positions.append(position);
    }
};

fn guardIsExiting(guard_map: GuardMap, guard_position: GuardPosition) bool {
    switch (guard_position.direction) {
        .UP => {
            if (guard_position.row == 0) return true;
        },
        .DOWN => {
            if (guard_position.row == guard_map.height - 1) return true;
        },
        .LEFT => {
            if (guard_position.col == 0) return true;
        },
        .RIGHT => {
            if (guard_position.col == guard_map.width - 1) return true;
        },
    }
    return false;
}

fn advanceGuard(guard_position: GuardPosition) GuardPosition {
    var next_position = guard_position;
    switch (guard_position.direction) {
        .UP => {
            next_position.row -= 1;
        },
        .DOWN => {
            next_position.row += 1;
        },
        .LEFT => {
            next_position.col -= 1;
        },
        .RIGHT => {
            next_position.col += 1;
        },
    }
    return next_position;
}

fn turnGuardRight(guard_position: GuardPosition) GuardPosition {
    var next_position = guard_position;
    next_position.direction = switch (guard_position.direction) {
        .UP => .RIGHT,
        .DOWN => .LEFT,
        .LEFT => .UP,
        .RIGHT => .DOWN,
    };
    return next_position;
}

fn moveGuardUntilExit(allocator: std.mem.Allocator, guard_map: GuardMap, start_position: GuardPosition) ![]GuardPosition {
    var guard_path = GuardPath.init(allocator);
    defer guard_path.deinit();

    var guard_position = start_position;
    try guard_path.addPosition(start_position);
    while (true) {
        if (guardIsExiting(guard_map, guard_position)) break;
        const next_position = advanceGuard(guard_position);
        if (guard_map.map[next_position.row][next_position.col] == '#') {
            guard_position = turnGuardRight(guard_position);
            continue;
        }
        guard_position = next_position;
        try guard_path.addPosition(guard_position);
    }
    return try guard_path.positions.toOwnedSlice();
}

fn checkLoop(allocator: std.mem.Allocator, guard_map: GuardMap, start_position: GuardPosition) !bool {
    var guard_path = GuardPath.init(allocator);
    defer guard_path.deinit();

    var guard_position = start_position;
    try guard_path.addPosition(start_position);
    while (true) {
        if (guardIsExiting(guard_map, guard_position)) return false;
        const next_position = advanceGuard(guard_position);
        if (guard_map.map[next_position.row][next_position.col] == '#') {
            guard_position = turnGuardRight(guard_position);
            continue;
        }
        guard_position = next_position;
        guard_path.addPosition(guard_position) catch |err| {
            if (err == error.LoopDetected) return true;
        };
    } else unreachable;
}

fn findAllPossibleLoopObstructions(allocator: std.mem.Allocator, guard_map: GuardMap, start_position: GuardPosition, visited_positions: []GuardPosition) ![]Obstruction {
    var possible_loop_obstructions = std.ArrayList(Obstruction).init(allocator);
    defer possible_loop_obstructions.deinit();
    const new_guard_map = try guard_map.clone(allocator);
    for (visited_positions[1..]) |position| {
        new_guard_map.copy(guard_map);
        new_guard_map.map[position.row][position.col] = '#';

        const has_loop = try checkLoop(allocator, new_guard_map, start_position);
        if (has_loop) {
            std.debug.print("possible loop position: row={d} col={d} direction={s}\n", .{ position.row, position.col, @tagName(position.direction) });
            const existing: ?Obstruction = for (possible_loop_obstructions.items) |obstruction| {
                if (obstruction.row == position.row and obstruction.col == position.col) {
                    break obstruction;
                }
            } else null;
            if (existing) |_| {
                std.debug.print("-- already exists\n", .{});
            } else {
                try possible_loop_obstructions.append(Obstruction{ .row = position.row, .col = position.col });
            }
        }
    }
    return try possible_loop_obstructions.toOwnedSlice();
}

fn markGuardPosition(visited_map: GuardMap, guard_position: GuardPosition) void {
    visited_map.map[guard_position.row][guard_position.col] = switch (guard_position.direction) {
        .UP => '^',
        .DOWN => 'v',
        .LEFT => '<',
        .RIGHT => '>',
    };
}

pub fn visitGuardMap(allocator: std.mem.Allocator, guard_map: GuardMap) !GuardMap {
    const start_position = extractInitialGuardPosition(guard_map);

    const visited_positions = try moveGuardUntilExit(allocator, guard_map, start_position);
    defer allocator.free(visited_positions);

    const possible_loop_obstructions = try findAllPossibleLoopObstructions(allocator, guard_map, start_position, visited_positions);
    defer allocator.free(possible_loop_obstructions);
    std.debug.print("possible loop obstructions: {}\n", .{possible_loop_obstructions.len});

    const visited_map = try guard_map.clone(allocator);
    for (visited_positions) |position| {
        markGuardPosition(visited_map, position);
    }
    return visited_map;
}

pub fn countVisitedPositions(visited_map: GuardMap) usize {
    var count: usize = 0;
    for (visited_map.map) |line| {
        for (line) |char| {
            if (char == '^' or char == 'v' or char == '<' or char == '>') {
                count += 1;
            }
        }
    }
    return count;
}

test moveGuardUntilExit {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day06/parseGuardMapFile\n", .{});
    std.debug.print("\tread test input file\n", .{});
    const guard_map = try parseGuardMapFile(allocator, "data/day06/test.txt");
    std.debug.print("\tmove guard until exit\n", .{});
    const visited_map = try visitGuardMap(allocator, guard_map);
    for (&[_][]const u8{
        "....#.....",
        "....^>>>>#",
        "....^...v.",
        "..#.^...v.",
        "..^>>>>#v.",
        "..^.^.v.v.",
        ".#<<<<v<v.",
        ".^>>>>>>#.",
        "#<<<<<vv..",
        "......#v..",
    }, 0..) |expected, row| {
        std.debug.print("\t  {s}\n", .{expected});
        try std.testing.expectEqualStrings(expected, visited_map.map[row]);
    }
    std.debug.print("\tcount visited positions\n", .{});
    try std.testing.expectEqual(41, countVisitedPositions(visited_map));
}
