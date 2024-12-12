const std = @import("std");

const HikingMap = struct {
    map: [][]const u8,
    width: usize,
    height: usize,
};

pub fn parseHikingMapFile(allocator: std.mem.Allocator, file_name: []const u8) !HikingMap {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var lines_list = std.ArrayList([]const u8).init(allocator);

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |readLineBuf| {
        const line = try allocator.alloc(u8, readLineBuf.len);
        std.mem.copyForwards(u8, line, readLineBuf);
        try lines_list.append(line);
    }
    return .{
        .height = lines_list.items.len,
        .width = lines_list.items[0].len,
        .map = try lines_list.toOwnedSlice(),
    };
}

test parseHikingMapFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day10/parseHikingMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    const hiking_map = try parseHikingMapFile(allocator, "data/day10/test.txt");
    try std.testing.expectEqual(8, hiking_map.height);
    try std.testing.expectEqual(8, hiking_map.width);
    try std.testing.expectEqualDeep(&[_][]const u8{
        "89010123",
        "78121874",
        "87430965",
        "96549874",
        "45678903",
        "32019012",
        "01329801",
        "10456732",
    }, hiking_map.map);
}

const Position = struct {
    row: usize,
    col: usize,
    pub fn bufPrintKey(self: *const Position, keyBuf: []u8) ![]u8 {
        return std.fmt.bufPrint(keyBuf, "{d},{d}", .{ self.row, self.col });
    }
    pub fn getKey(self: *const Position, allocator: std.mem.Allocator) ![]u8 {
        var keyBuf = [1]u8{0} ** 100;
        const key = try self.bufPrintKey(&keyBuf);
        const keyStr = try allocator.alloc(u8, key.len);
        std.mem.copyForwards(u8, keyStr, key);
        return keyStr;
    }
};

fn getNeightbours(hiking_map: HikingMap, position: Position, neighbours_buf: *[4]Position) []Position {
    var n_neighbours: usize = 0;
    if (position.row > 0) {
        neighbours_buf[n_neighbours] = .{ .row = position.row - 1, .col = position.col };
        n_neighbours += 1;
    }
    if (position.row < hiking_map.height - 1) {
        neighbours_buf[n_neighbours] = .{ .row = position.row + 1, .col = position.col };
        n_neighbours += 1;
    }
    if (position.col > 0) {
        neighbours_buf[n_neighbours] = .{ .row = position.row, .col = position.col - 1 };
        n_neighbours += 1;
    }
    if (position.col < hiking_map.width - 1) {
        neighbours_buf[n_neighbours] = .{ .row = position.row, .col = position.col + 1 };
        n_neighbours += 1;
    }
    return neighbours_buf[0..n_neighbours];
}

fn initTrailEnds(
    allocator: std.mem.Allocator,
    hiking_map: HikingMap,
    scores_map: *std.StringHashMap(std.BufSet),
    neighbours_map: *std.StringHashMap(std.BufSet),
) !void {
    const map = hiking_map.map;
    var neightbours_buf = [1]Position{.{ .row = 0, .col = 0 }} ** 4;
    var keyBuf = [1]u8{0} ** 100;
    for (map, 0..) |line, row| {
        for (line, 0..) |altitude, col| {
            if (altitude == '8') {
                const position = Position{ .row = row, .col = col };
                const neightbours = getNeightbours(hiking_map, position, &neightbours_buf);
                // std.debug.print("8[{d},{d}]({d})\n", .{ row, col, neightbours.len });
                var scores_set = std.BufSet.init(allocator);
                for (neightbours) |neighbour| {
                    if (map[neighbour.row][neighbour.col] == '9') {
                        const neighbour_key = try neighbour.bufPrintKey(&keyBuf);
                        try scores_set.insert(neighbour_key);
                    }
                }
                const key = try position.getKey(allocator);
                // std.debug.print(" => [{s}] {d}\n", .{ key, scores_set.count() });
                try scores_map.put(key, scores_set);
                try neighbours_map.put(key, scores_set);
            }
        }
    }
}

fn scoreAltitude(
    allocator: std.mem.Allocator,
    hiking_map: HikingMap,
    altitude: u8,
    scores_map: *std.StringHashMap(std.BufSet),
    neighbours_map: *std.StringHashMap(std.BufSet),
) !void {
    const map = hiking_map.map;
    const neighbour_altitude: u8 = altitude + 1;

    var neightbours_buf = [1]Position{.{ .row = 0, .col = 0 }} ** 4;
    var keyBuf = [1]u8{0} ** 100;
    for (map, 0..) |line, row| {
        for (line, 0..) |alt, col| {
            if (alt == altitude) {
                const position = Position{ .row = row, .col = col };
                const neightbours = getNeightbours(hiking_map, position, &neightbours_buf);
                // std.debug.print("{c}[{d},{d}]({d})\n", .{ altitude, row, col, neightbours.len });

                var neighbours_set = std.BufSet.init(allocator);
                var scores_set = std.BufSet.init(allocator);
                for (neightbours) |neighbour| {
                    if (map[neighbour.row][neighbour.col] == neighbour_altitude) {
                        // std.debug.print(" -> {c}[{d},{d}]\n", .{ neighbour_altitude, neighbour.row, neighbour.col });
                        const key = try neighbour.bufPrintKey(&keyBuf);
                        try neighbours_set.insert(key);
                        const import_scores_set = scores_map.get(key).?;
                        var it = import_scores_set.iterator();
                        while (it.next()) |entry| {
                            try scores_set.insert(entry.*);
                        }
                    }
                }
                const key = try position.getKey(allocator);
                // std.debug.print(" => [{s}] {d}\n", .{ key, scores_set.count() });
                try scores_map.put(key, scores_set);
                try neighbours_map.put(key, neighbours_set);
            }
        }
    }
}

fn sumAltitudeScores(hiking_map: HikingMap, scores_map: std.StringHashMap(std.BufSet), altitude: u8) !usize {
    const map = hiking_map.map;
    var keyBuf = [1]u8{0} ** 100;
    var score: usize = 0;
    for (map, 0..) |line, row| {
        for (line, 0..) |alt, col| {
            if (alt == altitude) {
                const position = Position{ .row = row, .col = col };
                const key = try position.bufPrintKey(&keyBuf);
                const scores_set = scores_map.get(key).?;
                // std.debug.print("+ {c}[{d},{d}] = {d}\n", .{ alt, row, col, scores_set.count() });
                score += scores_set.count();
            }
        }
    }
    return score;
}

pub fn scoreTrailHeads(allocator: std.mem.Allocator, hiking_map: HikingMap) !usize {
    var scores_map = std.StringHashMap(std.BufSet).init(allocator);
    var neighbours_map = std.StringHashMap(std.BufSet).init(allocator);
    defer scores_map.deinit();

    try initTrailEnds(allocator, hiking_map, &scores_map, &neighbours_map);
    for (0..8) |i| {
        try scoreAltitude(allocator, hiking_map, @intCast('7' - i), &scores_map, &neighbours_map);
    }
    const score = try sumAltitudeScores(hiking_map, scores_map, '0');
    return score;
}

test scoreTrailHeads {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day10/scoreTrailHeads\n", .{});
    std.debug.print("\tread input file\n", .{});
    const hiking_map = try parseHikingMapFile(allocator, "data/day10/test.txt");

    std.debug.print("\ta trailhead's score is the number of 9-height positions reachable from that trailhead via a hiking trail\n", .{});
    const score = try scoreTrailHeads(allocator, hiking_map);
    try std.testing.expectEqual(36, score);
}

fn ratePosition(position_key: []const u8, neighbours_map: std.StringHashMap(std.BufSet)) usize {
    // std.debug.print("[{s}]\n", .{position_key});
    if (neighbours_map.get(position_key)) |neighbours_set| {
        var it = neighbours_set.iterator();
        var rate: usize = 0;
        while (it.next()) |next_position_key| {
            const next_rate = ratePosition(next_position_key.*, neighbours_map);
            // std.debug.print("[{s}] -> [{s}] = {d}\n", .{ position_key, next_position_key.*, next_rate });
            rate += next_rate;
        }
        // std.debug.print("[{s}] = {d}\n", .{ position_key, rate });
        return rate;
    } else {
        return 1;
    }
}

fn sumAltitudeRates(hiking_map: HikingMap, neighbours_map: std.StringHashMap(std.BufSet), altitude: u8) !usize {
    const map = hiking_map.map;
    var keyBuf = [1]u8{0} ** 100;
    var rate: usize = 0;
    for (map, 0..) |line, row| {
        for (line, 0..) |alt, col| {
            if (alt == altitude) {
                const position = Position{ .row = row, .col = col };
                const key = try position.bufPrintKey(&keyBuf);
                const position_rate = ratePosition(key, neighbours_map);
                rate += position_rate;
            }
        }
    }
    return rate;
}

pub fn rateTrailHeads(allocator: std.mem.Allocator, hiking_map: HikingMap) !usize {
    var scores_map = std.StringHashMap(std.BufSet).init(allocator);
    var neighbours_map = std.StringHashMap(std.BufSet).init(allocator);
    defer scores_map.deinit();

    try initTrailEnds(allocator, hiking_map, &scores_map, &neighbours_map);
    for (0..8) |i| {
        try scoreAltitude(allocator, hiking_map, @intCast('7' - i), &scores_map, &neighbours_map);
    }
    const rate = try sumAltitudeRates(hiking_map, neighbours_map, '0');
    return rate;
}

test rateTrailHeads {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day10/rateTrailHeads\n", .{});
    std.debug.print("\tread input file\n", .{});
    const hiking_map = try parseHikingMapFile(allocator, "data/day10/test.txt");

    std.debug.print("\tA trailhead's rating is the number of distinct hiking trails which begin at that trailhead.\n", .{});
    const rate = try rateTrailHeads(allocator, hiking_map);
    try std.testing.expectEqual(81, rate);
}
