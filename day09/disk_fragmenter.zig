const std = @import("std");

const FileNumber = u16;
const DiskMap = []?FileNumber;

pub fn parseDiskMapFile(allocator: std.mem.Allocator, file_name: []const u8) !DiskMap {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var lineBuf: [25 * 1024]u8 = undefined;
    const readLineBuf = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n') orelse unreachable;
    var total_count: usize = 0;
    for (readLineBuf) |count| {
        total_count += count - '0';
    }
    const result = try allocator.alloc(?FileNumber, total_count);
    var index: usize = 0;
    var disk_number: FileNumber = 0;
    for (readLineBuf, 0..) |ch, place| {
        const count = ch - '0';
        if (place % 2 == 0) {
            for (0..count) |_| {
                result[index] = disk_number;
                index += 1;
            }
            disk_number += 1;
        } else {
            for (0..count) |_| {
                result[index] = null;
                index += 1;
            }
        }
    }
    return result;
}

test parseDiskMapFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day09/parseDiskMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});

    const disk_map = try parseDiskMapFile(allocator, "data/day09/test.txt");
    try std.testing.expectEqualDeep(&[_]?FileNumber{
        0,
        0,
        null,
        null,
        null,
        1,
        1,
        1,
        null,
        null,
        null,
        2,
        null,
        null,
        null,
        3,
        3,
        3,
        null,
        4,
        4,
        null,
        5,
        5,
        5,
        5,
        null,
        6,
        6,
        6,
        6,
        null,
        7,
        7,
        7,
        null,
        8,
        8,
        8,
        8,
        9,
        9,
    }, disk_map);
}

pub fn fragmentDisk(allocator: std.mem.Allocator, disk_map: DiskMap) !DiskMap {
    var occupied: usize = 0;
    for (disk_map) |block| {
        if (block) |_| {
            occupied += 1;
        }
    }
    const fragmented = try allocator.alloc(?FileNumber, occupied);
    var src_index: usize = disk_map.len - 1;
    for (fragmented, 0..) |*block, index| {
        if (disk_map[index]) |src_block| {
            block.* = src_block;
        } else {
            while (disk_map[src_index] == null) {
                src_index -= 1;
            }
            block.* = disk_map[src_index].?;
            src_index -= 1;
        }
    }
    return fragmented;
}

test fragmentDisk {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day09/fragmentDisk\n", .{});
    std.debug.print("\tread input file\n", .{});
    const disk_map = try parseDiskMapFile(allocator, "data/day09/test.txt");

    std.debug.print("\tmove file blocks one at a time from the end of the disk to the leftmost free space block\n", .{});
    const fragmented_map = try fragmentDisk(allocator, disk_map);
    try std.testing.expectEqualDeep(&[_]?FileNumber{
        0, 0, 9, 9, 8, 1, 1, 1, 8, 8, 8, 2, 7, 7, 7, 3, 3, 3, 6, 4, 4, 6, 5, 5, 5, 5, 6, 6,
    }, fragmented_map);
}

const FindResult = struct {
    start: usize,
    end: usize,
    len: usize,
};

fn findFile(disk_map: DiskMap, file_number: FileNumber) ?FindResult {
    const start_index: usize = for (disk_map, 0..) |block, index| {
        if (block == file_number) {
            break index;
        }
    } else unreachable;
    const end_index: usize = for (disk_map[start_index..], start_index..) |block, index| {
        if (block != file_number) {
            break index;
        }
    } else disk_map.len;
    return .{
        .start = start_index,
        .end = end_index,
        .len = end_index - start_index,
    };
}

fn findEmptySpace(disk_map: DiskMap, after: usize) ?FindResult {
    const start_index: ?usize = for (after..disk_map.len) |index| {
        if (disk_map[index] == null) {
            break index;
        }
    } else null;
    if (start_index == null) return null;
    const end_index: usize = for (start_index.?..disk_map.len) |index| {
        if (disk_map[index] != null) {
            break index;
        }
    } else disk_map.len;
    return .{
        .start = start_index.?,
        .end = end_index,
        .len = end_index - start_index.?,
    };
}

pub fn defragmentDisk(allocator: std.mem.Allocator, disk_map: DiskMap) !DiskMap {
    const defragmented = try allocator.alloc(?FileNumber, disk_map.len);
    std.mem.copyForwards(?FileNumber, defragmented, disk_map);
    var file_number: FileNumber = for (0..defragmented.len) |index| {
        if (defragmented[defragmented.len - index - 1]) |block| {
            break block;
        }
    } else unreachable;
    while (file_number > 0) {
        const file = findFile(defragmented, file_number).?;
        var after: usize = 0;
        while (findEmptySpace(defragmented[0..file.start], after)) |empty| {
            if (file.len <= empty.len) {
                for (defragmented[file.start..file.end], 0..) |block, index| {
                    defragmented[empty.start + index] = block;
                    defragmented[file.start + index] = null;
                }
                break;
            }
            after = empty.end;
        }
        file_number -= 1;
    }
    return defragmented;
}

test defragmentDisk {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day09/fragmentDisk\n", .{});
    std.debug.print("\tread input file\n", .{});
    const disk_map = try parseDiskMapFile(allocator, "data/day09/test.txt");

    std.debug.print("\tAttempt to move each file exactly once in order of decreasing file ID number starting with the file with the highest file ID number.\n", .{});
    std.debug.print("\tIf there is no span of free space to the left of a file that is large enough to fit the file, the file does not move.\n", .{});
    const defragmented_map = try defragmentDisk(allocator, disk_map);
    try std.testing.expectEqualDeep(&[_]?FileNumber{
        0, 0, 9, 9, 2, 1, 1, 1, 7, 7, 7, null, 4, 4, null, 3, 3, 3, null, null, null, null, 5, 5, 5, 5, null, 6, 6, 6, 6, null, null, null, null, null, 8, 8, 8, 8, null, null,
    }, defragmented_map);
}

pub fn checksum(disk_map: DiskMap) usize {
    var sum: usize = 0;
    for (disk_map, 0..) |block, index| {
        if (block) |b| {
            sum += b * index;
        }
    }
    return sum;
}

test checksum {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day09/checksum\n", .{});
    std.debug.print("\tread input file\n", .{});
    const disk_map = try parseDiskMapFile(allocator, "data/day09/test.txt");
    std.debug.print("\tfragment disk\n", .{});
    const fragmented_map = try fragmentDisk(allocator, disk_map);
    std.debug.print("\tdefragment disk\n", .{});
    const defragmented_map = try defragmentDisk(allocator, disk_map);
    std.debug.print("\tadd up the result of multiplying each of these blocks' position with the file ID number it contains\n", .{});
    try std.testing.expectEqual(1928, checksum(fragmented_map));
    try std.testing.expectEqual(2858, checksum(defragmented_map));
}
