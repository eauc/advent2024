const std = @import("std");

pub fn parseXXFile(allocator: std.mem.Allocator, file_name: []const u8) !void {
    _ = allocator;
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |robot_line| {
        var it = std.mem.splitScalar(u8, robot_line, ' ');
        const token = it.next().?;
        const number = try std.fmt.parseInt(isize, token, 10);
        _ = number;
    }
}

test parseXXFile {
    const allocator = std.testing.allocator;

    std.debug.print("dayXX/parseXXFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    const xxx = try parseXXFile(allocator, "data/dayXX/test.txt");
    _ = xxx;
}
