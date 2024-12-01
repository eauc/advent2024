const std = @import("std");

const Location = isize;
const LocationList = []Location;
const LocationListsPair = struct {
    left: LocationList,
    right: LocationList,
    pub fn deinit(self: *LocationListsPair, allocator: std.mem.Allocator) void {
        allocator.free(self.left);
        allocator.free(self.right);
    }
};

pub fn printLocationList(name: []const u8, list: LocationList) void {
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
    var locationBuf = [_]Location{2} ** 10;

    var left_list = std.ArrayList(Location).init(allocator);
    defer left_list.deinit();
    var right_list = std.ArrayList(Location).init(allocator);
    defer right_list.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |line| {
        var i: usize = 0;
        var it = std.mem.splitScalar(u8, line, ' ');

        while (it.next()) |token| {
            if (token.len == 0) continue;
            locationBuf[i] = try std.fmt.parseInt(Location, token, 10);
            i += 1;
            if (i == locationBuf.len) break;
        }

        try left_list.append(locationBuf[0]);
        try right_list.append(locationBuf[1]);
    }

    return .{
        .left = try left_list.toOwnedSlice(),
        .right = try right_list.toOwnedSlice(),
    };
}

test parseLocationListsFile {
    const allocator = std.testing.allocator;

    std.debug.print("day01/parseLocationListsFile\n", .{});
    var lists = try parseLocationListsFile(allocator, "data/day01/test.txt");
    defer lists.deinit(allocator);
    try std.testing.expectEqualSlices(Location, &[_]Location{ 3, 4, 2, 1, 3, 3 }, lists.left);
    try std.testing.expectEqualSlices(Location, &[_]Location{ 4, 3, 5, 3, 9, 3 }, lists.right);
}

pub fn totalDistance(lists: LocationListsPair) usize {
    std.mem.sort(Location, lists.left, {}, comptime std.sort.asc(Location));
    std.mem.sort(Location, lists.right, {}, comptime std.sort.asc(Location));
    var total_distance: usize = 0;
    for (lists.left, lists.right) |left, right| {
        const distance = @abs(left - right);
        total_distance += distance;
    }
    return total_distance;
}

test totalDistance {
    const allocator = std.testing.allocator;

    std.debug.print("day01/totalDistance\n", .{});
    // pairs up the numbers and measures how far apart they are.
    // Pair up the smallest number in the left list with the smallest number in the right list,
    // then the second-smallest left number with the second-smallest right number,
    // and so on
    var lists = try parseLocationListsFile(allocator, "data/day01/test.txt");
    defer lists.deinit(allocator);
    try std.testing.expectEqual(11, totalDistance(lists));
}

fn printFrequencies(frequencies: std.AutoHashMap(isize, isize)) void {
    std.debug.print("frequencies:\n", .{});
    var it = frequencies.iterator();
    while (it.next()) |entry| {
        std.debug.print("{}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

fn locationFrequencies(allocator: std.mem.Allocator, list: LocationList) !std.AutoHashMap(isize, isize) {
    var frequencies = std.AutoHashMap(isize, isize).init(allocator);
    for (list) |location| {
        if (frequencies.get(location)) |frequency| {
            try frequencies.put(location, frequency + 1);
        } else {
            try frequencies.put(location, 1);
        }
    }
    // printFrequencies(right_list_frequencies);
    return frequencies;
}

pub fn totalSimilarityScore(allocator: std.mem.Allocator, lists: LocationListsPair) !usize {
    var right_list_frequencies = try locationFrequencies(allocator, lists.right);
    defer right_list_frequencies.deinit();

    var total_similarity_score: usize = 0;
    for (lists.left) |location| {
        if (right_list_frequencies.get(location)) |frequency| {
            total_similarity_score += @intCast(location * frequency);
        }
    }
    return total_similarity_score;
}

test totalSimilarityScore {
    const allocator = std.testing.allocator;

    std.debug.print("day01/totalSimilarityScore\n", .{});
    // adds up each number in the left list
    // after multiplying it by the number of times that number appears in the right list
    var lists = try parseLocationListsFile(allocator, "data/day01/test.txt");
    defer lists.deinit(allocator);
    try std.testing.expectEqual(31, try totalSimilarityScore(allocator, lists));
}
