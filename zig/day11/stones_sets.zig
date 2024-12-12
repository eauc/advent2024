const std = @import("std");

const Stone = usize;
const StonesSet = []const Stone;

pub fn parseStonesSetFile(allocator: std.mem.Allocator, file_name: []const u8) !StonesSet {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var stones_list = std.ArrayList(usize).init(allocator);
    defer stones_list.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    const readLineBuf = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n');
    var it = std.mem.splitScalar(u8, readLineBuf.?, ' ');
    while (it.next()) |stoneStr| {
        const stone = try std.fmt.parseInt(Stone, stoneStr, 10);
        try stones_list.append(stone);
    }

    return try stones_list.toOwnedSlice();
}

test parseStonesSetFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day11/parseStonesSetFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    const stones_set = try parseStonesSetFile(allocator, "data/day11/test.txt");
    try std.testing.expectEqualDeep(&[_]Stone{ 125, 17 }, stones_set);
}

const BlinkStoneResult = struct { Stone, ?Stone };

fn blinkStoneOnce(stone: Stone) BlinkStoneResult {
    if (stone == 0) {
        return .{ 1, null };
    }
    var strBuf = [1]u8{0} ** 1024;
    var stoneStr = std.fmt.bufPrint(&strBuf, "{d}", .{stone}) catch unreachable;
    if (stoneStr.len % 2 == 0) {
        const half = stoneStr.len / 2;
        return .{
            std.fmt.parseInt(Stone, stoneStr[0..half], 10) catch unreachable,
            std.fmt.parseInt(Stone, stoneStr[half..], 10) catch unreachable,
        };
    }
    return .{ stone * 2024, null };
}

test blinkStoneOnce {
    std.debug.print("day11/blinkStoneOnce\n", .{});
    std.debug.print("\t0 -> 1\n", .{});
    try std.testing.expectEqualDeep(.{ 1, null }, blinkStoneOnce(0));

    std.debug.print("\tn -> n * 2024\n", .{});
    try std.testing.expectEqualDeep(.{ 2024, null }, blinkStoneOnce(1));
    try std.testing.expectEqualDeep(.{ 248952, null }, blinkStoneOnce(123));

    std.debug.print("\teven digits -> first half + last half\n", .{});
    try std.testing.expectEqualDeep(.{ 1, 2 }, blinkStoneOnce(12));
    try std.testing.expectEqualDeep(.{ 12, 34 }, blinkStoneOnce(1234));
    try std.testing.expectEqualDeep(.{ 12, 0 }, blinkStoneOnce(1200));
}

var keyBuf = [1]u8{0} ** 1024;

fn memoize(memo: *std.StringHashMap(usize), stone: Stone, times: usize, count: usize) usize {
    const keyStr = std.fmt.bufPrint(&keyBuf, "{d}x{d}", .{ stone, times }) catch unreachable;
    const key = std.heap.page_allocator.alloc(u8, keyStr.len) catch unreachable;
    std.mem.copyForwards(u8, key, keyStr);
    // std.debug.print("{d}x{d} store {d}\n", .{ stone, times, result.len });
    _ = memo.put(key, count) catch unreachable;
    return count;
}

fn readMemo(memo: *std.StringHashMap(usize), stone: Stone, times: usize) ?usize {
    const key = std.fmt.bufPrint(&keyBuf, "{d}x{d}", .{ stone, times }) catch unreachable;
    if (memo.get(key)) |count| {
        // std.debug.print("{d}x{d} read {d}\n", .{ stone, ti, value.len });
        return count;
    }
    return null;
}

fn blinkStone(allocator: std.mem.Allocator, stone: Stone, times: usize, memo: *std.StringHashMap(usize)) !usize {
    if (readMemo(memo, stone, times)) |count| {
        return count;
    }
    const new_stones = blinkStoneOnce(stone);
    if (times == 1) {
        if (new_stones[1]) |_| {
            return memoize(memo, stone, times, 2);
        }
        return memoize(memo, stone, times, 1);
    }

    var count = try blinkStone(allocator, new_stones[0], times - 1, memo);
    if (new_stones[1]) |new_stone| {
        count += try blinkStone(allocator, new_stone, times - 1, memo);
    }

    return memoize(memo, stone, times, count);
}

test blinkStone {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var memo = std.StringHashMap(usize).init(allocator);
    defer memo.deinit();

    std.debug.print("day11/blinkStone\n", .{});
    std.debug.print("\t[1] 125 -> 253000\n", .{});
    try std.testing.expectEqualDeep(1, try blinkStone(allocator, 125, 1, &memo));
    std.debug.print("\t[2] 125 -> 253, 0\n", .{});
    try std.testing.expectEqualDeep(2, try blinkStone(allocator, 125, 2, &memo));
    std.debug.print("\t[3] 125 -> 512072, 1\n", .{});
    try std.testing.expectEqualDeep(2, try blinkStone(allocator, 125, 3, &memo));
    std.debug.print("\t[4] 125 -> 512, 72, 2024\n", .{});
    try std.testing.expectEqualDeep(3, try blinkStone(allocator, 125, 4, &memo));
    std.debug.print("\t[5] 125 -> 1036288, 7, 2, 20, 24\n", .{});
    try std.testing.expectEqualDeep(5, try blinkStone(allocator, 125, 5, &memo));
    std.debug.print("\t[6] 125 -> 2097446912, 14168, 4048, 2, 0, 2, 4\n", .{});
    try std.testing.expectEqualDeep(7, try blinkStone(allocator, 125, 6, &memo));
}

pub fn blinkStonesSet(allocator: std.mem.Allocator, starting_stones_set: StonesSet, times: usize) !usize {
    var stones_list = std.ArrayList(Stone).init(allocator);
    defer stones_list.deinit();

    var memo = std.StringHashMap(usize).init(allocator);
    defer memo.deinit();

    var count: usize = 0;
    for (starting_stones_set) |stone| {
        count += try blinkStone(allocator, stone, times, &memo);
    }

    return count;
}

test blinkStonesSet {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day11/blinkStonesSet\n", .{});
    std.debug.print("\t[1] 125, 17 -> 253000, 1, 7\n", .{});
    try std.testing.expectEqualDeep(3, try blinkStonesSet(allocator, &[_]Stone{ 125, 17 }, 1));
    std.debug.print("\t[2] 125, 17 -> 253, 0, 2024, 14168\n", .{});
    try std.testing.expectEqualDeep(4, try blinkStonesSet(allocator, &[_]Stone{ 125, 17 }, 2));
    std.debug.print("\t[3] 125, 17 -> 512072, 1, 20, 24, 28676032\n", .{});
    try std.testing.expectEqualDeep(5, try blinkStonesSet(allocator, &[_]Stone{ 125, 17 }, 3));
    std.debug.print("\t[4] 125, 17 -> 512, 72, 2024, 2, 0, 2, 4, 2867, 6032\n", .{});
    try std.testing.expectEqualDeep(9, try blinkStonesSet(allocator, &[_]Stone{ 125, 17 }, 4));
    std.debug.print("\t[5] 125, 17 -> 1036288, 7, 2, 20, 24, 4048, 1, 4048, 8096, 28, 67, 60, 32\n", .{});
    try std.testing.expectEqualDeep(13, try blinkStonesSet(allocator, &[_]Stone{ 125, 17 }, 5));
    std.debug.print("\t[6] 125, 17 -> 2097446912, 14168, 4048, 2, 0, 2, 4, 40, 48, 2024, 40, 48, 80, 96, 2, 8, 6, 7, 6, 0, 3, 2\n", .{});
    try std.testing.expectEqualDeep(22, try blinkStonesSet(allocator, &[_]Stone{ 125, 17 }, 6));
    std.debug.print("\t[25] 125, 17 -> 55312 stones\n", .{});
    const blink_stones_count = try blinkStonesSet(allocator, &[_]Stone{ 125, 17 }, 25);
    try std.testing.expectEqual(55312, blink_stones_count);
}
