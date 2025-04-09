//! # Day 1: Historian Hysteria
//!
//! The Chief Historian is always present for the big Christmas sleigh launch, but nobody has seen him in months! Last anyone heard, he was visiting locations that are historically significant to the North Pole; a group of Senior Historians has asked you to accompany them as they check the places they think he was most likely to visit.
//!
//! As each location is checked, they will mark it on their list with a star. They figure the Chief Historian must be in one of the first fifty places they'll look, so in order to save Christmas, you need to help them get fifty stars on their list before Santa takes off on December 25th.
//!
//! Collect stars by solving puzzles. Two puzzles will be made available on each day in the Advent calendar; the second puzzle is unlocked when you complete the first. Each puzzle grants one star. Good luck!
//!
//! You haven't even left yet and the group of Elvish Senior Historians has already hit a problem: their list of locations to check is currently empty. Eventually, someone decides that the best place to check first would be the Chief Historian's office.
//!
//! Upon pouring into the office, everyone confirms that the Chief Historian is indeed nowhere to be found. Instead, the Elves discover an assortment of notes and lists of historically significant locations! This seems to be the planning the Chief Historian was doing before he left. Perhaps these notes can be used to determine which locations to search?
//!
//! Throughout the Chief's office, the historically significant locations are listed not by name but by a unique number called the location ID. To make sure they don't miss anything, The Historians split into two groups, each searching the office and trying to create their own complete list of location IDs.
//!
//! There's just one problem: by holding the two lists up side by side (your puzzle input), it quickly becomes clear that the lists aren't very similar. Maybe you can help The Historians reconcile their lists?

const std = @import("std");

const Location = isize;
const LocationList = []Location;
const LocationListsPair = struct {
    allocator: std.mem.Allocator,
    left: LocationList,
    right: LocationList,
    pub fn deinit(self: *LocationListsPair) void {
        self.allocator.free(self.left);
        self.allocator.free(self.right);
    }
};

fn printLocationList(name: []const u8, list: LocationList) void {
    std.debug.print("{s}: ", .{name});
    for (list.items) |location| {
        std.debug.print("{} ", .{location});
    }
    std.debug.print("\n", .{});
}

pub fn parseLocationListsFile(allocator: std.mem.Allocator, file_name: []const u8) !LocationListsPair {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();
    var lineBuf: [1024]u8 = undefined;
    var locationBuf = [2]Location{ 0, 0 };

    var left_list = std.ArrayList(Location).init(allocator);
    defer left_list.deinit();
    var right_list = std.ArrayList(Location).init(allocator);
    defer right_list.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');
        var token = it.next().?;
        locationBuf[0] = try std.fmt.parseInt(Location, token, 10);
        token = it.next().?;
        // skip multiple spaces
        while (token.len == 0) {
            token = it.next().?;
        }
        locationBuf[1] = try std.fmt.parseInt(Location, token, 10);

        left_list.append(locationBuf[0]) catch unreachable;
        right_list.append(locationBuf[1]) catch unreachable;
    }

    return .{
        .allocator = allocator,
        .left = left_list.toOwnedSlice() catch unreachable,
        .right = right_list.toOwnedSlice() catch unreachable,
    };
}

test parseLocationListsFile {
    const allocator = std.testing.allocator;
    var lists = try parseLocationListsFile(allocator, "day01/test.txt");
    defer lists.deinit();

    try std.testing.expectEqualSlices(Location, &[_]Location{ 3, 4, 2, 1, 3, 3 }, lists.left);
    try std.testing.expectEqualSlices(Location, &[_]Location{ 4, 3, 5, 3, 9, 3 }, lists.right);
}

/// Finds the total distance between the left list and the right list.
pub fn totalDistance(lists: LocationListsPair) usize {
    // Pair up the smallest number in the left list with the smallest number in the right list, then the second-smallest left number with the second-smallest right number, and so on.
    std.mem.sort(Location, lists.left, {}, comptime std.sort.asc(Location));
    std.mem.sort(Location, lists.right, {}, comptime std.sort.asc(Location));
    var total_distance: usize = 0;
    for (lists.left, lists.right) |left, right| {
        // Within each pair, figure out how far apart the two numbers are; you'll need to add up all of those distances.
        const distance = @abs(left - right);
        // To find the total distance between the left list and the right list, add up the distances between all of the pairs you found.
        total_distance += distance;
    }
    return total_distance;
}

test totalDistance {
    const allocator = std.testing.allocator;
    var lists = try parseLocationListsFile(allocator, "day01/test.txt");
    defer lists.deinit();

    try std.testing.expectEqual(11, totalDistance(lists));
}

const LocationFrequencies = std.AutoHashMap(Location, isize);

fn printFrequencies(frequencies: LocationFrequencies) void {
    std.debug.print("frequencies:\n", .{});
    var it = frequencies.iterator();
    while (it.next()) |entry| {
        std.debug.print("{}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

/// Calculates the frequency of each location in the list.
pub fn locationFrequencies(allocator: std.mem.Allocator, list: LocationList) LocationFrequencies {
    var frequencies = LocationFrequencies.init(allocator);
    for (list) |location| {
        if (frequencies.get(location)) |frequency| {
            frequencies.put(location, frequency + 1) catch unreachable;
        } else {
            frequencies.put(location, 1) catch unreachable;
        }
    }
    return frequencies;
}

/// Calculates a total similarity score.
pub fn totalSimilarityScore(allocator: std.mem.Allocator, lists: LocationListsPair) usize {
    var right_list_frequencies = locationFrequencies(allocator, lists.right);
    defer right_list_frequencies.deinit();

    var total_similarity_score: usize = 0;
    for (lists.left) |location| {
        if (right_list_frequencies.get(location)) |frequency| {
            // adds up each number in the left list after multiplying it by the number of times that number appears in the right list.
            total_similarity_score += @intCast(location * frequency);
        }
    }
    return total_similarity_score;
}

test totalSimilarityScore {
    const allocator = std.testing.allocator;
    var lists = try parseLocationListsFile(allocator, "day01/test.txt");
    defer lists.deinit();

    try std.testing.expectEqual(31, totalSimilarityScore(allocator, lists));
}
