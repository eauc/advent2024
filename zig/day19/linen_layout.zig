const std = @import("std");

const Pattern = []const u8;
const Design = []const u8;

const ParseResult = struct {
    patterns: []const Pattern,
    designs: []const Design,
};

pub fn parseLinenLayoutFile(allocator: std.mem.Allocator, file_name: []const u8) !ParseResult {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var patterns_list = std.ArrayList([]const u8).init(allocator);
    defer patterns_list.deinit();
    var designs_list = std.ArrayList([]const u8).init(allocator);
    defer designs_list.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    const patterns_line = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n') orelse unreachable;
    var it = std.mem.splitScalar(u8, patterns_line, ',');
    while (it.next()) |token| {
        const pattern = try allocator.dupe(u8, token);
        try patterns_list.append(pattern);
    }
    // empty line separator
    _ = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n');
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |design_line| {
        const design = try allocator.dupe(u8, design_line);
        try designs_list.append(design);
    }
    return .{
        .patterns = try patterns_list.toOwnedSlice(),
        .designs = try designs_list.toOwnedSlice(),
    };
}

fn freePatterns(allocator: std.mem.Allocator, patterns: []const Pattern) void {
    for (patterns) |pattern| {
        allocator.free(pattern);
    }
    allocator.free(patterns);
}

fn freeDesigns(allocator: std.mem.Allocator, designs: []const Design) void {
    for (designs) |design| {
        allocator.free(design);
    }
    allocator.free(designs);
}

test parseLinenLayoutFile {
    const allocator = std.testing.allocator;

    std.debug.print("day19/parseLinenLayoutFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    const parse_result = try parseLinenLayoutFile(allocator, "data/day19/test.txt");
    const patterns = parse_result.patterns;
    defer freePatterns(allocator, patterns);
    for ([_][]const u8{ "r", "wr", "b", "g", "bwu", "rb", "gb", "br" }, 0..) |expected, i| {
        std.debug.print("\t  patterns[i]={s}\n", .{expected});
        try std.testing.expectEqualStrings(expected, patterns[i]);
    }

    const designs = parse_result.designs;
    defer freeDesigns(allocator, designs);
    for ([_][]const u8{ "brwrr", "bggr", "gbbr", "rrbgbr", "ubwu", "bwurrg", "brgr", "bbrgwb" }, 0..) |expected, i| {
        std.debug.print("\t  designs[i]={s}\n", .{expected});
        try std.testing.expectEqualStrings(expected, designs[i]);
    }
}

fn designIsPossible(design: []const u8, patterns: []const []const u8) bool {
    if (design.len == 0) {
        return true;
    }
    for (patterns) |pattern| {
        // std.debug.print("design={s} pattern={s}\n", .{ design, pattern });
        if (std.mem.startsWith(u8, design, pattern)) {
            if (designIsPossible(design[pattern.len..], patterns)) {
                return true;
            }
        }
    }
    return false;
}

test designIsPossible {
    const allocator = std.testing.allocator;

    std.debug.print("day19/designIsPossible\n", .{});
    std.debug.print("\tread input file\n", .{});
    const parse_result = try parseLinenLayoutFile(allocator, "data/day19/test.txt");
    const patterns = parse_result.patterns;
    defer freePatterns(allocator, patterns);
    const designs = parse_result.designs;
    defer freeDesigns(allocator, designs);

    std.debug.print("\tdesign = brwrr\n", .{});
    try std.testing.expectEqual(true, designIsPossible("brwrr", patterns));

    std.debug.print("\tdesign = bggr\n", .{});
    try std.testing.expectEqual(true, designIsPossible("bggr", patterns));

    std.debug.print("\tdesign = gbbr\n", .{});
    try std.testing.expectEqual(true, designIsPossible("gbbr", patterns));

    std.debug.print("\tdesign = rrbgbr\n", .{});
    try std.testing.expectEqual(true, designIsPossible("rrbgbr", patterns));

    std.debug.print("\tdesign = ubwu\n", .{});
    try std.testing.expectEqual(false, designIsPossible("ubwu", patterns));

    std.debug.print("\tdesign = bwurrg\n", .{});
    try std.testing.expectEqual(true, designIsPossible("bwurrg", patterns));

    std.debug.print("\tdesign = brgr\n", .{});
    try std.testing.expectEqual(true, designIsPossible("brgr", patterns));

    std.debug.print("\tdesign = bbrgwb\n", .{});
    try std.testing.expectEqual(false, designIsPossible("bbrgwb", patterns));
}

pub fn countPossibleDesigns(designs: []const Design, patterns: []const Pattern) usize {
    var count: usize = 0;
    for (designs) |design| {
        if (designIsPossible(design, patterns)) {
            count += 1;
        }
    }
    return count;
}

test countPossibleDesigns {
    const allocator = std.testing.allocator;

    std.debug.print("day19/countPossibleDesigns\n", .{});
    std.debug.print("\tread input file\n", .{});
    const parse_result = try parseLinenLayoutFile(allocator, "data/day19/test.txt");
    const patterns = parse_result.patterns;
    defer freePatterns(allocator, patterns);
    const designs = parse_result.designs;
    defer freeDesigns(allocator, designs);

    try std.testing.expectEqual(6, countPossibleDesigns(designs, patterns));
}

fn countDesignArrangements(design: []const u8, patterns: []const []const u8, memo: *std.StringHashMap(usize)) !usize {
    if (design.len == 0) {
        return 1;
    }
    if (memo.contains(design)) {
        return memo.get(design).?;
    }
    var count: usize = 0;
    for (patterns) |pattern| {
        if (std.mem.startsWith(u8, design, pattern)) {
            const sub_count = try countDesignArrangements(design[pattern.len..], patterns, memo);
            // std.debug.print("design={s} pattern={s} count={d}\n", .{ design, pattern, sub_count });
            count += sub_count;
        }
    }
    try memo.put(design, count);
    return count;
}

test countDesignArrangements {
    const allocator = std.testing.allocator;

    std.debug.print("day19/countDesignArrangements\n", .{});
    std.debug.print("\tread input file\n", .{});
    const parse_result = try parseLinenLayoutFile(allocator, "data/day19/test.txt");
    const patterns = parse_result.patterns;
    defer freePatterns(allocator, patterns);
    const designs = parse_result.designs;
    defer freeDesigns(allocator, designs);

    var memo = std.StringHashMap(usize).init(allocator);
    defer memo.deinit();

    std.debug.print("\tdesign = brwrr\n", .{});
    try std.testing.expectEqual(2, try countDesignArrangements("brwrr", patterns, &memo));

    std.debug.print("\tdesign = bggr\n", .{});
    try std.testing.expectEqual(1, try countDesignArrangements("bggr", patterns, &memo));

    std.debug.print("\tdesign = gbbr\n", .{});
    try std.testing.expectEqual(4, try countDesignArrangements("gbbr", patterns, &memo));

    std.debug.print("\tdesign = rrbgbr\n", .{});
    try std.testing.expectEqual(6, try countDesignArrangements("rrbgbr", patterns, &memo));

    std.debug.print("\tdesign = ubwu\n", .{});
    try std.testing.expectEqual(0, try countDesignArrangements("ubwu", patterns, &memo));

    std.debug.print("\tdesign = bwurrg\n", .{});
    try std.testing.expectEqual(1, try countDesignArrangements("bwurrg", patterns, &memo));

    std.debug.print("\tdesign = brgr\n", .{});
    try std.testing.expectEqual(2, try countDesignArrangements("brgr", patterns, &memo));

    std.debug.print("\tdesign = bbrgwb\n", .{});
    try std.testing.expectEqual(0, try countDesignArrangements("bbrgwb", patterns, &memo));
}

pub fn countTotalDesignArrangements(allocator: std.mem.Allocator, designs: []const Design, patterns: []const Pattern) !usize {
    var memo = std.StringHashMap(usize).init(allocator);
    defer memo.deinit();

    var count: usize = 0;
    for (designs, 0..) |design, index| {
        std.debug.print("design[{d}]={s}\n", .{ index, design });
        count += try countDesignArrangements(design, patterns, &memo);
    }
    return count;
}

test countTotalDesignArrangements {
    const allocator = std.testing.allocator;

    std.debug.print("day19/countTotalDesignArrangements\n", .{});
    std.debug.print("\tread input file\n", .{});
    const parse_result = try parseLinenLayoutFile(allocator, "data/day19/test.txt");
    const patterns = parse_result.patterns;
    defer freePatterns(allocator, patterns);
    const designs = parse_result.designs;
    defer freeDesigns(allocator, designs);

    try std.testing.expectEqual(16, try countTotalDesignArrangements(allocator, designs, patterns));
}
