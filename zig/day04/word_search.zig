const std = @import("std");

const WordSearchLines = [][]const u8;
pub fn parseWordSearchFile(allocator: std.mem.Allocator, file_name: []const u8) !WordSearchLines {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var linesList = std.ArrayList([]u8).init(allocator);
    defer linesList.deinit();

    var lineBuf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |readLineBuf| {
        const line = try allocator.alloc(u8, readLineBuf.len);
        std.mem.copyForwards(u8, line, readLineBuf);

        try linesList.append(line);
    }
    return linesList.toOwnedSlice();
}

test parseWordSearchFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day04/parseWordSearchFile\n", .{});
    std.debug.print("\tread test input file\n", .{});
    const word_search_lines = try parseWordSearchFile(allocator, "data/day04/test.txt");
    try std.testing.expectEqual(10, word_search_lines.len);
    try std.testing.expectEqualDeep(&[_][]const u8{
        "MMMSXXMASM",
        "MSAMXMSMSA",
        "AMXSXMAAMM",
        "MSAMASMSMX",
        "XMASAMXAMM",
        "XXAMMXXAMA",
        "SMSMSASXSS",
        "SAXAMASAAA",
        "MAMMMXMMMM",
        "MXMXAXMASX",
    }, word_search_lines);
}

const CharPosition = struct {
    row: usize,
    col: usize,
    char: u8,
};

const OccurenceDirection = enum { RIGHT, LEFT, DOWN, UP, RIGHT_DOWN, RIGHT_UP, LEFT_UP, LEFT_DOWN };

const Occurence = struct {
    direction: OccurenceDirection,
    charPositions: []CharPosition,
};

pub fn findWordOccurenceInDirection(word_search_lines: WordSearchLines, word: []const u8, direction: OccurenceDirection, charPositionsBuf: []CharPosition) bool {
    const row = charPositionsBuf[0].row;
    const col = charPositionsBuf[0].col;
    switch (direction) {
        .RIGHT => if (col + word.len > word_search_lines[row].len) {
            return false;
        },
        .LEFT => if (col + 1 < word.len) {
            return false;
        },
        .DOWN => if (row + word.len > word_search_lines.len) {
            return false;
        },
        .UP => if (row + 1 < word.len) {
            return false;
        },
        .RIGHT_DOWN => if (row + word.len > word_search_lines.len or col + word.len > word_search_lines[row].len) {
            return false;
        },
        .RIGHT_UP => if (row + 1 < word.len or col + word.len > word_search_lines[row].len) {
            return false;
        },
        .LEFT_UP => if (row + 1 < word.len or col + 1 < word.len) {
            return false;
        },
        .LEFT_DOWN => if (row + word.len > word_search_lines.len or col + 1 < word.len) {
            return false;
        },
    }
    for (1..word.len) |i| {
        const next_pos: struct {
            row: usize,
            col: usize,
        } = switch (direction) {
            .RIGHT => .{ .row = row, .col = col + i },
            .LEFT => .{ .row = row, .col = col - i },
            .DOWN => .{ .row = row + i, .col = col },
            .UP => .{ .row = row - i, .col = col },
            .RIGHT_DOWN => .{ .row = row + i, .col = col + i },
            .RIGHT_UP => .{ .row = row - i, .col = col + i },
            .LEFT_UP => .{ .row = row - i, .col = col - i },
            .LEFT_DOWN => .{ .row = row + i, .col = col - i },
        };
        if (word_search_lines[next_pos.row][next_pos.col] == word[i]) {
            charPositionsBuf[i] = CharPosition{ .row = next_pos.row, .col = next_pos.col, .char = word[i] };
        } else {
            return false;
        }
    } else return true;
}

pub fn findWordOccurences(allocator: std.mem.Allocator, word_search_lines: WordSearchLines, word: []const u8) ![]Occurence {
    var charPositionsBuf = try allocator.alloc(CharPosition, word.len);
    defer allocator.free(charPositionsBuf);

    var occurences = std.ArrayList(Occurence).init(allocator);
    defer occurences.deinit();

    for (word_search_lines, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == word[0]) {
                charPositionsBuf[0] = CharPosition{ .row = row, .col = col, .char = word[0] };
                for ([_]OccurenceDirection{ .RIGHT, .LEFT, .DOWN, .UP, .RIGHT_DOWN, .RIGHT_UP, .LEFT_UP, .LEFT_DOWN }) |direction| {
                    const word_found = findWordOccurenceInDirection(word_search_lines, word, direction, charPositionsBuf);
                    if (word_found) {
                        const charPositions = try allocator.alloc(CharPosition, word.len);
                        std.mem.copyForwards(CharPosition, charPositions, charPositionsBuf);
                        try occurences.append(Occurence{
                            .direction = direction,
                            .charPositions = charPositions,
                        });
                    }
                }
            }
        }
    }
    return occurences.toOwnedSlice();
}

pub fn wordOccurencesToStrings(allocator: std.mem.Allocator, word_search_lines: WordSearchLines, occurences: []const Occurence) ![][]const u8 {
    const strings = try allocator.alloc([]u8, word_search_lines.len);
    for (word_search_lines, 0..) |line, row| {
        const string = try allocator.alloc(u8, line.len);
        for (line, 0..) |char, col| {
            string[col] = find: for (occurences) |occurence| {
                for (occurence.charPositions) |charPosition| {
                    if (charPosition.row == row and charPosition.col == col) {
                        break :find char;
                    }
                }
            } else '.';
        }
        strings[row] = string;
    }
    return strings;
}

test findWordOccurences {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day04/findWordOccurences\n", .{});
    std.debug.print("\tThis word search allows words to be horizontal, vertical, diagonal, written backwards, or even overlapping other words.\n", .{});
    std.debug.print("\t- read test input file\n", .{});
    const word_search_lines = try parseWordSearchFile(allocator, "data/day04/test.txt");
    std.debug.print("\t- findWordOccurences\n", .{});
    const occurences = try findWordOccurences(allocator, word_search_lines, "XMAS");
    try std.testing.expectEqual(18, occurences.len);
    const strings = try wordOccurencesToStrings(allocator, word_search_lines, occurences);
    for ([_][]const u8{
        "....XXMAS.",
        ".SAMXMS...",
        "...S..A...",
        "..A.A.MS.X",
        "XMASAMX.MM",
        "X.....XA.A",
        "S.S.S.S.SS",
        ".A.A.A.A.A",
        "..M.M.M.MM",
        ".X.X.XMASX",
    }, 0..) |expected, row| {
        std.debug.print("\t.comparing row {d}\n", .{row});
        try std.testing.expectEqualStrings(expected, strings[row]);
    }
}

pub fn findCrossedWordOccurences(allocator: std.mem.Allocator, word_search_lines: WordSearchLines, word: []const u8, cross_index: usize) ![]Occurence {
    const word_occurences = try findWordOccurences(allocator, word_search_lines, word);
    var cross_occurences_list = std.ArrayList(Occurence).init(allocator);
    defer cross_occurences_list.deinit();
    for (word_occurences, 0..) |occurence, current_index| {
        switch (occurence.direction) {
            .RIGHT, .LEFT, .UP, .DOWN => continue,
            else => {},
        }
        const char_position = occurence.charPositions[cross_index];
        const found = for (word_occurences, 0..) |other_occurence, i| {
            if (i == current_index) continue;
            switch (other_occurence.direction) {
                .RIGHT, .LEFT, .UP, .DOWN => continue,
                else => {},
            }
            if (char_position.row == other_occurence.charPositions[cross_index].row and char_position.col == other_occurence.charPositions[cross_index].col) {
                break true;
            }
        } else false;
        if (found) {
            try cross_occurences_list.append(occurence);
        }
    }
    return cross_occurences_list.toOwnedSlice();
}

test findCrossedWordOccurences {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day04/findWordOccurences\n", .{});
    std.debug.print("\tThis word search allows words to be horizontal, vertical, diagonal, written backwards, or even overlapping other words.\n", .{});
    std.debug.print("\t- read test input file\n", .{});
    const word_search_lines = try parseWordSearchFile(allocator, "data/day04/test.txt");
    std.debug.print("\t- findWordOccurences\n", .{});
    const occurences = try findCrossedWordOccurences(allocator, word_search_lines, "MAS", 1);
    try std.testing.expectEqual(18, occurences.len);
    const strings = try wordOccurencesToStrings(allocator, word_search_lines, occurences);
    for ([_][]const u8{
        ".M.S......",
        "..A..MSMS.",
        ".M.S.MAA..",
        "..A.ASMSM.",
        ".M.S.M....",
        "..........",
        "S.S.S.S.S.",
        ".A.A.A.A..",
        "M.M.M.M.M.",
        "..........",
    }, 0..) |expected, row| {
        // std.debug.print("\t{s}\t{s}\n", .{ strings[row], expected });
        std.debug.print("\t.comparing row {d}\n", .{row});
        try std.testing.expectEqualStrings(expected, strings[row]);
    }
}
