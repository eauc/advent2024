const std = @import("std");

const AntennaFrequency = u8;
const Coordinate = usize;
const Antenna = struct {
    row: Coordinate,
    col: Coordinate,
    frequency: AntennaFrequency,
};
const AntennaMap = struct {
    width: Coordinate,
    height: Coordinate,
    antennas: []const Antenna,
};

pub fn parseAntennaMapFile(allocator: std.mem.Allocator, file_name: []const u8) !AntennaMap {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var antennas_list = std.ArrayList(Antenna).init(allocator);
    defer antennas_list.deinit();

    var lineBuf: [1024]u8 = undefined;
    var row: usize = 0;
    var width: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |readLineBuf| {
        width = readLineBuf.len;
        for (readLineBuf, 0..) |char, col| {
            if (char == '.') continue;
            try antennas_list.append(.{ .row = row, .col = col, .frequency = char });
        }
        row += 1;
    }

    return .{
        .width = width,
        .height = row,
        .antennas = try antennas_list.toOwnedSlice(),
    };
}

test parseAntennaMapFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day08/parseAntennaMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});

    const antenna_map = try parseAntennaMapFile(allocator, "data/day08/test.txt");
    try std.testing.expectEqualDeep(AntennaMap{
        .width = 12,
        .height = 12,
        .antennas = &[_]Antenna{
            .{ .row = 1, .col = 8, .frequency = '0' },
            .{ .row = 2, .col = 5, .frequency = '0' },
            .{ .row = 3, .col = 7, .frequency = '0' },
            .{ .row = 4, .col = 4, .frequency = '0' },
            .{ .row = 5, .col = 6, .frequency = 'A' },
            .{ .row = 8, .col = 8, .frequency = 'A' },
            .{ .row = 9, .col = 9, .frequency = 'A' },
        },
    }, antenna_map);
}

const AntennaPair = [2]Antenna;

fn antennaPairs(allocator: std.mem.Allocator, antenna_map: AntennaMap) ![]AntennaPair {
    var pairs = std.ArrayList(AntennaPair).init(allocator);
    for (antenna_map.antennas, 0..) |antenna, index| {
        const other_antennas = antenna_map.antennas[index + 1 ..];
        for (other_antennas) |other_antenna| {
            if (antenna.frequency != other_antenna.frequency) continue;
            try pairs.append(.{ antenna, other_antenna });
        }
    }
    return pairs.toOwnedSlice();
}

test antennaPairs {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day08/antennaPairs\n", .{});
    std.debug.print("\tall uniq antenna pairs with same frequency\n", .{});

    const pairs = try antennaPairs(allocator, AntennaMap{
        .width = 12,
        .height = 12,
        .antennas = &[_]Antenna{
            .{ .row = 1, .col = 8, .frequency = '0' },
            .{ .row = 2, .col = 5, .frequency = '0' },
            .{ .row = 3, .col = 7, .frequency = '0' },
            .{ .row = 4, .col = 4, .frequency = '0' },
            .{ .row = 5, .col = 6, .frequency = 'A' },
            .{ .row = 8, .col = 8, .frequency = 'A' },
            .{ .row = 9, .col = 9, .frequency = 'A' },
        },
    });
    try std.testing.expectEqualDeep(&[_]AntennaPair{
        AntennaPair{
            .{ .row = 1, .col = 8, .frequency = '0' },
            .{ .row = 2, .col = 5, .frequency = '0' },
        },
        AntennaPair{
            .{ .row = 1, .col = 8, .frequency = '0' },
            .{ .row = 3, .col = 7, .frequency = '0' },
        },
        AntennaPair{
            .{ .row = 1, .col = 8, .frequency = '0' },
            .{ .row = 4, .col = 4, .frequency = '0' },
        },
        AntennaPair{
            .{ .row = 2, .col = 5, .frequency = '0' },
            .{ .row = 3, .col = 7, .frequency = '0' },
        },
        AntennaPair{
            .{ .row = 2, .col = 5, .frequency = '0' },
            .{ .row = 4, .col = 4, .frequency = '0' },
        },
        AntennaPair{
            .{ .row = 3, .col = 7, .frequency = '0' },
            .{ .row = 4, .col = 4, .frequency = '0' },
        },
        AntennaPair{
            .{ .row = 5, .col = 6, .frequency = 'A' },
            .{ .row = 8, .col = 8, .frequency = 'A' },
        },
        AntennaPair{
            .{ .row = 5, .col = 6, .frequency = 'A' },
            .{ .row = 9, .col = 9, .frequency = 'A' },
        },
        AntennaPair{
            .{ .row = 8, .col = 8, .frequency = 'A' },
            .{ .row = 9, .col = 9, .frequency = 'A' },
        },
    }, pairs);
}

const AntiNode = struct {
    row: Coordinate,
    col: Coordinate,
};

fn antennaPairAntiNodes(allocator: std.mem.Allocator, antenna_map: AntennaMap, antenna_pair: AntennaPair) ![]AntiNode {
    const a = antenna_pair[0];
    const b = antenna_pair[1];
    var antiNodes = std.ArrayList(AntiNode).init(allocator);
    var antiNode = AntiNode{
        .row = a.row,
        .col = a.col,
    };
    try antiNodes.append(antiNode);
    while (antiNode.row + a.row >= b.row and antiNode.row + a.row < antenna_map.height + b.row and
        antiNode.col + a.col >= b.col and antiNode.col + a.col < antenna_map.width + b.col)
    {
        antiNode = AntiNode{
            .row = antiNode.row + a.row - b.row,
            .col = antiNode.col + a.col - b.col,
        };
        try antiNodes.append(antiNode);
    }
    antiNode = AntiNode{
        .row = b.row,
        .col = b.col,
    };
    try antiNodes.append(antiNode);
    while (antiNode.row + b.row >= a.row and antiNode.row + b.row < antenna_map.height + a.row and
        antiNode.col + b.col >= a.col and antiNode.col + b.col < antenna_map.width + a.col)
    {
        antiNode = AntiNode{
            .row = antiNode.row + b.row - a.row,
            .col = antiNode.col + b.col - a.col,
        };
        try antiNodes.append(antiNode);
    }
    return antiNodes.toOwnedSlice();
}

test antennaPairAntiNodes {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const antenna_map = AntennaMap{
        .width = 12,
        .height = 12,
        .antennas = &[_]Antenna{
            .{ .row = 1, .col = 8, .frequency = '0' },
            .{ .row = 2, .col = 5, .frequency = '0' },
            .{ .row = 3, .col = 7, .frequency = '0' },
            .{ .row = 4, .col = 4, .frequency = '0' },
            .{ .row = 5, .col = 6, .frequency = 'A' },
            .{ .row = 8, .col = 8, .frequency = 'A' },
            .{ .row = 9, .col = 9, .frequency = 'A' },
        },
    };
    std.debug.print("day08/antennaPairAntiNodes\n", .{});
    std.debug.print("\tantiNodes of an antenna pair if they are in map range\n", .{});

    std.debug.print("\t/ pair with both antiNodes in map\n", .{});
    try std.testing.expectEqualDeep(&[_]AntiNode{
        .{ .row = 1, .col = 8 },
        .{ .row = 0, .col = 11 },
        .{ .row = 2, .col = 5 },
        .{ .row = 3, .col = 2 },
    }, antennaPairAntiNodes(
        allocator,
        antenna_map,
        AntennaPair{
            .{ .row = 1, .col = 8, .frequency = '0' },
            .{ .row = 2, .col = 5, .frequency = '0' },
        },
    ));
    std.debug.print("\t\\ pair with both antiNodes in map\n", .{});
    try std.testing.expectEqualDeep(&[_]AntiNode{
        .{ .row = 2, .col = 5 },
        .{ .row = 1, .col = 3 },
        .{ .row = 0, .col = 1 },
        .{ .row = 3, .col = 7 },
        .{ .row = 4, .col = 9 },
        .{ .row = 5, .col = 11 },
    }, antennaPairAntiNodes(
        allocator,
        antenna_map,
        AntennaPair{
            .{ .row = 2, .col = 5, .frequency = '0' },
            .{ .row = 3, .col = 7, .frequency = '0' },
        },
    ));
    std.debug.print("\t/ pair with upper right antiNode out of map\n", .{});
    try std.testing.expectEqualDeep(&[_]AntiNode{
        .{ .row = 1, .col = 8 },
        .{ .row = 4, .col = 4 },
        .{ .row = 7, .col = 0 },
    }, antennaPairAntiNodes(
        allocator,
        antenna_map,
        AntennaPair{
            .{ .row = 1, .col = 8, .frequency = '0' },
            .{ .row = 4, .col = 4, .frequency = '0' },
        },
    ));
    std.debug.print("\t\\ pair with lower right antiNode out of map\n", .{});
    try std.testing.expectEqualDeep(&[_]AntiNode{
        .{ .row = 5, .col = 6 },
        .{ .row = 1, .col = 3 },
        .{ .row = 9, .col = 9 },
    }, antennaPairAntiNodes(
        allocator,
        antenna_map,
        AntennaPair{
            .{ .row = 5, .col = 6, .frequency = 'A' },
            .{ .row = 9, .col = 9, .frequency = 'A' },
        },
    ));
}

pub fn findAllAntiNodes(allocator: std.mem.Allocator, antenna_map: AntennaMap) ![]AntiNode {
    const antenna_pairs = try antennaPairs(allocator, antenna_map);
    var antiNodes_list = std.ArrayList(AntiNode).init(allocator);
    for (antenna_pairs) |antenna_pair| {
        const antiNodes = try antennaPairAntiNodes(allocator, antenna_map, antenna_pair);
        add_antiNodes: for (antiNodes) |antiNode| {
            for (antiNodes_list.items) |existing| {
                if (antiNode.row == existing.row and antiNode.col == existing.col) {
                    continue :add_antiNodes;
                }
            }
            try antiNodes_list.append(antiNode);
        }
    }
    return antiNodes_list.toOwnedSlice();
}

pub fn antiNodesMap(allocator: std.mem.Allocator, antenna_map: AntennaMap, antiNodes: []AntiNode) ![][]const u8 {
    var antiNodes_map = try allocator.alloc([]u8, antenna_map.height);
    for (0..antenna_map.height) |row| {
        antiNodes_map[row] = try allocator.alloc(u8, antenna_map.width);
        for (0..antenna_map.width) |col| {
            antiNodes_map[row][col] = '.';
        }
    }
    for (antenna_map.antennas) |antenna| {
        antiNodes_map[antenna.row][antenna.col] = antenna.frequency;
    }
    for (antiNodes) |antiNode| {
        antiNodes_map[antiNode.row][antiNode.col] = '#';
    }
    return antiNodes_map;
}

test findAllAntiNodes {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day08/findAllAntiNodes\n", .{});
    std.debug.print("\tread input file\n", .{});
    const antenna_map = try parseAntennaMapFile(allocator, "data/day08/test.txt");
    try std.testing.expectEqualDeep(AntennaMap{
        .width = 12,
        .height = 12,
        .antennas = &[_]Antenna{
            .{ .row = 1, .col = 8, .frequency = '0' },
            .{ .row = 2, .col = 5, .frequency = '0' },
            .{ .row = 3, .col = 7, .frequency = '0' },
            .{ .row = 4, .col = 4, .frequency = '0' },
            .{ .row = 5, .col = 6, .frequency = 'A' },
            .{ .row = 8, .col = 8, .frequency = 'A' },
            .{ .row = 9, .col = 9, .frequency = 'A' },
        },
    }, antenna_map);

    std.debug.print("\tchecks antiNodes\n", .{});
    const antiNodes = try findAllAntiNodes(allocator, antenna_map);
    const antiNodes_map = try antiNodesMap(allocator, antenna_map, antiNodes);
    try std.testing.expectEqual(34, antiNodes.len);
    for ([_][]const u8{
        "##....#....#",
        ".#.#....#...",
        "..#.##....#.",
        "..##...#....",
        "....#....#..",
        ".#...##....#",
        "...#..#.....",
        "#....#.#....",
        "..#.....#...",
        "....#....#..",
        ".#........#.",
        "...#......##",
    }, 0..) |expected, row| {
        std.debug.print("\t  {s}\n", .{expected});
        try std.testing.expectEqualStrings(expected, antiNodes_map[row]);
    }
}
