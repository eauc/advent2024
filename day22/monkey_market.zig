const std = @import("std");

const Secret = usize;

pub fn parseBuyerSecretsFile(allocator: std.mem.Allocator, file_name: []const u8) ![]Secret {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var secrets_list = std.ArrayList(Secret).init(allocator);
    defer secrets_list.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |secret_line| {
        const secret = try std.fmt.parseInt(usize, secret_line, 10);

        try secrets_list.append(secret);
    }

    return secrets_list.toOwnedSlice();
}

test parseBuyerSecretsFile {
    const allocator = std.testing.allocator;

    std.debug.print("day22/parseBuyerSecretsFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    const buyer_secrets = try parseBuyerSecretsFile(allocator, "data/day22/test.txt");
    defer allocator.free(buyer_secrets);
    try std.testing.expectEqualDeep(&[_]usize{
        1,
        10,
        100,
        2024,
    }, buyer_secrets);
}

fn mix(secret: Secret, value: Secret) Secret {
    return value ^ secret;
}

test mix {
    std.debug.print("day22/mix\n", .{});
    try std.testing.expectEqual(
        37,
        mix(42, 15),
    );
}

fn prune(secret: Secret) Secret {
    return secret % 16777216;
}

test prune {
    std.debug.print("day22/prune\n", .{});
    try std.testing.expectEqual(
        16113920,
        prune(100000000),
    );
}

fn nextSecret(secret: Secret) Secret {
    const stage_one = prune(mix(secret, secret * 64));
    const stage_two = prune(mix(stage_one, @divFloor(stage_one, 32)));
    return prune(mix(stage_two, stage_two * 2048));
}

test nextSecret {
    std.debug.print("day22/nextSecret\n", .{});
    var secret: usize = 123;
    for ([_]usize{
        15887950,
        16495136,
        527345,
        704524,
        1553684,
        12683156,
        11100544,
        12249484,
        7753432,
        5908254,
    }, 0..) |expected, i| {
        std.debug.print("\t[{d}] {d} -> {d}\n", .{ i, secret, expected });
        const next_secret = nextSecret(secret);
        try std.testing.expectEqual(expected, next_secret);
        secret = next_secret;
    }
}

fn evolve(secret: Secret, depth: usize) Secret {
    var current = secret;
    for (0..depth) |_| {
        const next_secret = nextSecret(current);
        current = next_secret;
    }
    return current;
}

test evolve {
    const allocator = std.testing.allocator;

    std.debug.print("day22/evolve\n", .{});
    std.debug.print("\tread input file\n", .{});
    const buyer_secrets = try parseBuyerSecretsFile(allocator, "data/day22/test.txt");
    defer allocator.free(buyer_secrets);

    for ([_]usize{
        8685429,
        4700978,
        15273692,
        8667524,
    }, 0..) |expected, i| {
        std.debug.print("\t[{d}]x2000 {d} -> {d}\n", .{ i, buyer_secrets[i], expected });
        try std.testing.expectEqual(expected, evolve(buyer_secrets[i], 2000));
    }
}

pub fn part1Checksum(secrets: []Secret) usize {
    var sum: usize = 0;
    for (secrets) |secret| {
        sum += evolve(secret, 2000);
    }
    return sum;
}

test part1Checksum {
    const allocator = std.testing.allocator;

    std.debug.print("day22/part1Checksum\n", .{});
    std.debug.print("\tread input file\n", .{});
    const buyer_secrets = try parseBuyerSecretsFile(allocator, "data/day22/test.txt");
    defer allocator.free(buyer_secrets);

    std.debug.print("\tchecksum\n", .{});
    try std.testing.expectEqual(37327623, part1Checksum(buyer_secrets));
}

const Price = i8;

fn price(secret: Secret) Price {
    const result: isize = @intCast(secret % 10);
    return @truncate(result);
}

const PriceSequence = []Price;

fn priceSequence(allocator: std.mem.Allocator, secret: Secret, depth: usize) !PriceSequence {
    var result = try allocator.alloc(Price, depth + 1);
    var current = secret;
    for (0..depth + 1) |i| {
        result[i] = price(current);
        current = nextSecret(current);
    }
    return result;
}

test price {
    const allocator = std.testing.allocator;

    std.debug.print("day22/price\n", .{});
    const price_seq = try priceSequence(allocator, 123, 15);
    defer allocator.free(price_seq);
    try std.testing.expectEqualDeep(
        &[_]Price{ 3, 0, 6, 5, 4, 4, 6, 4, 4, 2, 4, 0, 4, 0, 3, 9 },
        price_seq,
    );
}

const PriceChangeSequenceMap = std.StringHashMap(Price);

fn freeStringHashMap(map: *PriceChangeSequenceMap) void {
    var it = map.iterator();
    while (it.next()) |entry| {
        map.allocator.free(entry.key_ptr.*);
    }
    map.deinit();
}

fn wrapIndex(index: usize, dec: usize) usize {
    if (index >= dec) {
        return index - dec;
    }
    return 4 + index - dec;
}

fn insertPriceChangeSequenceMap(map: *PriceChangeSequenceMap, price_change_sequence: [4]Price, current_change_index: usize, current_price: Price) !void {
    var print_buf = [1]u8{0} ** 128;
    const key = try std.fmt.bufPrint(&print_buf, "[{d},{d},{d},{d}]", .{
        price_change_sequence[wrapIndex(current_change_index, 3)],
        price_change_sequence[wrapIndex(current_change_index, 2)],
        price_change_sequence[wrapIndex(current_change_index, 1)],
        price_change_sequence[current_change_index],
    });
    if (!map.contains(key)) {
        _ = try map.put(try map.allocator.dupe(u8, key), current_price);
    }
}

fn priceChangeSequenceMap(allocator: std.mem.Allocator, price_seq: PriceSequence) !PriceChangeSequenceMap {
    var result = PriceChangeSequenceMap.init(allocator);
    var price_change_sequence = [4]Price{
        price_seq[1] - price_seq[0],
        price_seq[2] - price_seq[1],
        price_seq[3] - price_seq[2],
        price_seq[4] - price_seq[3],
    };
    var current_price = price_seq[3];
    var current_change_index: usize = 3;
    for (price_seq[4..]) |new_price| {
        const price_change: i8 = new_price - current_price;
        price_change_sequence[current_change_index] = price_change;

        try insertPriceChangeSequenceMap(&result, price_change_sequence, current_change_index, new_price);

        current_change_index = (current_change_index + 1) % 4;
        current_price = new_price;
    }
    // var it = result.iterator();
    // while (it.next()) |entry| {
    //     std.debug.print("{s}: {d}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    // }
    return result;
}

test priceChangeSequenceMap {
    const allocator = std.testing.allocator;

    std.debug.print("day22/priceChangeMap\n", .{});
    const prices_seq = try priceSequence(allocator, 123, 15);
    defer allocator.free(prices_seq);
    var price_change_sequence_map = try priceChangeSequenceMap(allocator, prices_seq);
    defer freeStringHashMap(&price_change_sequence_map);
    try std.testing.expectEqual(12, price_change_sequence_map.count());
    for ([_]struct { key: []const u8, price: Price }{
        .{ .key = "[-3,6,-1,-1]", .price = 4 },
        .{ .key = "[6,-1,-1,0]", .price = 4 },
        .{ .key = "[-1,-1,0,2]", .price = 6 },
        .{ .key = "[-1,0,2,-2]", .price = 4 },
        .{ .key = "[0,2,-2,0]", .price = 4 },
        .{ .key = "[2,-2,0,-2]", .price = 2 },
        .{ .key = "[-2,0,-2,2]", .price = 4 },
        .{ .key = "[0,-2,2,-4]", .price = 0 },
        .{ .key = "[-2,2,-4,4]", .price = 4 },
        .{ .key = "[2,-4,4,-4]", .price = 0 },
        .{ .key = "[-4,4,-4,3]", .price = 3 },
        .{ .key = "[4,-4,3,6]", .price = 9 },
    }) |expected| {
        std.debug.print("\t{s}: {d}\n", .{ expected.key, expected.price });
        try std.testing.expectEqual(expected.price, price_change_sequence_map.get(expected.key));
    }
}

const PriceChangeSequenceSet = std.BufSet;

fn priceChangeSequenceSet(allocator: std.mem.Allocator, price_change_sequence_maps: std.ArrayList(PriceChangeSequenceMap)) !PriceChangeSequenceSet {
    var result = PriceChangeSequenceSet.init(allocator);
    for (price_change_sequence_maps.items) |price_change_sequence_map| {
        var it = price_change_sequence_map.iterator();
        while (it.next()) |entry| {
            try result.insert(entry.key_ptr.*);
        }
    }
    return result;
}

pub fn optimalSell(allocator: std.mem.Allocator, buyer_secrets: []const Secret) !isize {
    var price_change_sequence_maps = std.ArrayList(PriceChangeSequenceMap).init(allocator);
    defer price_change_sequence_maps.deinit();
    for (buyer_secrets) |secret| {
        const price_seq = try priceSequence(allocator, secret, 2001);
        defer allocator.free(price_seq);

        const price_change_map = try priceChangeSequenceMap(allocator, price_seq);
        try price_change_sequence_maps.append(price_change_map);
        // std.debug.print("[{d}/{d}] {d} map count = {d}\n", .{ i, buyer_secrets.len, secret, price_change_map.count() });
    }

    var price_change_sequence_set = try priceChangeSequenceSet(allocator, price_change_sequence_maps);
    defer price_change_sequence_set.deinit();
    // std.debug.print("set count = {d}\n", .{price_change_sequence_set.count()});

    var optimal_price: isize = 0;
    var it = price_change_sequence_set.iterator();
    while (it.next()) |ptr| {
        const price_change_sequence_key = ptr.*;
        var total_price: isize = 0;
        for (price_change_sequence_maps.items) |map| {
            if (map.get(price_change_sequence_key)) |price_change| {
                total_price += @intCast(price_change);
            }
        }
        if (total_price > optimal_price) {
            // std.debug.print("{s}: {d}\n", .{ price_change_sequence_key, total_price });
            optimal_price = total_price;
        }
    }
    for (price_change_sequence_maps.items) |*map| {
        freeStringHashMap(map);
    }
    return optimal_price;
}

test optimalSell {
    const allocator = std.testing.allocator;

    std.debug.print("day22/optimalSell\n", .{});
    const optimal_price = try optimalSell(allocator, &[_]Secret{ 1, 2, 3, 2024 });
    try std.testing.expectEqual(23, optimal_price);
}
