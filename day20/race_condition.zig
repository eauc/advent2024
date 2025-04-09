const std = @import("std");

const RaceMap = struct {
    allocator: std.mem.Allocator,
    height: usize,
    width: usize,
    map: [][]u8,
    pub fn bufPrint(self: RaceMap, buf: []u8) []const u8 {
        for (self.map, 0..) |line, row| {
            @memcpy(buf[row * (self.width + 1) ..][0..line.len], line);
            buf[row * (self.width + 1) + line.len] = '\n';
        }
        return buf[0 .. self.height * (self.width + 1) - 1];
    }
    pub fn deinit(self: *RaceMap) void {
        for (self.map) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.map);
    }
};

pub fn parseRaceMapFile(allocator: std.mem.Allocator, file_name: []const u8) !RaceMap {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var lines_list = std.ArrayList([]u8).init(allocator);
    defer lines_list.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |line| {
        try lines_list.append(try allocator.dupe(u8, line));
    }
    return .{
        .allocator = allocator,
        .height = lines_list.items.len,
        .width = lines_list.items[0].len,
        .map = try lines_list.toOwnedSlice(),
    };
}

test parseRaceMapFile {
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** 1024;

    std.debug.print("day20/parseRaceMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    var race_map = try parseRaceMapFile(allocator, "data/day20/test.txt");
    defer race_map.deinit();

    try std.testing.expectEqualStrings(
        \\###############
        \\#...#...#.....#
        \\#.#.#.#.#.###.#
        \\#S#...#.#.#...#
        \\#######.#.#.###
        \\#######.#.#...#
        \\#######.#.###.#
        \\###..E#...#...#
        \\###.#######.###
        \\#...###...#...#
        \\#.#####.#.###.#
        \\#.#...#.#.#...#
        \\#.#.#.#.#.#.###
        \\#...#...#...###
        \\###############
    , race_map.bufPrint(&print_buf));
}

fn absoluteDiff(a: usize, b: usize) usize {
    if (a > b) {
        return a - b;
    } else {
        return b - a;
    }
}

const Position = struct {
    row: usize,
    col: usize,
    pub fn distance(self: Position, other: Position) usize {
        const row_diff = absoluteDiff(self.row, other.row);
        const col_diff = absoluteDiff(self.col, other.col);
        return row_diff + col_diff;
    }
};

const PathStep = struct {
    position: Position,
    cost: usize,
};

const Path = struct {
    allocator: std.mem.Allocator,
    steps: []PathStep,
    pub fn bufPrint(self: Path, buf: []u8) []const u8 {
        if (self.steps.len == 0) {
            return buf[0..0];
        }
        var printed: usize = 0;
        for (self.steps) |step| {
            const b = std.fmt.bufPrint(buf[printed..], "[{d},{d}]={d}\n", .{
                step.position.row,
                step.position.col,
                step.cost,
            }) catch unreachable;
            printed += b.len;
        }
        return buf[0 .. printed - 1];
    }
    pub fn deinit(self: *Path) void {
        self.allocator.free(self.steps);
    }
};

fn getNextPathPosition(race_map: RaceMap, position: Position, previous_position: Position) ?Position {
    if (position.row > 0 and race_map.map[position.row - 1][position.col] != '#' and previous_position.row != position.row - 1) {
        return .{ .row = position.row - 1, .col = position.col };
    }
    if (position.row < race_map.height - 1 and race_map.map[position.row + 1][position.col] != '#' and previous_position.row != position.row + 1) {
        return .{ .row = position.row + 1, .col = position.col };
    }
    if (position.col > 0 and race_map.map[position.row][position.col - 1] != '#' and previous_position.col != position.col - 1) {
        return .{ .row = position.row, .col = position.col - 1 };
    }
    if (position.col < race_map.width - 1 and race_map.map[position.row][position.col + 1] != '#' and previous_position.col != position.col + 1) {
        return .{ .row = position.row, .col = position.col + 1 };
    }
    return null;
}

pub fn getPath(allocator: std.mem.Allocator, race_map: RaceMap) !Path {
    var steps_list = std.ArrayList(PathStep).init(allocator);
    defer steps_list.deinit();

    const start_position = find_start: for (race_map.map, 0..) |line, row| {
        for (line, 0..) |cell, col| {
            if (cell == 'S') {
                break :find_start Position{ .row = row, .col = col };
            }
        }
    } else unreachable;
    try steps_list.append(.{ .position = start_position, .cost = 0 });

    var position = start_position;
    var previous_position = start_position;
    var cost: usize = 0;
    while (true) {
        cost += 1;
        if (getNextPathPosition(race_map, position, previous_position)) |next_position| {
            try steps_list.append(.{ .position = next_position, .cost = cost });
            previous_position = position;
            position = next_position;
        } else {
            break;
        }
    }

    return .{
        .allocator = allocator,
        .steps = try steps_list.toOwnedSlice(),
    };
}

test getPath {
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** 1024;

    std.debug.print("day20/parseRaceMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    var race_map = try parseRaceMapFile(allocator, "data/day20/test.txt");
    defer race_map.deinit();

    std.debug.print("\tget path\n", .{});
    var path = try getPath(allocator, race_map);
    defer path.deinit();

    std.debug.print("\tcheck path\n", .{});
    try std.testing.expectEqualStrings(
        \\[3,1]=0
        \\[2,1]=1
        \\[1,1]=2
        \\[1,2]=3
        \\[1,3]=4
        \\[2,3]=5
        \\[3,3]=6
        \\[3,4]=7
        \\[3,5]=8
        \\[2,5]=9
        \\[1,5]=10
        \\[1,6]=11
        \\[1,7]=12
        \\[2,7]=13
        \\[3,7]=14
        \\[4,7]=15
        \\[5,7]=16
        \\[6,7]=17
        \\[7,7]=18
        \\[7,8]=19
        \\[7,9]=20
        \\[6,9]=21
        \\[5,9]=22
        \\[4,9]=23
        \\[3,9]=24
        \\[2,9]=25
        \\[1,9]=26
        \\[1,10]=27
        \\[1,11]=28
        \\[1,12]=29
        \\[1,13]=30
        \\[2,13]=31
        \\[3,13]=32
        \\[3,12]=33
        \\[3,11]=34
        \\[4,11]=35
        \\[5,11]=36
        \\[5,12]=37
        \\[5,13]=38
        \\[6,13]=39
        \\[7,13]=40
        \\[7,12]=41
        \\[7,11]=42
        \\[8,11]=43
        \\[9,11]=44
        \\[9,12]=45
        \\[9,13]=46
        \\[10,13]=47
        \\[11,13]=48
        \\[11,12]=49
        \\[11,11]=50
        \\[12,11]=51
        \\[13,11]=52
        \\[13,10]=53
        \\[13,9]=54
        \\[12,9]=55
        \\[11,9]=56
        \\[10,9]=57
        \\[9,9]=58
        \\[9,8]=59
        \\[9,7]=60
        \\[10,7]=61
        \\[11,7]=62
        \\[12,7]=63
        \\[13,7]=64
        \\[13,6]=65
        \\[13,5]=66
        \\[12,5]=67
        \\[11,5]=68
        \\[11,4]=69
        \\[11,3]=70
        \\[12,3]=71
        \\[13,3]=72
        \\[13,2]=73
        \\[13,1]=74
        \\[12,1]=75
        \\[11,1]=76
        \\[10,1]=77
        \\[9,1]=78
        \\[9,2]=79
        \\[9,3]=80
        \\[8,3]=81
        \\[7,3]=82
        \\[7,4]=83
        \\[7,5]=84
    , path.bufPrint(&print_buf));
}

pub fn countCheats(path: Path, max_cheat_distance: usize, above: usize) usize {
    var count: usize = 0;
    for (path.steps[0 .. path.steps.len - above - 2], 0..) |step, index| {
        for (path.steps[index + above .. path.steps.len]) |other_step| {
            const distance = step.position.distance(other_step.position);
            const cheatable = distance > 1 and
                distance <= max_cheat_distance and
                other_step.cost >= step.cost + distance + above;
            if (cheatable) {
                // std.debug.print("[{d},{d}]={d}->[{d},{d}]={d} / {d}\n", .{
                //     step.position.row,
                //     step.position.col,
                //     step.cost,
                //     other_step.position.row,
                //     other_step.position.col,
                //     other_step.cost,
                //     other_step.cost - step.cost - distance,
                // });
                count += 1;
            }
        }
    }
    return count;
}

test countCheats {
    const allocator = std.testing.allocator;

    std.debug.print("day20/parseRaceMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    var race_map = try parseRaceMapFile(allocator, "data/day20/test.txt");
    defer race_map.deinit();

    std.debug.print("\tget path\n", .{});
    var path = try getPath(allocator, race_map);
    defer path.deinit();

    std.debug.print("\tcount cheats with max distance = 2\n", .{});
    std.debug.print("\t  above 60\n", .{});
    try std.testing.expectEqual(1, countCheats(path, 2, 60));
    std.debug.print("\t  above 40\n", .{});
    try std.testing.expectEqual(2, countCheats(path, 2, 40));
    std.debug.print("\t  above 30\n", .{});
    try std.testing.expectEqual(4, countCheats(path, 2, 30));
    std.debug.print("\t  above 20\n", .{});
    try std.testing.expectEqual(5, countCheats(path, 2, 20));
    std.debug.print("\t  above 10\n", .{});
    try std.testing.expectEqual(10, countCheats(path, 2, 10));
    std.debug.print("\t  above 5\n", .{});
    try std.testing.expectEqual(16, countCheats(path, 2, 5));
    std.debug.print("\t  above 4\n", .{});
    try std.testing.expectEqual(30, countCheats(path, 2, 4));
    std.debug.print("\t  above 1\n", .{});
    try std.testing.expectEqual(44, countCheats(path, 2, 1));

    std.debug.print("\tcount cheats with max distance = 20\n", .{});
    std.debug.print("\t  above 77\n", .{});
    try std.testing.expectEqual(0, countCheats(path, 20, 77));
    std.debug.print("\t  above 76\n", .{});
    try std.testing.expectEqual(3, countCheats(path, 20, 76));
    std.debug.print("\t  above 74\n", .{});
    try std.testing.expectEqual(7, countCheats(path, 20, 74));
    std.debug.print("\t  above 72\n", .{});
    try std.testing.expectEqual(29, countCheats(path, 20, 72));
    std.debug.print("\t  above 70\n", .{});
    try std.testing.expectEqual(41, countCheats(path, 20, 70));
    std.debug.print("\t  above 68\n", .{});
    try std.testing.expectEqual(55, countCheats(path, 20, 68));
    std.debug.print("\t  above 66\n", .{});
    try std.testing.expectEqual(67, countCheats(path, 20, 66));
    std.debug.print("\t  above 64\n", .{});
    try std.testing.expectEqual(86, countCheats(path, 20, 64));
    std.debug.print("\t  above 62\n", .{});
    try std.testing.expectEqual(106, countCheats(path, 20, 62));
    std.debug.print("\t  above 60\n", .{});
    try std.testing.expectEqual(129, countCheats(path, 20, 60));
    std.debug.print("\t  above 58\n", .{});
    try std.testing.expectEqual(154, countCheats(path, 20, 58));
    std.debug.print("\t  above 56\n", .{});
    try std.testing.expectEqual(193, countCheats(path, 20, 56));
    std.debug.print("\t  above 54\n", .{});
    try std.testing.expectEqual(222, countCheats(path, 20, 54));
    std.debug.print("\t  above 52\n", .{});
    try std.testing.expectEqual(253, countCheats(path, 20, 52));
    std.debug.print("\t  above 50\n", .{});
    try std.testing.expectEqual(285, countCheats(path, 20, 50));
}
