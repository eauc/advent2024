const std = @import("std");

const Position = struct {
    row: usize,
    col: usize,
};

pub fn parseBytesListFile(allocator: std.mem.Allocator, file_name: []const u8) ![]Position {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var bytes_list = std.ArrayList(Position).init(allocator);
    defer bytes_list.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |bytes_line| {
        var it = std.mem.splitScalar(u8, bytes_line, ',');
        var token = it.next().?;
        const col = try std.fmt.parseInt(usize, token, 10);
        token = it.next().?;
        const row = try std.fmt.parseInt(usize, token, 10);
        try bytes_list.append(Position{
            .row = (row),
            .col = (col),
        });
    }

    return bytes_list.toOwnedSlice();
}

test parseBytesListFile {
    const allocator = std.testing.allocator;

    std.debug.print("day18/parseBytesListFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    const bytes_list = try parseBytesListFile(allocator, "data/day18/test.txt");
    defer allocator.free(bytes_list);

    try std.testing.expectEqualDeep(&[_]Position{
        .{ .col = 5, .row = 4 },
        .{ .col = 4, .row = 2 },
        .{ .col = 4, .row = 5 },
        .{ .col = 3, .row = 0 },
        .{ .col = 2, .row = 1 },
        .{ .col = 6, .row = 3 },
        .{ .col = 2, .row = 4 },
        .{ .col = 1, .row = 5 },
        .{ .col = 0, .row = 6 },
        .{ .col = 3, .row = 3 },
        .{ .col = 2, .row = 6 },
        .{ .col = 5, .row = 1 },
        .{ .col = 1, .row = 2 },
        .{ .col = 5, .row = 5 },
        .{ .col = 2, .row = 5 },
        .{ .col = 6, .row = 5 },
        .{ .col = 1, .row = 4 },
        .{ .col = 0, .row = 4 },
        .{ .col = 6, .row = 4 },
        .{ .col = 1, .row = 1 },
        .{ .col = 6, .row = 1 },
        .{ .col = 1, .row = 0 },
        .{ .col = 0, .row = 5 },
        .{ .col = 1, .row = 6 },
        .{ .col = 2, .row = 0 },
    }, bytes_list);
}

const MemoryMap = struct {
    allocator: std.mem.Allocator,
    height: usize,
    width: usize,
    map: [][]?usize,
    pub fn init(allocator: std.mem.Allocator, height: usize, width: usize, bytes_list: []Position) !MemoryMap {
        var memory_map = try allocator.alloc([]?usize, height);
        for (memory_map) |*row| {
            row.* = try allocator.alloc(?usize, width);
            for (row.*) |*col| {
                col.* = std.math.maxInt(usize);
            }
        }
        for (bytes_list) |byte| {
            memory_map[byte.row][byte.col] = null;
        }
        return .{
            .allocator = allocator,
            .height = height,
            .width = width,
            .map = memory_map,
        };
    }
    pub fn deinit(self: *MemoryMap) void {
        for (self.map) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.map);
    }
};

fn drawMap(memory_map: MemoryMap, buf: []u8) []u8 {
    for (memory_map.map, 0..) |line, row| {
        for (line, 0..) |cell, col| {
            if (cell) |cost| {
                buf[row * (line.len + 1) + col] = if (cost == std.math.maxInt(usize)) '.' else 'O';
            } else {
                buf[row * (line.len + 1) + col] = '#';
            }
        }
        buf[row * (line.len + 1) + line.len] = '\n';
    }
    return buf[0 .. (memory_map.width + 1) * memory_map.height - 1];
}

test MemoryMap {
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** (1024);

    std.debug.print("day18/memoryMap\n", .{});
    std.debug.print("\tread input file\n", .{});
    const bytes_list = try parseBytesListFile(allocator, "data/day18/test.txt");
    defer allocator.free(bytes_list);

    std.debug.print("\tcreate memory map\n", .{});
    var memory_map = try MemoryMap.init(allocator, 7, 7, bytes_list[0..12]);
    defer memory_map.deinit();

    std.debug.print("\tcheck memory map\n", .{});
    try std.testing.expectEqualStrings(
        \\...#...
        \\..#..#.
        \\....#..
        \\...#..#
        \\..#..#.
        \\.#..#..
        \\#.#....
    , drawMap(memory_map, &print_buf));
}

fn growHead(memory_map: MemoryMap, head: Position, heads: *std.ArrayList(Position)) !void {
    const head_cost = memory_map.map[head.row][head.col].?;
    const new_cost = head_cost + 1;
    if (head.row > 0) {
        const new_head = Position{ .col = head.col, .row = head.row - 1 };
        const new_cell = memory_map.map[new_head.row][new_head.col];
        if (new_cell) |previous_cost| {
            if (previous_cost > new_cost) {
                memory_map.map[new_head.row][new_head.col] = new_cost;
                try heads.append(new_head);
            }
        }
    }
    if (head.row < memory_map.height - 1) {
        const new_head = Position{ .col = head.col, .row = head.row + 1 };
        const new_cell = memory_map.map[new_head.row][new_head.col];
        if (new_cell) |previous_cost| {
            if (previous_cost > new_cost) {
                memory_map.map[new_head.row][new_head.col] = new_cost;
                try heads.append(new_head);
            }
        }
    }
    if (head.col > 0) {
        const new_head = Position{ .col = head.col - 1, .row = head.row };
        const new_cell = memory_map.map[new_head.row][new_head.col];
        if (new_cell) |previous_cost| {
            if (previous_cost > new_cost) {
                memory_map.map[new_head.row][new_head.col] = new_cost;
                try heads.append(new_head);
            }
        }
    }
    if (head.col < memory_map.width - 1) {
        const new_head = Position{ .col = head.col + 1, .row = head.row };
        const new_cell = memory_map.map[new_head.row][new_head.col];
        if (new_cell) |previous_cost| {
            if (previous_cost > new_cost) {
                memory_map.map[new_head.row][new_head.col] = new_cost;
                try heads.append(new_head);
            }
        }
    }
}

pub fn findOptimalPathCost(height: usize, width: usize, bytes_list: []Position) !usize {
    var print_buf = [1]u8{0} ** (1024 * 1024);
    const exit_position = Position{ .col = width - 1, .row = height - 1 };
    var memory_map = try MemoryMap.init(std.heap.page_allocator, height, width, bytes_list);
    defer memory_map.deinit();

    memory_map.map[0][0] = 0;
    var heads = std.ArrayList(Position).init(std.heap.page_allocator);
    defer heads.deinit();
    try heads.append(Position{ .col = 0, .row = 0 });
    while (heads.items.len > 0) {
        var new_heads = std.ArrayList(Position).init(std.heap.page_allocator);
        for (heads.items) |head| {
            try growHead(memory_map, head, &new_heads);
        }
        for (new_heads.items) |new_head| {
            if (new_head.row == exit_position.row and new_head.col == exit_position.col) {
                std.debug.print("============\n{s}\n", .{drawMap(memory_map, &print_buf)});
                return memory_map.map[new_head.row][new_head.col].?;
            }
        }
        heads.deinit();
        heads = new_heads;
    }
    std.debug.print("============\n{s}\n", .{drawMap(memory_map, &print_buf)});
    return error.NoPathFound;
}

test findOptimalPathCost {
    const allocator = std.testing.allocator;

    std.debug.print("day18/findOptimalPathCost\n", .{});
    std.debug.print("\tread input file\n", .{});
    const bytes_list = try parseBytesListFile(allocator, "data/day18/test.txt");
    defer allocator.free(bytes_list);
    std.debug.print("\tfind optimal path\n", .{});
    try std.testing.expectEqual(22, try findOptimalPathCost(7, 7, bytes_list[0..12]));
}

pub fn firstNoExitByte(height: usize, width: usize, bytes_list: []Position) !Position {
    for (bytes_list, 0..) |byte, index| {
        std.debug.print("[{d}, {d}]({d})\n", .{ byte.row, byte.col, index });
        _ = findOptimalPathCost(height, width, bytes_list[0 .. index + 1]) catch |err| switch (err) {
            error.NoPathFound => return byte,
            else => return err,
        };
    }
    return error.NoByteFound;
}

test firstNoExitByte {
    const allocator = std.testing.allocator;

    std.debug.print("day18/findOptimalPathCost\n", .{});
    std.debug.print("\tread input file\n", .{});
    const bytes_list = try parseBytesListFile(allocator, "data/day18/test.txt");
    defer allocator.free(bytes_list);
    std.debug.print("\tfind first no exit byte\n", .{});
    try std.testing.expectEqualDeep(Position{
        .col = 6,
        .row = 1,
    }, try firstNoExitByte(7, 7, bytes_list));
}
