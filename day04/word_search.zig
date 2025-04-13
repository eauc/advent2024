//! --- Day 4: Ceres Search ---
//! "Looks like the Chief's not here. Next!" One of The Historians pulls out a device and pushes the only button on it. After a brief flash, you recognize the interior of the Ceres monitoring station!
//!
//! As the search for the Chief continues, a small Elf who lives on the station tugs on your shirt; she'd like to know if you could help her with her word search (your puzzle input). She only has to find one word: XMAS.
//!
//! This word search allows words to be horizontal, vertical, diagonal, written backwards, or even overlapping other words. It's a little unusual, though, as you don't merely need to find one instance of XMAS - you need to find all of them. Here are a few ways XMAS might appear, where irrelevant characters have been replaced with .:
//!
//! ```
//! ..X...
//! .SAMX.
//! .A..A.
//! XMAS.S
//! .X....
//! ```
//!
//! The actual word search will be full of letters instead. For example:
//! ```
//! MMMSXXMASM
//! MSAMXMSMSA
//! AMXSXMAAMM
//! MSAMASMSMX
//! XMASAMXAMM
//! XXAMMXXAMA
//! SMSMSASXSS
//! SAXAMASAAA
//! MAMMMXMMMM
//! MXMXAXMASX
//! ```
//! In this word search, XMAS occurs a total of 18 times; here's the same word search again, but where letters not involved in any XMAS have been replaced with .:
//! ```
//! ....XXMAS.
//! .SAMXMS...
//! ...S..A...
//! ..A.A.MS.X
//! XMASAMX.MM
//! X.....XA.A
//! S.S.S.S.SS
//! .A.A.A.A.A
//! ..M.M.M.MM
//! .X.X.XMASX
//! ```
//!
//! The Elf looks quizzically at you. Did you misunderstand the assignment?
//!
//! Looking for the instructions, you flip over the word search to find that this isn't actually an XMAS puzzle; it's an X-MAS puzzle in which you're supposed to find two MAS in the shape of an X. One way to achieve that is like this:
//! ```
//! M.S
//! .A.
//! M.S
//! ```
//! Irrelevant characters have again been replaced with . in the above diagram. Within the X, each MAS can be written forwards or backwards.
//!
//! Here's the same example from before, but this time all of the X-MASes have been kept instead:
//! ```
//! .M.S......
//! ..A..MSMS.
//! .M.S.MAA..
//! ..A.ASMSM.
//! .M.S.M....
//! ..........
//! S.S.S.S.S.
//! .A.A.A.A..
//! M.M.M.M.M.
//! ..........
//! ```
//! In this example, an X-MAS appears 9 times.
const std = @import("std");

const WordSearchLines = struct {
    allocator: std.mem.Allocator,
    lines: [][]u8,
    pub fn deinit(self: WordSearchLines) void {
        for (self.lines) |line| {
            self.allocator.free(line);
        }
        self.allocator.free(self.lines);
    }
};

pub fn parseWordSearchFile(allocator: std.mem.Allocator, file_name: []const u8) !WordSearchLines {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var linesList = std.ArrayList([]u8).init(allocator);
    defer linesList.deinit();

    var lineBuf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |readLineBuf| {
        const line = allocator.alloc(u8, readLineBuf.len) catch unreachable;
        std.mem.copyForwards(u8, line, readLineBuf);

        linesList.append(line) catch unreachable;
    }
    return .{
        .allocator = allocator,
        .lines = linesList.toOwnedSlice() catch unreachable,
    };
}

test parseWordSearchFile {
    const allocator = std.testing.allocator;

    var word_search_lines = try parseWordSearchFile(allocator, "day04/test.txt");
    defer word_search_lines.deinit();

    try std.testing.expectEqual(10, word_search_lines.lines.len);
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
    }, word_search_lines.lines);
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

/// Checks if `word` is found in `word_search_lines` in direction `direction` starting from `charPositionsBuf[0]`.
/// Fills `charPositionsBuf` with the positions of the found word characters.
pub fn findWordOccurenceInDirection(
    allocator: std.mem.Allocator,
    word_search_lines: WordSearchLines,
    word: []const u8,
    direction: OccurenceDirection,
    start: CharPosition,
) error{NotFound}![]CharPosition {
    const row = start.row;
    const col = start.col;
    const lines = word_search_lines.lines;
    // Checks if `word` can fit within `word_search_lines`
    switch (direction) {
        .RIGHT => if (col + word.len > lines[row].len) {
            return error.NotFound;
        },
        .LEFT => if (col + 1 < word.len) {
            return error.NotFound;
        },
        .DOWN => if (row + word.len > lines.len) {
            return error.NotFound;
        },
        .UP => if (row + 1 < word.len) {
            return error.NotFound;
        },
        .RIGHT_DOWN => if (row + word.len > lines.len or col + word.len > lines[row].len) {
            return error.NotFound;
        },
        .RIGHT_UP => if (row + 1 < word.len or col + word.len > lines[row].len) {
            return error.NotFound;
        },
        .LEFT_UP => if (row + 1 < word.len or col + 1 < word.len) {
            return error.NotFound;
        },
        .LEFT_DOWN => if (row + word.len > lines.len or col + 1 < word.len) {
            return error.NotFound;
        },
    }

    var charPositionsBuf = allocator.alloc(CharPosition, word.len) catch unreachable;
    errdefer allocator.free(charPositionsBuf);
    charPositionsBuf[0] = start;

    // Loops over each character in `word` and see if it's found in the correct `direction` starting from `charPositionsBuf[0]`
    // if it is found, adds the character position to `charPositionsBuf`
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
        if (lines[next_pos.row][next_pos.col] != word[i]) {
            return error.NotFound;
        }
        charPositionsBuf[i] = CharPosition{
            .row = next_pos.row,
            .col = next_pos.col,
            .char = word[i],
        };
    }
    return charPositionsBuf;
}

/// Finds all occurences of `word` in `word_search_lines` in all directions
pub fn findWordOccurences(allocator: std.mem.Allocator, word_search_lines: WordSearchLines, word: []const u8) []Occurence {
    var occurences = std.ArrayList(Occurence).init(allocator);
    defer occurences.deinit();

    for (word_search_lines.lines, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == word[0]) {
                for ([_]OccurenceDirection{ .RIGHT, .LEFT, .DOWN, .UP, .RIGHT_DOWN, .RIGHT_UP, .LEFT_UP, .LEFT_DOWN }) |direction| {
                    const start = CharPosition{ .row = row, .col = col, .char = word[0] };
                    const char_positions = findWordOccurenceInDirection(allocator, word_search_lines, word, direction, start) catch |err| switch (err) {
                        error.NotFound => continue,
                    };
                    occurences.append(Occurence{ .direction = direction, .charPositions = char_positions }) catch unreachable;
                }
            }
        }
    }
    return occurences.toOwnedSlice() catch unreachable;
}

fn freeOccurences(allocator: std.mem.Allocator, occurences: []Occurence) void {
    for (occurences) |occurence| {
        allocator.free(occurence.charPositions);
    }
    allocator.free(occurences);
}

// Returns a copy of `word_search_lines` with the characters not found in `occurences` replaced by `.`
pub fn wordOccurencesToStrings(allocator: std.mem.Allocator, word_search_lines: WordSearchLines, occurences: []const Occurence) [][]u8 {
    const strings = allocator.alloc([]u8, word_search_lines.lines.len) catch unreachable;
    for (word_search_lines.lines, 0..) |line, row| {
        const string = allocator.alloc(u8, line.len) catch unreachable;
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

fn freeStrings(allocator: std.mem.Allocator, strings: [][]u8) void {
    for (strings) |string| {
        allocator.free(string);
    }
    allocator.free(strings);
}

test findWordOccurences {
    const allocator = std.testing.allocator;

    var word_search_lines = try parseWordSearchFile(allocator, "day04/test.txt");
    defer word_search_lines.deinit();

    const occurences = findWordOccurences(allocator, word_search_lines, "XMAS");
    defer freeOccurences(allocator, occurences);

    const strings = wordOccurencesToStrings(allocator, word_search_lines, occurences);
    defer freeStrings(allocator, strings);

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
        try std.testing.expectEqualStrings(expected, strings[row]);
    }
}

// Finds crossed-word occurrences of `word` in `word_search_lines`, crossed at character index `cross_index`
pub fn findCrossedWordOccurences(allocator: std.mem.Allocator, word_search_lines: WordSearchLines, word: []const u8, cross_index: usize) []Occurence {
    const word_occurences = findWordOccurences(allocator, word_search_lines, word);
    defer freeOccurences(allocator, word_occurences);

    var cross_occurences_list = std.ArrayList(Occurence).init(allocator);
    defer cross_occurences_list.deinit();

    for (word_occurences, 0..) |occurence, current_index| {
        // vertical or horizontal occurences cannot be part of crossed words
        switch (occurence.direction) {
            .RIGHT, .LEFT, .UP, .DOWN => continue,
            else => {},
        }
        const char_position = occurence.charPositions[cross_index];
        // look for another occurence of word with the same character in the same position, and in a diagonal direction
        const found = for (word_occurences, 0..) |other_occurence, i| {
            // skip over the current occurence
            if (i == current_index) continue;
            // vertical or horizontal occurences cannot be part of crossed words
            switch (other_occurence.direction) {
                .RIGHT, .LEFT, .UP, .DOWN => continue,
                else => {},
            }
            if (char_position.row == other_occurence.charPositions[cross_index].row and
                char_position.col == other_occurence.charPositions[cross_index].col)
            {
                break true;
            }
        } else false;
        if (found) {
            const cross_occurence = Occurence{
                .direction = occurence.direction,
                .charPositions = allocator.dupe(CharPosition, occurence.charPositions) catch unreachable,
            };
            cross_occurences_list.append(cross_occurence) catch unreachable;
        }
    }
    return cross_occurences_list.toOwnedSlice() catch unreachable;
}

test findCrossedWordOccurences {
    const allocator = std.testing.allocator;

    var word_search_lines = try parseWordSearchFile(allocator, "day04/test.txt");
    defer word_search_lines.deinit();

    const occurences = findCrossedWordOccurences(allocator, word_search_lines, "MAS", 1);
    defer freeOccurences(allocator, occurences);

    const strings = wordOccurencesToStrings(allocator, word_search_lines, occurences);
    defer freeStrings(allocator, strings);
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
        try std.testing.expectEqualStrings(expected, strings[row]);
    }
}
