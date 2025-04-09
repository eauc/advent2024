const std = @import("std");
const ws = @import("word_search.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const word_search_lines = try ws.parseWordSearchFile(allocator, "data/day04/input.txt");

    const occurences = try ws.findWordOccurences(allocator, word_search_lines, "XMAS");
    const strings = try ws.wordOccurencesToStrings(allocator, word_search_lines, occurences);
    for (strings) |string| {
        std.debug.print("{s}\n", .{string});
    }
    std.debug.print("n_occurences: {}\n", .{occurences.len});

    const crossed_occurences = try ws.findCrossedWordOccurences(allocator, word_search_lines, "MAS", 1);
    const crossed_strings = try ws.wordOccurencesToStrings(allocator, word_search_lines, crossed_occurences);
    for (crossed_strings) |string| {
        std.debug.print("{s}\n", .{string});
    }
    std.debug.print("n_crossed_occurences: {}\n", .{crossed_occurences.len / 2});
}

test {
    _ = std.testing.refAllDecls(@This());
}
