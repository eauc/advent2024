const std = @import("std");

const Position = struct {
    row: usize,
    col: usize,
    pub fn equal(a: *const Position, b: Position) bool {
        return a.row == b.row and a.col == b.col;
    }
    pub fn distance(a: *const Position, b: Position) usize {
        return (if (a.row > b.row) a.row - b.row else b.row - a.row) +
            (if (a.col > b.col) a.col - b.col else b.col - a.col);
    }
};

const Direction = enum { NORTH, EAST, SOUTH, WEST };
const Turn = enum { NONE, LEFT, RIGHT };

const PathItem = struct {
    position: Position,
    direction: Direction,
    cost: usize,
    pub fn equal(a: *const PathItem, b: PathItem) bool {
        return a.position.equal(b.position) and a.direction == b.direction;
    }
    pub fn score(self: *const PathItem, start_position: Position) usize {
        return self.position.distance(start_position);
    }
    pub fn bufPrintKey(self: *const PathItem, buf: []u8) ![]u8 {
        return std.fmt.bufPrint(buf, "{d},{d},{s}", .{
            self.position.row,
            self.position.col,
            @tagName(self.direction),
        });
    }
    pub fn bufPrint(self: *const PathItem, buf: []u8) []u8 {
        return std.fmt.bufPrint(buf, "[{d},{d},{s}]={d}", .{
            self.position.row,
            self.position.col,
            @tagName(self.direction),
            self.cost,
        }) catch unreachable;
    }
};

const Path = struct {
    path: std.ArrayList(PathItem),
    pub fn create(allocator: std.mem.Allocator) Path {
        const path = std.ArrayList(PathItem).init(allocator);
        return .{ .path = path };
    }
    pub fn clone(other: *const Path) !Path {
        return Path{ .path = try other.path.clone() };
    }
    pub fn contains(self: *const Path, item: PathItem) bool {
        for (self.path.items) |path_item| {
            if (path_item.equal(item)) {
                return true;
            }
        }
        return false;
    }
    pub fn append(self: *Path, item: PathItem) !void {
        if (self.contains(item)) {
            return error.PathLoop;
        }
        try self.path.append(item);
    }
    pub fn head(self: *const Path) PathItem {
        return self.path.items[self.path.items.len - 1];
    }
    pub fn cost(self: *const Path) usize {
        return self.head().cost;
    }
    pub fn score(self: *const Path, start_position: Position) usize {
        return self.head().score(start_position);
    }
    pub fn turnEast(self: *Path) !void {
        const h = self.head();
        switch (h.direction) {
            .NORTH => try self.append(.{
                .position = h.position,
                .direction = .EAST,
                .cost = h.cost + 1000,
            }),
            .SOUTH => try self.append(.{
                .position = h.position,
                .direction = .EAST,
                .cost = h.cost + 1000,
            }),
            .WEST => try self.append(.{
                .position = h.position,
                .direction = .EAST,
                .cost = h.cost + 2000,
            }),
            .EAST => {},
        }
    }
    pub fn bufPrintHead(self: *const Path, buf: []u8) []u8 {
        var printed: usize = 0;
        var b = self.head().bufPrint(buf);
        printed += b.len;
        b = std.fmt.bufPrint(buf[printed..], " ({d})", .{self.path.items.len}) catch unreachable;
        printed += b.len;
        return buf[0..printed];
    }
    pub fn bufPrint(self: *const Path, buf: []u8) []u8 {
        var printed: usize = 0;
        var b = std.fmt.bufPrint(buf[printed..], "path\n", .{}) catch unreachable;
        printed += b.len;
        for (self.path.items) |item| {
            b = item.bufPrint(buf[printed..]);
            printed += b.len;
            b = std.fmt.bufPrint(buf[printed..], "\n", .{}) catch unreachable;
            printed += b.len;
        }
        return buf[0 .. printed - 1];
    }
    pub fn deinit(self: *Path) void {
        self.path.deinit();
    }
};

const Paths = struct {
    paths: std.ArrayList(Path),
    min_costs: std.StringHashMap(usize),
    pub fn init(allocator: std.mem.Allocator, maze_map: MazeMap, exit_position: Position) !Paths {
        var key_buf = [1]u8{0} ** 100;
        var paths = std.ArrayList(Path).init(allocator);
        var min_costs = std.StringHashMap(usize).init(allocator);
        for ([_]Direction{ .NORTH, .SOUTH, .WEST, .EAST }) |direction| {
            const preceding_position = precedingPosition(exit_position, direction, .NONE);
            if (!maze_map.isWall(preceding_position)) {
                const new_head = PathItem{
                    .position = exit_position,
                    .direction = direction,
                    .cost = 0,
                };

                var path = Path.create(allocator);
                try path.append(new_head);
                try paths.append(path);

                const key = try new_head.bufPrintKey(&key_buf);
                try min_costs.put(try allocator.dupe(u8, key), 0);
            }
        }
        return .{
            .paths = paths,
            .min_costs = min_costs,
        };
    }
    pub fn keepPathsWithCost(self: *const Paths, cost: usize) !Paths {
        var paths_list = std.ArrayList(Path).init(self.paths.allocator);
        for (self.paths.items) |path| {
            if (path.head().cost == cost) {
                try paths_list.append(try path.clone());
            }
        }
        if (paths_list.items.len == 0) {
            return error.NoPathFound;
        }
        return .{
            .paths = paths_list,
            .min_costs = std.StringHashMap(usize).init(paths_list.allocator),
        };
    }
    pub fn nth(self: *const Paths, index: usize) *Path {
        return &self.paths.items[index];
    }
    pub fn head(self: *const Paths, index: usize) PathItem {
        return self.nth(index).head();
    }
    pub fn findMinScorePathIndex(self: *const Paths, optimal_cost: usize, start_position: Position) !usize {
        var min_index: usize = self.paths.items.len;
        var min_score: usize = std.math.maxInt(usize);
        for (self.paths.items, 0..) |path, index| {
            if (path.score(start_position) < min_score and
                path.head().cost < optimal_cost)
            {
                min_index = index;
                min_score = path.score(start_position);
            }
        }
        if (min_index >= self.paths.items.len) {
            return error.NoPathFound;
        }
        return min_index;
    }
    pub fn checkMinCost(self: *const Paths, key: []const u8, new_cost: usize) bool {
        const min_cost_ptr = self.min_costs.getPtr(key);
        if (min_cost_ptr) |min_cost| {
            if (new_cost > min_cost.*) {
                return false;
            }
        }
        return true;
    }
    pub fn updateMinCost(self: *Paths, key: []const u8, new_cost: usize) !bool {
        const min_cost_ptr = self.min_costs.getPtr(key);
        if (min_cost_ptr) |min_cost| {
            min_cost.* = new_cost;
        } else {
            try self.min_costs.put(try self.min_costs.allocator.dupe(u8, key), new_cost);
        }
        return true;
    }
    pub fn grow(self: *Paths, path_index: usize, new_head: PathItem) !bool {
        var key_buf = [1]u8{0} ** 100;
        const key = try new_head.bufPrintKey(&key_buf);
        if (!self.checkMinCost(key, new_head.cost)) {
            return false;
        }

        self.nth(path_index).append(new_head) catch |err| {
            switch (err) {
                error.PathLoop => return false,
                else => return err,
            }
        };

        return self.updateMinCost(key, new_head.cost);
    }
    pub fn branch(self: *Paths, path_index: usize, new_head: PathItem) !bool {
        var key_buf = [1]u8{0} ** 100;
        const key = try new_head.bufPrintKey(&key_buf);
        if (!self.checkMinCost(key, new_head.cost)) {
            return false;
        }

        var new_path = try self.nth(path_index).clone();
        new_path.append(new_head) catch |err| {
            switch (err) {
                error.PathLoop => {
                    new_path.deinit();
                    return false;
                },
                else => return err,
            }
        };
        try self.paths.append(new_path);

        return self.updateMinCost(key, new_head.cost);
    }
    pub fn remove(self: *Paths, index: usize) void {
        self.nth(index).deinit();
        _ = self.paths.swapRemove(index);
    }
    pub fn bufPrintHeads(self: *const Paths, buf: []u8) []u8 {
        var printed: usize = 0;
        for (self.paths.items) |path| {
            var b = path.bufPrintHead(buf[printed..]);
            printed += b.len;
            b = std.fmt.bufPrint(buf[printed..], "\n", .{}) catch unreachable;
            printed += b.len;
        }
        return buf[0 .. printed - 1];
    }
    pub fn bufPrint(self: *const Paths, buf: []u8) []u8 {
        var printed: usize = 0;
        for (self.paths.items) |path| {
            var b = path.bufPrint(buf[printed..]);
            printed += b.len;
            b = std.fmt.bufPrint(buf[printed..], "\n", .{}) catch unreachable;
            printed += b.len;
        }
        return buf[0 .. printed - 1];
    }
    pub fn deinit(self: *Paths) void {
        for (self.paths.items) |*path| {
            path.deinit();
        }
        self.paths.deinit();
        var keys = self.min_costs.keyIterator();
        while (keys.next()) |key| {
            self.min_costs.allocator.free(key.*);
        }
        self.min_costs.deinit();
    }
};

const MazeMap = struct {
    allocator: ?std.mem.Allocator,
    width: usize,
    height: usize,
    map: []const []const u8,
    pub fn create(allocator: ?std.mem.Allocator, lines: []const []const u8) MazeMap {
        return .{
            .allocator = allocator,
            .width = lines[0].len,
            .height = lines.len,
            .map = lines,
        };
    }
    pub fn isWall(self: *const MazeMap, position: Position) bool {
        return self.map[position.row][position.col] == '#';
    }
    pub fn deinit(self: *MazeMap) void {
        if (self.allocator) |allocator| {
            for (self.map) |line| {
                allocator.free(line);
            }
            allocator.free(self.map);
        }
    }
};

pub fn parseReindeerMazeMapFile(allocator: std.mem.Allocator, file_name: []const u8) !struct {
    maze_map: MazeMap,
    start_position: Position,
    exit_position: Position,
} {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var lines_list = std.ArrayList([]const u8).init(allocator);
    defer lines_list.deinit();

    var lineBuf: [25 * 100000]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |maze_line| {
        const line = try allocator.dupe(u8, maze_line);
        try lines_list.append(line);
    }
    const start_position: Position = start_position: for (lines_list.items, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == 'S') {
                break :start_position .{ .row = row, .col = col };
            }
        }
    } else return error.StartPositionNotFound;
    const exit_position: Position = exit_position: for (lines_list.items, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == 'E') {
                break :exit_position .{ .row = row, .col = col };
            }
        }
    } else return error.ExitPositionNotFound;
    return .{
        .maze_map = MazeMap.create(allocator, try lines_list.toOwnedSlice()),
        .start_position = start_position,
        .exit_position = exit_position,
    };
}

test parseReindeerMazeMapFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day16/parseReindeerMazeMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    var parse_result = try parseReindeerMazeMapFile(allocator, "data/day16/test.txt");
    defer parse_result.maze_map.deinit();

    const maze_map = parse_result.maze_map;
    const start_position = parse_result.start_position;
    const exit_position = parse_result.exit_position;
    try std.testing.expectEqualDeep(Position{ .row = 15, .col = 1 }, start_position);
    try std.testing.expectEqualDeep(Position{ .row = 1, .col = 15 }, exit_position);
    try std.testing.expectEqualDeep(MazeMap{
        .allocator = allocator,
        .width = 17,
        .height = 17,
        .map = &[_][]const u8{
            "#################",
            "#...#...#...#..E#",
            "#.#.#.#.#.#.#.#.#",
            "#.#.#.#...#...#.#",
            "#.#.#.#.###.#.#.#",
            "#...#.#.#.....#.#",
            "#.#.#.#.#.#####.#",
            "#.#...#.#.#.....#",
            "#.#.#####.#.###.#",
            "#.#.#.......#...#",
            "#.#.###.#####.###",
            "#.#.#...#.....#.#",
            "#.#.#.#####.###.#",
            "#.#.#.........#.#",
            "#.#.#.#########.#",
            "#S#.............#",
            "#################",
        },
    }, maze_map);
}

fn precedingDirection(direction: Direction, turn: Turn) Direction {
    if (turn == .LEFT) {
        return switch (direction) {
            .NORTH => .EAST,
            .SOUTH => .WEST,
            .WEST => .NORTH,
            .EAST => .SOUTH,
        };
    }
    if (turn == .RIGHT) {
        return switch (direction) {
            .NORTH => .WEST,
            .SOUTH => .EAST,
            .WEST => .SOUTH,
            .EAST => .NORTH,
        };
    }
    return direction;
}

fn precedingPosition(position: Position, direction: Direction, turn: Turn) Position {
    if (turn != .NONE) {
        return precedingPosition(position, precedingDirection(direction, turn), .NONE);
    }
    return switch (direction) {
        .NORTH => .{ .row = position.row + 1, .col = position.col },
        .SOUTH => .{ .row = position.row - 1, .col = position.col },
        .WEST => .{ .row = position.row, .col = position.col + 1 },
        .EAST => .{ .row = position.row, .col = position.col - 1 },
    };
}

test { // Paths.init
    const allocator = std.testing.allocator;
    const maze_map = MazeMap.create(
        null,
        &[_][]const u8{
            "###############",
            "#.......#....E#",
            "#.#.###.#.###.#",
            "#.....#.#...#.#",
            "#.###.#####.#.#",
            "#.#.#.......#.#",
            "#.#.#####.###.#",
            "#...........#.#",
            "###.#.#####.#.#",
            "#...#.....#.#.#",
            "#.#.#.###.#.#.#",
            "#.....#...#.#.#",
            "#.###.#.#.#.#.#",
            "#S..#.....#...#",
            "###############",
        },
    );
    var print_buf = [1]u8{0} ** 100000;

    std.debug.print("day16/Paths.init\n", .{});
    var paths = try Paths.init(allocator, maze_map, Position{ .row = 1, .col = 13 });
    defer paths.deinit();

    try std.testing.expectEqualStrings(
        \\path
        \\[1,13,NORTH]=0
        \\path
        \\[1,13,EAST]=0
    , paths.bufPrint(&print_buf));
}

fn precedingPathItems(maze_map: MazeMap, path_item: PathItem, result_buf: *[3]PathItem) []PathItem {
    var result_count: usize = 0;

    var preceding = precedingPosition(path_item.position, path_item.direction, .NONE);
    if (!maze_map.isWall(preceding)) {
        result_buf[result_count] = .{
            .position = preceding,
            .direction = path_item.direction,
            .cost = path_item.cost + 1,
        };
        result_count += 1;
    }
    for ([_]Turn{ .LEFT, .RIGHT }) |turn| {
        preceding = precedingPosition(path_item.position, path_item.direction, turn);
        if (!maze_map.isWall(preceding)) {
            result_buf[result_count] = .{
                .position = preceding,
                .direction = precedingDirection(path_item.direction, turn),
                .cost = path_item.cost + 1001,
            };
            result_count += 1;
        }
    }

    return result_buf[0..result_count];
}

test precedingPathItems {
    const maze_map = MazeMap.create(
        null,
        &[_][]const u8{
            "###############",
            "#.......#....E#",
            "#.#.###.#.###.#",
            "#.....#.#...#.#",
            "#.###.#####.#.#",
            "#.#.#.......#.#",
            "#.#.#####.###.#",
            "#...........#.#",
            "###.#.#####.#.#",
            "#...#.....#.#.#",
            "#.#.#.###.#.#.#",
            "#.....#...#.#.#",
            "#.###.#.#.#.#.#",
            "#S..#.....#...#",
            "###############",
        },
    );
    var result_buf: [3]PathItem = undefined;

    std.debug.print("day16/precedingPathItems\n", .{});
    std.debug.print("\tNORTH with only no turn available\n", .{});
    try std.testing.expectEqualDeep(
        &[_]PathItem{
            .{
                .position = Position{ .row = 3, .col = 13 },
                .direction = .NORTH,
                .cost = 2,
            },
        },
        precedingPathItems(maze_map, PathItem{
            .position = Position{ .row = 2, .col = 13 },
            .direction = .NORTH,
            .cost = 1,
        }, &result_buf),
    );

    std.debug.print("\tNORTH with only left turn available\n", .{});
    try std.testing.expectEqualDeep(
        &[_]PathItem{
            .{
                .position = Position{ .row = 13, .col = 12 },
                .direction = .EAST,
                .cost = 1002,
            },
        },
        precedingPathItems(maze_map, PathItem{
            .position = Position{ .row = 13, .col = 13 },
            .direction = .NORTH,
            .cost = 1,
        }, &result_buf),
    );

    std.debug.print("\tNORTH with only left or right turn available\n", .{});
    try std.testing.expectEqualDeep(
        &[_]PathItem{
            .{
                .position = Position{ .row = 1, .col = 1 },
                .direction = .EAST,
                .cost = 1002,
            },
            .{
                .position = Position{ .row = 1, .col = 3 },
                .direction = .WEST,
                .cost = 1002,
            },
        },
        precedingPathItems(maze_map, PathItem{
            .position = Position{ .row = 1, .col = 2 },
            .direction = .NORTH,
            .cost = 1,
        }, &result_buf),
    );

    std.debug.print("\tSOUTH with only no turn available\n", .{});
    try std.testing.expectEqualDeep(
        &[_]PathItem{
            .{
                .position = Position{ .row = 2, .col = 13 },
                .direction = .SOUTH,
                .cost = 2,
            },
        },
        precedingPathItems(maze_map, PathItem{
            .position = Position{ .row = 3, .col = 13 },
            .direction = .SOUTH,
            .cost = 1,
        }, &result_buf),
    );

    std.debug.print("\tSOUTH with only left or right turn available\n", .{});
    try std.testing.expectEqualDeep(
        &[_]PathItem{
            .{
                .position = Position{ .row = 1, .col = 3 },
                .direction = .WEST,
                .cost = 1002,
            },
            .{
                .position = Position{ .row = 1, .col = 1 },
                .direction = .EAST,
                .cost = 1002,
            },
        },
        precedingPathItems(maze_map, PathItem{
            .position = Position{ .row = 1, .col = 2 },
            .direction = .SOUTH,
            .cost = 1,
        }, &result_buf),
    );

    std.debug.print("\tEAST with only no turn available\n", .{});
    try std.testing.expectEqualDeep(
        &[_]PathItem{
            .{
                .position = Position{ .row = 1, .col = 1 },
                .direction = .EAST,
                .cost = 2,
            },
        },
        precedingPathItems(maze_map, PathItem{
            .position = Position{ .row = 1, .col = 2 },
            .direction = .EAST,
            .cost = 1,
        }, &result_buf),
    );

    std.debug.print("\tEAST with only left or right turn available\n", .{});
    try std.testing.expectEqualDeep(
        &[_]PathItem{
            .{
                .position = Position{ .row = 1, .col = 1 },
                .direction = .SOUTH,
                .cost = 1002,
            },
            .{
                .position = Position{ .row = 3, .col = 1 },
                .direction = .NORTH,
                .cost = 1002,
            },
        },
        precedingPathItems(maze_map, PathItem{
            .position = Position{ .row = 2, .col = 1 },
            .direction = .EAST,
            .cost = 1,
        }, &result_buf),
    );

    std.debug.print("\tWEST with only no turn available\n", .{});
    try std.testing.expectEqualDeep(
        &[_]PathItem{
            .{
                .position = Position{ .row = 1, .col = 3 },
                .direction = .WEST,
                .cost = 2,
            },
        },
        precedingPathItems(maze_map, PathItem{
            .position = Position{ .row = 1, .col = 2 },
            .direction = .WEST,
            .cost = 1,
        }, &result_buf),
    );

    std.debug.print("\tWEST with only left or right turn available\n", .{});
    try std.testing.expectEqualDeep(
        &[_]PathItem{
            .{
                .position = Position{ .row = 3, .col = 1 },
                .direction = .NORTH,
                .cost = 1002,
            },
            .{
                .position = Position{ .row = 1, .col = 1 },
                .direction = .SOUTH,
                .cost = 1002,
            },
        },
        precedingPathItems(maze_map, PathItem{
            .position = Position{ .row = 2, .col = 1 },
            .direction = .WEST,
            .cost = 1,
        }, &result_buf),
    );
}

fn growPath(maze_map: MazeMap, paths: *Paths, path_index: usize, start_position: Position) !bool {
    var preceding_buf: [3]PathItem = undefined;
    while (true) {
        if (paths.head(path_index).score(start_position) == 0) {
            return true;
        }
        const preceding = precedingPathItems(maze_map, paths.head(path_index), &preceding_buf);
        if (preceding.len == 0) {
            return false;
        }
        for (preceding[1..]) |path_item| {
            _ = try paths.branch(path_index, path_item);
        }
        if (!try paths.grow(path_index, preceding[0])) {
            return false;
        }
    }
}

test growPath {
    const allocator = std.testing.allocator;
    const maze_map = MazeMap.create(
        null,
        &[_][]const u8{
            "###############",
            "#.......#....E#",
            "#.#.###.#.###.#",
            "#.....#.#...#.#",
            "#.###.#####.#.#",
            "#.#.#.......#.#",
            "#.#.#####.###.#",
            "#...........#.#",
            "###.#.#####.#.#",
            "#...#.....#.#.#",
            "#.#.#.###.#.#.#",
            "#.....#...#.#.#",
            "#.###.#.#.#.#.#",
            "#S..#.....#...#",
            "###############",
        },
    );
    var print_buf = [1]u8{0} ** 100000;

    std.debug.print("day16/growPath\n", .{});
    std.debug.print("\tPaths.init\n", .{});
    var paths = try Paths.init(allocator, maze_map, Position{ .row = 1, .col = 13 });
    defer paths.deinit();
    try std.testing.expectEqualStrings(
        \\[1,13,NORTH]=0 (1)
        \\[1,13,EAST]=0 (1)
    , paths.bufPrintHeads(&print_buf));

    std.debug.print("\tgrow the first path until it aborts\n", .{});
    const arrived = try growPath(maze_map, &paths, 0, Position{ .row = 13, .col = 1 });
    try std.testing.expectEqual(false, arrived);
    try std.testing.expectEqualStrings(
        \\[3,7,NORTH]=6044 (45)
        \\[1,13,EAST]=0 (1)
        \\[1,12,EAST]=1001 (2)
        \\[6,9,SOUTH]=4023 (24)
        \\[8,5,NORTH]=4027 (28)
        \\[6,3,SOUTH]=4029 (30)
        \\[8,3,NORTH]=4029 (30)
        \\[3,2,WEST]=5035 (36)
        \\[2,3,NORTH]=6039 (40)
    , paths.bufPrintHeads(&print_buf));
}

pub fn findAllOptimalPaths(allocator: std.mem.Allocator, maze_map: MazeMap, start_position: Position, exit_position: Position) !Paths {
    var paths = try Paths.init(allocator, maze_map, exit_position);
    defer paths.deinit();
    var optimal_cost: usize = std.math.maxInt(usize);

    for (0..50000) |_| {
        const grow_index = paths.findMinScorePathIndex(optimal_cost, start_position) catch |err| switch (err) {
            error.NoPathFound => return paths.keepPathsWithCost(optimal_cost),
            else => return err,
        };
        const success = try growPath(maze_map, &paths, grow_index, start_position);
        if (!success) {
            paths.remove(grow_index);
        } else {
            const path = paths.nth(grow_index);
            try path.turnEast();
            if (path.cost() < optimal_cost) {
                optimal_cost = path.cost();
            }
        }
    }
    return error.NoPathFound;
}

pub fn bufPrintPath(buf: []u8, maze_map: MazeMap, path: Path) []u8 {
    for (maze_map.map, 0..) |line, row| {
        _ = std.fmt.bufPrint(buf[(row * (maze_map.width + 1))..], "{s}\n", .{line}) catch unreachable;
    }
    for (path.path.items) |item| {
        buf[item.position.row * (maze_map.width + 1) + item.position.col] = switch (item.direction) {
            .NORTH => '^',
            .EAST => '>',
            .SOUTH => 'v',
            .WEST => '<',
        };
    }
    return buf[0 .. (maze_map.width + 1) * maze_map.height - 1];
}

test findAllOptimalPaths {
    const allocator = std.testing.allocator;
    const maze_map = MazeMap.create(
        null,
        &[_][]const u8{
            "###############",
            "#.......#....E#",
            "#.#.###.#.###.#",
            "#.....#.#...#.#",
            "#.###.#####.#.#",
            "#.#.#.......#.#",
            "#.#.#####.###.#",
            "#...........#.#",
            "###.#.#####.#.#",
            "#...#.....#.#.#",
            "#.#.#.###.#.#.#",
            "#.....#...#.#.#",
            "#.###.#.#.#.#.#",
            "#S..#.....#...#",
            "###############",
        },
    );
    const start_position = Position{ .row = 13, .col = 1 };
    const exit_position = Position{ .row = 1, .col = 13 };
    var print_buf = [1]u8{0} ** 100000;

    std.debug.print("day16/findAllOptimalPaths\n", .{});
    std.debug.print("\tsmall test\n", .{});
    var optimal_paths = try findAllOptimalPaths(allocator, maze_map, start_position, exit_position);
    defer optimal_paths.deinit();

    try std.testing.expectEqual(3, optimal_paths.paths.items.len);
    for ([_][]const u8{
        \\###############
        \\#.......#....^#
        \\#.#.###.#.###^#
        \\#.....#.#...#^#
        \\#.###.#####.#^#
        \\#.#.#.......#^#
        \\#.#.#####.###^#
        \\#..>>>>>>>>v#^#
        \\###^#.#####v#^#
        \\#>>^#.....#v#^#
        \\#^#.#.###.#v#^#
        \\#^....#...#v#^#
        \\#^###.#.#.#v#^#
        \\#>..#.....#>>^#
        \\###############
        ,
        \\###############
        \\#.......#....^#
        \\#.#.###.#.###^#
        \\#.....#.#...#^#
        \\#.###.#####.#^#
        \\#.#.#.......#^#
        \\#.#.#####.###^#
        \\#..>>>>>>>>v#^#
        \\###^#.#####v#^#
        \\#..^#.....#v#^#
        \\#.#^#.###.#v#^#
        \\#>>^..#...#v#^#
        \\#^###.#.#.#v#^#
        \\#>..#.....#>>^#
        \\###############
        ,
        \\###############
        \\#.......#....^#
        \\#.#.###.#.###^#
        \\#.....#.#...#^#
        \\#.###.#####.#^#
        \\#.#.#.......#^#
        \\#.#.#####.###^#
        \\#....>>>>>>v#^#
        \\###.#^#####v#^#
        \\#...#^....#v#^#
        \\#.#.#^###.#v#^#
        \\#>>>>^#...#v#^#
        \\#^###.#.#.#v#^#
        \\#>..#.....#>>^#
        \\###############
        ,
    }, 0..) |expected, i| {
        std.debug.print("\t  path[{d}]\n{s}\n", .{ i, expected });
        try std.testing.expectEqualStrings(
            expected,
            bufPrintPath(&print_buf, maze_map, optimal_paths.paths.items[i]),
        );
    }

    std.debug.print("\tlarge test\n", .{});
    var parse_result = try parseReindeerMazeMapFile(allocator, "data/day16/test.txt");
    defer parse_result.maze_map.deinit();

    const large_maze_map = parse_result.maze_map;
    const large_start_position = parse_result.start_position;
    const large_exit_position = parse_result.exit_position;
    var large_optimal_paths = try findAllOptimalPaths(allocator, large_maze_map, large_start_position, large_exit_position);
    defer large_optimal_paths.deinit();

    try std.testing.expectEqual(2, large_optimal_paths.paths.items.len);
    for ([_][]const u8{
        \\#################
        \\#...#...#...#..^#
        \\#.#.#.#.#.#.#.#^#
        \\#.#.#.#...#...#^#
        \\#.#.#.#.###.#.#^#
        \\#>>v#.#.#.....#^#
        \\#^#v#.#.#.#####^#
        \\#^#v..#.#.#....^#
        \\#^#v#####.#.###^#
        \\#^#v#.......#>>^#
        \\#^#v###.#####^###
        \\#^#v#...#..>>^#.#
        \\#^#v#.#####^###.#
        \\#^#v#>>>>>>^..#.#
        \\#^#v#^#########.#
        \\#>#>>^..........#
        \\#################
        ,
        \\#################
        \\#...#...#...#..^#
        \\#.#.#.#.#.#.#.#^#
        \\#.#.#.#...#...#^#
        \\#.#.#.#.###.#.#^#
        \\#>>v#.#.#.....#^#
        \\#^#v#.#.#.#####^#
        \\#^#v..#.#.#>>>>^#
        \\#^#v#####.#^###.#
        \\#^#v#..>>>>^#...#
        \\#^#v###^#####.###
        \\#^#v#>>^#.....#.#
        \\#^#v#^#####.###.#
        \\#^#v#^........#.#
        \\#^#v#^#########.#
        \\#>#>>^..........#
        \\#################
    }, 0..) |expected, i| {
        std.debug.print("\t  path[{d}]\n{s}\n", .{ i, expected });
        try std.testing.expectEqualStrings(
            expected,
            bufPrintPath(&print_buf, large_maze_map, large_optimal_paths.paths.items[i]),
        );
    }
}

pub fn uniquePositions(allocator: std.mem.Allocator, paths: Paths) ![]Position {
    var unique_positions = std.ArrayList(Position).init(allocator);
    defer unique_positions.deinit();
    for (paths.paths.items) |path| {
        for (path.path.items) |item| {
            const exists = for (unique_positions.items) |existing| {
                if (item.position.equal(existing)) {
                    break true;
                }
            } else false;
            if (!exists) {
                try unique_positions.append(item.position);
            }
        }
    }
    return unique_positions.toOwnedSlice();
}

pub fn bufPrintPositions(buf: []u8, maze_map: MazeMap, positions: []Position) []u8 {
    for (maze_map.map, 0..) |line, row| {
        _ = std.fmt.bufPrint(buf[(row * (maze_map.width + 1))..], "{s}\n", .{line}) catch unreachable;
    }
    for (positions) |position| {
        buf[position.row * (maze_map.width + 1) + position.col] = 'O';
    }
    return buf[0 .. (maze_map.width + 1) * maze_map.height - 1];
}

test uniquePositions {
    const allocator = std.testing.allocator;
    const maze_map = MazeMap.create(
        null,
        &[_][]const u8{
            "###############",
            "#.......#....E#",
            "#.#.###.#.###.#",
            "#.....#.#...#.#",
            "#.###.#####.#.#",
            "#.#.#.......#.#",
            "#.#.#####.###.#",
            "#...........#.#",
            "###.#.#####.#.#",
            "#...#.....#.#.#",
            "#.#.#.###.#.#.#",
            "#.....#...#.#.#",
            "#.###.#.#.#.#.#",
            "#S..#.....#...#",
            "###############",
        },
    );
    const start_position = Position{ .row = 13, .col = 1 };
    const exit_position = Position{ .row = 1, .col = 13 };
    var print_buf = [1]u8{0} ** 100000;

    std.debug.print("day16/findAllOptimalPaths\n", .{});
    std.debug.print("\tsmall test\n", .{});
    var optimal_paths = try findAllOptimalPaths(allocator, maze_map, start_position, exit_position);
    defer optimal_paths.deinit();
    const unique_positions = try uniquePositions(allocator, optimal_paths);
    defer allocator.free(unique_positions);

    try std.testing.expectEqualStrings(
        \\###############
        \\#.......#....O#
        \\#.#.###.#.###O#
        \\#.....#.#...#O#
        \\#.###.#####.#O#
        \\#.#.#.......#O#
        \\#.#.#####.###O#
        \\#..OOOOOOOOO#O#
        \\###O#O#####O#O#
        \\#OOO#O....#O#O#
        \\#O#O#O###.#O#O#
        \\#OOOOO#...#O#O#
        \\#O###.#.#.#O#O#
        \\#O..#.....#OOO#
        \\###############
    , bufPrintPositions(&print_buf, maze_map, unique_positions));
    try std.testing.expectEqual(45, unique_positions.len);

    std.debug.print("\tlarge test\n", .{});
    var parse_result = try parseReindeerMazeMapFile(allocator, "data/day16/test.txt");
    defer parse_result.maze_map.deinit();

    const large_maze_map = parse_result.maze_map;
    const large_start_position = parse_result.start_position;
    const large_exit_position = parse_result.exit_position;
    var large_optimal_paths = try findAllOptimalPaths(allocator, large_maze_map, large_start_position, large_exit_position);
    defer large_optimal_paths.deinit();
    const large_unique_positions = try uniquePositions(allocator, large_optimal_paths);
    defer allocator.free(large_unique_positions);

    try std.testing.expectEqualStrings(
        \\#################
        \\#...#...#...#..O#
        \\#.#.#.#.#.#.#.#O#
        \\#.#.#.#...#...#O#
        \\#.#.#.#.###.#.#O#
        \\#OOO#.#.#.....#O#
        \\#O#O#.#.#.#####O#
        \\#O#O..#.#.#OOOOO#
        \\#O#O#####.#O###O#
        \\#O#O#..OOOOO#OOO#
        \\#O#O###O#####O###
        \\#O#O#OOO#..OOO#.#
        \\#O#O#O#####O###.#
        \\#O#O#OOOOOOO..#.#
        \\#O#O#O#########.#
        \\#O#OOO..........#
        \\#################
    , bufPrintPositions(&print_buf, large_maze_map, large_unique_positions));
    try std.testing.expectEqual(64, large_unique_positions.len);
}
