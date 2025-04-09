const std = @import("std");

const Code = []const u8;
const Codes = std.ArrayList(Code);

fn freeCodes(allocator: std.mem.Allocator, paths: std.ArrayList([]const u8)) void {
    for (paths.items) |path| {
        allocator.free(path);
    }
    paths.deinit();
}

pub fn parseDoorLockCodesFile(allocator: std.mem.Allocator, file_name: []const u8) !Codes {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var codes_list = Codes.init(allocator);

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |code_line| {
        try codes_list.append(try allocator.dupe(u8, code_line));
    }

    return codes_list;
}

test parseDoorLockCodesFile {
    const allocator = std.testing.allocator;

    std.debug.print("day21/parseDoorLockCodesFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    const codes = try parseDoorLockCodesFile(allocator, "data/day21/test.txt");
    defer freeCodes(allocator, codes);
    for ([_]Code{
        "029A",
        "980A",
        "179A",
        "456A",
        "379A",
    }, 0..) |expected, i| {
        std.debug.print("\t  codes[{d}]={s}\n", .{ i, expected });
        try std.testing.expectEqualStrings(expected, codes.items[i]);
    }
}

const Position = struct {
    row: u8,
    col: u8,
};

fn keypadHMoves(start: Position, end: Position, buf: []u8) []u8 {
    var len: usize = 0;
    if (end.col > start.col) {
        for (start.col..end.col) |_| {
            buf[len] = '>';
            len += 1;
        }
    } else {
        for (end.col..start.col) |_| {
            buf[len] = '<';
            len += 1;
        }
    }
    return buf[0..len];
}

fn keypadVMoves(start: Position, end: Position, buf: []u8) []u8 {
    var len: usize = 0;
    if (start.row > end.row) {
        for (end.row..start.row) |_| {
            buf[len] = '^';
            len += 1;
        }
    } else {
        len = 0;
        for (start.row..end.row) |_| {
            buf[len] = 'v';
            len += 1;
        }
    }
    return buf[0..len];
}

fn numericKeypadPosition(digit: u8) Position {
    return switch (digit) {
        '7' => .{ .row = 0, .col = 0 },
        '8' => .{ .row = 0, .col = 1 },
        '9' => .{ .row = 0, .col = 2 },
        '4' => .{ .row = 1, .col = 0 },
        '5' => .{ .row = 1, .col = 1 },
        '6' => .{ .row = 1, .col = 2 },
        '1' => .{ .row = 2, .col = 0 },
        '2' => .{ .row = 2, .col = 1 },
        '3' => .{ .row = 2, .col = 2 },
        '0' => .{ .row = 3, .col = 1 },
        'A' => .{ .row = 3, .col = 2 },
        else => unreachable,
    };
}

fn numericKeypadCodes(allocator: std.mem.Allocator, start: Position, end: Position) error{ OutOfMemory, NoSpaceLeft }!Codes {
    var codes_list = Codes.init(allocator);
    var hbuf: [100]u8 = undefined;
    var vbuf: [100]u8 = undefined;
    var buf: [100]u8 = undefined;
    const hmoves = keypadHMoves(start, end, &hbuf);
    const vmoves = keypadVMoves(start, end, &vbuf);
    if (!(start.row == 3 and end.col == 0)) {
        const path1 = try std.fmt.bufPrint(&buf, "{s}{s}A", .{ hmoves, vmoves });
        try codes_list.append(try allocator.dupe(u8, path1));
    }
    if (hmoves.len > 0 and vmoves.len > 0 and
        !(start.col == 0 and end.row == 3))
    {
        const path2 = try std.fmt.bufPrint(&buf, "{s}{s}A", .{ vmoves, hmoves });
        try codes_list.append(try allocator.dupe(u8, path2));
    }
    return codes_list;
}

test numericKeypadCodes {
    const allocator = std.testing.allocator;

    std.debug.print("day21/numericKeypadCodes\n", .{});
    std.debug.print("\tA -> 9 : ^^^A\n", .{});
    const pathsA9 = try numericKeypadCodes(allocator, numericKeypadPosition('A'), numericKeypadPosition('9'));
    defer freeCodes(allocator, pathsA9);
    try std.testing.expectEqual(1, pathsA9.items.len);
    try std.testing.expectEqualStrings("^^^A", pathsA9.items[0]);

    std.debug.print("\t6 -> 4 : <<A\n", .{});
    const paths64 = try numericKeypadCodes(allocator, numericKeypadPosition('6'), numericKeypadPosition('4'));
    defer freeCodes(allocator, paths64);
    try std.testing.expectEqual(1, paths64.items.len);
    try std.testing.expectEqualStrings("<<A", paths64.items[0]);

    std.debug.print("\t7 -> 3 : >>vvA & vv>>A\n", .{});
    const paths73 = try numericKeypadCodes(allocator, numericKeypadPosition('7'), numericKeypadPosition('3'));
    defer freeCodes(allocator, paths73);
    try std.testing.expectEqual(2, paths73.items.len);
    try std.testing.expectEqualStrings(">>vvA", paths73.items[0]);
    try std.testing.expectEqualStrings("vv>>A", paths73.items[1]);

    std.debug.print("\t3 -> 7 : <<^^A & ^^<<A\n", .{});
    const paths37 = try numericKeypadCodes(allocator, numericKeypadPosition('3'), numericKeypadPosition('7'));
    defer freeCodes(allocator, paths37);
    try std.testing.expectEqual(2, paths37.items.len);
    try std.testing.expectEqualStrings("<<^^A", paths37.items[0]);
    try std.testing.expectEqualStrings("^^<<A", paths37.items[1]);

    std.debug.print("\t1 -> 9 : >>^^A & ^^>>A\n", .{});
    const paths19 = try numericKeypadCodes(allocator, numericKeypadPosition('1'), numericKeypadPosition('9'));
    defer freeCodes(allocator, paths19);
    try std.testing.expectEqual(2, paths19.items.len);
    try std.testing.expectEqualStrings(">>^^A", paths19.items[0]);
    try std.testing.expectEqualStrings("^^>>A", paths19.items[1]);

    std.debug.print("\t9 -> 1 : <<vvA & vv<<A\n", .{});
    const paths91 = try numericKeypadCodes(allocator, numericKeypadPosition('9'), numericKeypadPosition('1'));
    defer freeCodes(allocator, paths91);
    try std.testing.expectEqual(2, paths91.items.len);
    try std.testing.expectEqualStrings("<<vvA", paths91.items[0]);
    try std.testing.expectEqualStrings("vv<<A", paths91.items[1]);

    std.debug.print("\t7 -> 0 : >vvvA avoid empty lower left corner\n", .{});
    const paths70 = try numericKeypadCodes(allocator, numericKeypadPosition('7'), numericKeypadPosition('0'));
    defer freeCodes(allocator, paths70);
    try std.testing.expectEqual(1, paths70.items.len);
    try std.testing.expectEqualStrings(">vvvA", paths70.items[0]);

    std.debug.print("\t0 -> 1 : ^<A avoid empty lower left corner\n", .{});
    const paths01 = try numericKeypadCodes(allocator, numericKeypadPosition('0'), numericKeypadPosition('1'));
    defer freeCodes(allocator, paths01);
    try std.testing.expectEqual(1, paths01.items.len);
    try std.testing.expectEqualStrings("^<A", paths01.items[0]);
}

fn directionalKeypadPosition(digit: u8) Position {
    return switch (digit) {
        '^' => .{ .row = 0, .col = 1 },
        'A' => .{ .row = 0, .col = 2 },
        '<' => .{ .row = 1, .col = 0 },
        'v' => .{ .row = 1, .col = 1 },
        '>' => .{ .row = 1, .col = 2 },
        else => unreachable,
    };
}

fn directionalKeypadCodes(allocator: std.mem.Allocator, start: Position, end: Position) !Codes {
    var codes_list = Codes.init(allocator);
    var hbuf: [100]u8 = undefined;
    var vbuf: [100]u8 = undefined;
    var buf: [100]u8 = undefined;
    const hmoves = keypadHMoves(start, end, &hbuf);
    const vmoves = keypadVMoves(start, end, &vbuf);
    if (!(start.row == 0 and end.col == 0)) {
        const path1 = try std.fmt.bufPrint(&buf, "{s}{s}A", .{ hmoves, vmoves });
        try codes_list.append(try allocator.dupe(u8, path1));
    }
    if (hmoves.len > 0 and vmoves.len > 0 and
        !(start.col == 0 and end.row == 0))
    {
        const path2 = try std.fmt.bufPrint(&buf, "{s}{s}A", .{ vmoves, hmoves });
        try codes_list.append(try allocator.dupe(u8, path2));
    }
    return codes_list;
}

test directionalKeypadCodes {
    const allocator = std.testing.allocator;

    std.debug.print("day21/directionalKeypadCodes\n", .{});
    std.debug.print("\tA -> > : vA\n", .{});
    const pathsARight = try directionalKeypadCodes(allocator, directionalKeypadPosition('A'), directionalKeypadPosition('>'));
    defer freeCodes(allocator, pathsARight);
    try std.testing.expectEqualDeep(&[_][]const u8{"vA"}, pathsARight.items);

    std.debug.print("\t< -> > : >>A\n", .{});
    const pathsLeftRight = try directionalKeypadCodes(allocator, directionalKeypadPosition('<'), directionalKeypadPosition('>'));
    defer freeCodes(allocator, pathsLeftRight);
    try std.testing.expectEqualDeep(&[_][]const u8{">>A"}, pathsLeftRight.items);

    std.debug.print("\t^ -> > : v>A & >vA\n", .{});
    const pathsUpRight = try directionalKeypadCodes(allocator, directionalKeypadPosition('^'), directionalKeypadPosition('>'));
    defer freeCodes(allocator, pathsUpRight);
    try std.testing.expectEqualDeep(&[_][]const u8{ ">vA", "v>A" }, pathsUpRight.items);

    std.debug.print("\t> -> ^ : <^A & ^<A\n", .{});
    const pathsRightUp = try directionalKeypadCodes(allocator, directionalKeypadPosition('>'), directionalKeypadPosition('^'));
    defer freeCodes(allocator, pathsRightUp);
    try std.testing.expectEqualDeep(&[_][]const u8{ "<^A", "^<A" }, pathsRightUp.items);

    std.debug.print("\tv -> A : >^A & ^>A\n", .{});
    const pathsDownA = try directionalKeypadCodes(allocator, directionalKeypadPosition('v'), directionalKeypadPosition('A'));
    defer freeCodes(allocator, pathsDownA);
    try std.testing.expectEqualDeep(&[_][]const u8{ ">^A", "^>A" }, pathsDownA.items);

    std.debug.print("\tA -> v : <vA & v<A\n", .{});
    const pathsADown = try directionalKeypadCodes(allocator, directionalKeypadPosition('A'), directionalKeypadPosition('v'));
    defer freeCodes(allocator, pathsADown);
    try std.testing.expectEqualDeep(&[_][]const u8{ "<vA", "v<A" }, pathsADown.items);

    std.debug.print("\tA -> < : v<<A avoid top left empty corner\n", .{});
    const pathsALeft = try directionalKeypadCodes(allocator, directionalKeypadPosition('A'), directionalKeypadPosition('<'));
    defer freeCodes(allocator, pathsALeft);
    try std.testing.expectEqualDeep(&[_][]const u8{"v<<A"}, pathsALeft.items);

    std.debug.print("\t< -> ^ : >^A avoid top left empty corner\n", .{});
    const pathsLeftUp = try directionalKeypadCodes(allocator, directionalKeypadPosition('<'), directionalKeypadPosition('^'));
    defer freeCodes(allocator, pathsLeftUp);
    try std.testing.expectEqualDeep(&[_][]const u8{">^A"}, pathsLeftUp.items);
}

fn memoized(memo: *std.StringHashMap(usize), code: []const u8, depth: usize) !?usize {
    var print_buf = [1]u8{0} ** 128;
    const key = try std.fmt.bufPrint(&print_buf, "{s}:{d}", .{ code, depth });
    if (memo.get(key)) |result| {
        return result;
    }
    return null;
}

fn memoize(memo: *std.StringHashMap(usize), code: []const u8, depth: usize, result: usize) !usize {
    var print_buf = [1]u8{0} ** 128;
    const key = try std.fmt.bufPrint(&print_buf, "{s}:{d}", .{ code, depth });
    _ = try memo.put(try memo.allocator.dupe(u8, key), result);
    return result;
}

fn freeMemo(memo: *std.StringHashMap(usize)) void {
    var it = memo.iterator();
    while (it.next()) |entry| {
        memo.allocator.free(entry.key_ptr.*);
    }
    memo.deinit();
}

fn directionalKeypadCodeMinLength(allocator: std.mem.Allocator, code: []const u8, depth: usize, memo: *std.StringHashMap(usize)) !usize {
    if (try memoized(memo, code, depth)) |result| {
        return result;
    }
    if (depth == 0) {
        return memoize(memo, code, depth, code.len);
    }
    var total_length: usize = 0;
    var current_position = directionalKeypadPosition('A');
    for (code) |digit| {
        const next_position = directionalKeypadPosition(digit);
        const next_codes = try directionalKeypadCodes(allocator, current_position, next_position);
        defer freeCodes(allocator, next_codes);

        var min_length: usize = std.math.maxInt(usize);
        for (next_codes.items) |next_code| {
            const next_min_length = try directionalKeypadCodeMinLength(allocator, next_code, depth - 1, memo);
            if (next_min_length < min_length) {
                min_length = next_min_length;
            }
        }
        total_length += min_length;

        current_position = next_position;
    }
    return memoize(memo, code, depth, total_length);
}

fn humanKeypadCodeMinLength(allocator: std.mem.Allocator, code: []const u8, depth: usize, memo: *std.StringHashMap(usize)) !usize {
    var total_length: usize = 0;
    var current_position = numericKeypadPosition('A');
    for (code) |digit| {
        const next_position = numericKeypadPosition(digit);
        const next_codes = try numericKeypadCodes(allocator, current_position, next_position);
        defer freeCodes(allocator, next_codes);

        var digit_code_min_length: usize = std.math.maxInt(usize);
        for (next_codes.items) |next_code| {
            const next_code_min_length = try directionalKeypadCodeMinLength(allocator, next_code, depth, memo);
            if (next_code_min_length < digit_code_min_length) {
                digit_code_min_length = next_code_min_length;
            }
        }
        total_length += digit_code_min_length;

        current_position = next_position;
    }
    return total_length;
}

test humanKeypadCodeMinLength {
    const allocator = std.testing.allocator;
    var memo = std.StringHashMap(usize).init(allocator);
    defer freeMemo(&memo);

    std.debug.print("day21/humanKeypadCodeMinLength\n", .{});
    std.debug.print("\t(A)0 -> <A -> v<<A -> <vA<AA>>^A\n", .{});
    const commands_A0 = try humanKeypadCodeMinLength(allocator, "0", 2, &memo);
    try std.testing.expectEqual(18, commands_A0);

    std.debug.print("day21/humanKeypadCommands\n", .{});
    std.debug.print("\t029A\n", .{});
    const commands_029A = try humanKeypadCodeMinLength(allocator, "029A", 2, &memo);
    try std.testing.expectEqual(68, commands_029A);

    std.debug.print("\t980A\n", .{});
    const commands_980A = try humanKeypadCodeMinLength(allocator, "980A", 2, &memo);
    try std.testing.expectEqual(60, commands_980A);

    std.debug.print("\t179A\n", .{});
    const commands_179A = try humanKeypadCodeMinLength(allocator, "179A", 2, &memo);
    try std.testing.expectEqual(68, commands_179A);

    std.debug.print("\t456A\n", .{});
    const commands_456A = try humanKeypadCodeMinLength(allocator, "456A", 2, &memo);
    try std.testing.expectEqual(64, commands_456A);

    std.debug.print("\t379A\n", .{});
    const commands_379A = try humanKeypadCodeMinLength(allocator, "379A", 2, &memo);
    try std.testing.expectEqual(64, commands_379A);
}

fn codeComplexity(allocator: std.mem.Allocator, code: []const u8, depth: usize, memo: *std.StringHashMap(usize)) !usize {
    const value = try std.fmt.parseInt(usize, code[0..3], 10);
    const min_length = try humanKeypadCodeMinLength(allocator, code, depth, memo);
    return value * min_length;
}

test codeComplexity {
    const allocator = std.testing.allocator;
    var memo = std.StringHashMap(usize).init(allocator);
    defer freeMemo(&memo);

    std.debug.print("day21/codeComplexity\n", .{});
    std.debug.print("\t029A = 68 * 29 = 1972\n", .{});
    const complexity_029A = try codeComplexity(allocator, "029A", 2, &memo);
    try std.testing.expectEqual(1972, complexity_029A);

    std.debug.print("\t379A = 68 * 29 = 24256\n", .{});
    const complexity_379A = try codeComplexity(allocator, "379A", 2, &memo);
    try std.testing.expectEqual(24256, complexity_379A);
}

pub fn sumCodeComplexities(allocator: std.mem.Allocator, codes: []Code, depth: usize) !usize {
    var memo = std.StringHashMap(usize).init(allocator);
    defer freeMemo(&memo);

    var sum: usize = 0;
    for (codes) |code| {
        sum += try codeComplexity(allocator, code, depth, &memo);
    }
    return sum;
}

test sumCodeComplexities {
    const allocator = std.testing.allocator;

    std.debug.print("day21/sumCodeComplexities\n", .{});
    std.debug.print("\tread input file\n", .{});
    const codes = try parseDoorLockCodesFile(allocator, "data/day21/test.txt");
    defer freeCodes(allocator, codes);
    std.debug.print("\tsum complexities\n", .{});
    const sum = try sumCodeComplexities(allocator, codes.items, 2);
    try std.testing.expectEqual(126384, sum);
}
