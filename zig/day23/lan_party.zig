const std = @import("std");

const ComputerName = []const u8;

const ComputerPair = struct {
    allocator: std.mem.Allocator,
    c1: ComputerName,
    c2: ComputerName,
    pub fn deinit(self: *ComputerPair) void {
        self.allocator.free(self.c1);
        self.allocator.free(self.c2);
    }
};

const NetworkMap = struct {
    allocator: std.mem.Allocator,
    pairs: []ComputerPair,
    pub fn bufPrint(self: NetworkMap, buf: []u8) []u8 {
        var printed: usize = 0;
        for (self.pairs) |pair| {
            const b = std.fmt.bufPrint(buf[printed..], "{s}-{s}\n", .{ pair.c1, pair.c2 }) catch unreachable;
            printed += b.len;
        }
        return buf[0 .. printed - 1];
    }
    pub fn deinit(self: *NetworkMap) void {
        for (self.pairs) |*pair| {
            pair.deinit();
        }
        self.allocator.free(self.pairs);
    }
};

pub fn parseNetworkMapFile(allocator: std.mem.Allocator, file_name: []const u8) !NetworkMap {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var pairs_list = std.ArrayList(ComputerPair).init(allocator);
    defer pairs_list.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |pair_line| {
        var it = std.mem.splitScalar(u8, pair_line, '-');
        const c1 = it.next().?;
        const c2 = it.next().?;
        try pairs_list.append(ComputerPair{
            .allocator = allocator,
            .c1 = try allocator.dupe(u8, c1),
            .c2 = try allocator.dupe(u8, c2),
        });
    }

    return NetworkMap{
        .allocator = allocator,
        .pairs = try pairs_list.toOwnedSlice(),
    };
}

test parseNetworkMapFile {
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** 1024;

    std.debug.print("day23/parseNetworkMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    var network_map = try parseNetworkMapFile(allocator, "data/day23/test.txt");
    defer network_map.deinit();
    try std.testing.expectEqualStrings(
        \\kh-tc
        \\qp-kh
        \\de-cg
        \\ka-co
        \\yn-aq
        \\qp-ub
        \\cg-tb
        \\vc-aq
        \\tb-ka
        \\wh-tc
        \\yn-cg
        \\kh-ub
        \\ta-co
        \\de-co
        \\tc-td
        \\tb-wq
        \\wh-td
        \\ta-ka
        \\td-qp
        \\aq-cg
        \\wq-ub
        \\ub-vc
        \\de-ta
        \\wq-aq
        \\wq-vc
        \\wh-yn
        \\ka-de
        \\kh-ta
        \\co-tc
        \\wh-qp
        \\tb-vc
        \\td-yn
    , network_map.bufPrint(&print_buf));
}

fn bufPrintNamesSet(buf: []u8, names_set: std.BufSet) []u8 {
    if (names_set.count() == 0) {
        return buf[0..0];
    }
    var it = names_set.iterator();
    var printed: usize = 0;
    while (it.next()) |ptr| {
        const b = std.fmt.bufPrint(buf[printed..], "{s},", .{ptr.*}) catch unreachable;
        printed += b.len;
    }
    return buf[0 .. printed - 1];
}

const PairingSets = struct {
    sets: std.StringHashMap(std.BufSet),
    pub fn deinit(self: *PairingSets) void {
        var it = self.sets.iterator();
        while (it.next()) |kv| {
            kv.value_ptr.deinit();
        }
        self.sets.deinit();
    }
    pub fn bufPrint(self: PairingSets, buf: []u8) []u8 {
        var printed: usize = 0;
        var it = self.sets.iterator();
        while (it.next()) |kv| {
            var b = std.fmt.bufPrint(buf[printed..], "{s} = ", .{kv.key_ptr.*}) catch unreachable;
            printed += b.len;
            b = bufPrintNamesSet(buf[printed..], kv.value_ptr.*);
            printed += b.len;
            buf[printed] = '\n';
            printed += 1;
        }
        return buf[0 .. printed - 1];
    }
};

fn pairingSets(allocator: std.mem.Allocator, network_map: NetworkMap) !PairingSets {
    var sets = std.StringHashMap(std.BufSet).init(allocator);
    for (network_map.pairs) |pair| {
        var name = pair.c1;
        if (!sets.contains(name)) {
            var pairs_set = std.BufSet.init(allocator);
            for (network_map.pairs) |p| {
                if (std.mem.eql(u8, name, p.c1)) {
                    _ = try pairs_set.insert(p.c2);
                }
                if (std.mem.eql(u8, name, p.c2)) {
                    _ = try pairs_set.insert(p.c1);
                }
            }
            _ = try sets.put(name, pairs_set);
        }
        name = pair.c2;
        if (!sets.contains(name)) {
            var pairs_set = std.BufSet.init(allocator);
            for (network_map.pairs) |p| {
                if (std.mem.eql(u8, name, p.c1)) {
                    _ = try pairs_set.insert(p.c2);
                }
                if (std.mem.eql(u8, name, p.c2)) {
                    _ = try pairs_set.insert(p.c1);
                }
            }
            _ = try sets.put(name, pairs_set);
        }
    }
    return PairingSets{ .sets = sets };
}

test pairingSets {
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** (10 * 1024);

    std.debug.print("day23/pairingSets\n", .{});
    std.debug.print("\tread input file\n", .{});
    var network_map = try parseNetworkMapFile(allocator, "data/day23/test.txt");
    defer network_map.deinit();
    std.debug.print("\ttransform network pairs to pairing sets map\n", .{});
    var pairing_sets = try pairingSets(allocator, network_map);
    defer pairing_sets.deinit();
    try std.testing.expectEqualStrings(
        \\ub = wq,vc,kh,qp
        \\de = co,cg,ta,ka
        \\co = tc,ta,ka,de
        \\cg = aq,de,tb,yn
        \\ka = co,ta,tb,de
        \\wh = tc,td,qp,yn
        \\qp = ub,td,wh,kh
        \\tc = td,co,wh,kh
        \\td = tc,yn,wh,qp
        \\wq = ub,tb,vc,aq
        \\kh = tc,ub,ta,qp
        \\yn = td,cg,wh,aq
        \\aq = cg,wq,vc,yn
        \\ta = co,ka,de,kh
        \\tb = cg,ka,wq,vc
        \\vc = ub,wq,tb,aq
    , pairing_sets.bufPrint(&print_buf));
}

const Threesome = struct {
    c1: ComputerName,
    c2: ComputerName,
    c3: ComputerName,
    pub fn isEqual(self: Threesome, other: Threesome) bool {
        return (std.mem.eql(u8, self.c1, other.c1) or
            std.mem.eql(u8, self.c1, other.c2) or
            std.mem.eql(u8, self.c1, other.c3)) and (std.mem.eql(u8, self.c2, other.c1) or
            std.mem.eql(u8, self.c2, other.c2) or
            std.mem.eql(u8, self.c2, other.c3)) and (std.mem.eql(u8, self.c3, other.c1) or
            std.mem.eql(u8, self.c3, other.c2) or
            std.mem.eql(u8, self.c3, other.c3));
    }
};

const ThreesomesSet = struct {
    threes: std.ArrayList(Threesome),
    pub fn init(allocator: std.mem.Allocator) ThreesomesSet {
        return ThreesomesSet{ .threes = std.ArrayList(Threesome).init(allocator) };
    }
    pub fn deinit(self: ThreesomesSet) void {
        for (self.threes.items) |threesome| {
            self.threes.allocator.free(threesome.c1);
            self.threes.allocator.free(threesome.c2);
            self.threes.allocator.free(threesome.c3);
        }
        self.threes.deinit();
    }
    pub fn bufPrint(self: ThreesomesSet, buf: []u8) []u8 {
        var printed: usize = 0;
        for (self.threes.items) |threesome| {
            var b = std.fmt.bufPrint(buf[printed..], "{s},", .{threesome.c1}) catch unreachable;
            printed += b.len;
            b = std.fmt.bufPrint(buf[printed..], "{s},", .{threesome.c2}) catch unreachable;
            printed += b.len;
            b = std.fmt.bufPrint(buf[printed..], "{s}\n", .{threesome.c3}) catch unreachable;
            printed += b.len;
        }
        return buf[0 .. printed - 1];
    }
    pub fn append(self: *ThreesomesSet, threesome: Threesome) !void {
        for (self.threes.items) |three| {
            if (three.isEqual(threesome)) {
                // std.debug.print("-> already\n", .{});
                return;
            }
        }
        // std.debug.print("-> c1 = {s}, c2 = {s}, c3 = {s}\n", .{ threesome.c1, threesome.c2, threesome.c3 });
        try self.threes.append(.{
            .c1 = try self.threes.allocator.dupe(u8, threesome.c1),
            .c2 = try self.threes.allocator.dupe(u8, threesome.c2),
            .c3 = try self.threes.allocator.dupe(u8, threesome.c3),
        });
    }
};

fn intersection(allocator: std.mem.Allocator, set1: std.BufSet, set2: std.BufSet) !std.BufSet {
    var result = std.BufSet.init(allocator);
    var it = set1.iterator();
    while (it.next()) |ptr| {
        if (set2.contains(ptr.*)) {
            _ = try result.insert(ptr.*);
        }
    }
    return result;
}

fn threesomes(allocator: std.mem.Allocator, network_map: NetworkMap) !ThreesomesSet {
    var result = ThreesomesSet.init(allocator);
    var pairing_sets = try pairingSets(allocator, network_map);
    defer pairing_sets.deinit();
    var map_it = pairing_sets.sets.iterator();
    while (map_it.next()) |kv| {
        const c1 = kv.key_ptr.*;
        const c1_pairs_set = kv.value_ptr.*;
        var set_it = c1_pairs_set.iterator();
        while (set_it.next()) |ptr| {
            const c2 = ptr.*;
            const c2_pairs_set = pairing_sets.sets.get(c2).?;
            var c3s_set = try intersection(allocator, c1_pairs_set, c2_pairs_set);
            defer c3s_set.deinit();
            // var print_buf = [1]u8{0} ** (10 * 1024);
            // std.debug.print("c1 = {s}, c2 = {s}\n", .{ c1, c2 });
            // std.debug.print("c1_set = {s}\n", .{bufPrintNamesSet(&print_buf, c1_pairs_set)});
            // std.debug.print("c2_set = {s}\n", .{bufPrintNamesSet(&print_buf, c2_pairs_set)});
            // std.debug.print("c3_set = {s}\n", .{bufPrintNamesSet(&print_buf, c3s_set)});
            var c3_it = c3s_set.iterator();
            while (c3_it.next()) |ptr2| {
                const c3 = ptr2.*;
                try result.append(Threesome{ .c1 = c1, .c2 = c2, .c3 = c3 });
            }
        }
    }
    return result;
}

test threesomes {
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** (10 * 1024);

    std.debug.print("day23/threesomes\n", .{});
    std.debug.print("\tread input file\n", .{});
    var network_map = try parseNetworkMapFile(allocator, "data/day23/test.txt");
    defer network_map.deinit();
    std.debug.print("\textract all threesomes in network map\n", .{});
    const threes = try threesomes(allocator, network_map);
    defer threes.deinit();
    try std.testing.expectEqualStrings(
        \\ub,wq,vc
        \\ub,kh,qp
        \\de,co,ta
        \\de,co,ka
        \\de,ta,ka
        \\co,ta,ka
        \\cg,aq,yn
        \\wh,tc,td
        \\wh,td,yn
        \\wh,td,qp
        \\wq,tb,vc
        \\wq,vc,aq
    , threes.bufPrint(&print_buf));
}

pub fn chiefHistorianThreesomeCandidates(allocator: std.mem.Allocator, network_map: NetworkMap) !ThreesomesSet {
    const threesomes_set = try threesomes(allocator, network_map);
    defer threesomes_set.deinit();
    var result = ThreesomesSet.init(allocator);
    for (threesomes_set.threes.items) |threesome| {
        if (threesome.c1[0] == 't' or threesome.c2[0] == 't' or threesome.c3[0] == 't') {
            try result.append(threesome);
        }
    }
    return result;
}

test chiefHistorianThreesomeCandidates {
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** (10 * 1024);

    std.debug.print("day23/chiefHistorianThreesomeCandidates\n", .{});
    std.debug.print("\tread input file\n", .{});
    var network_map = try parseNetworkMapFile(allocator, "data/day23/test.txt");
    defer network_map.deinit();
    std.debug.print("\textract all threesomes in network map with at least one computer name starting with t\n", .{});
    const candidates = try chiefHistorianThreesomeCandidates(allocator, network_map);
    defer candidates.deinit();
    try std.testing.expectEqualStrings(
        \\de,co,ta
        \\de,ta,ka
        \\co,ta,ka
        \\wh,tc,td
        \\wh,td,yn
        \\wh,td,qp
        \\wq,tb,vc
    , candidates.bufPrint(&print_buf));
}

fn maxSizeGroup(allocator: std.mem.Allocator, pairing_sets: PairingSets, name: ComputerName, current_pairings: std.BufSet) !std.BufSet {
    // var print_buf = [1]u8{0} ** (10 * 1024);
    // std.debug.print("maxSizeGroup: name = {s}, current_pairings = {s}\n", .{ name, bufPrintNamesSet(&print_buf, current_pairings) });
    if (current_pairings.count() == 0) {
        var result = try current_pairings.clone();
        try result.insert(name);
        // std.debug.print("->(0) {s}\n", .{bufPrintNamesSet(&print_buf, result)});
        return result;
    }
    if (current_pairings.count() == 1) {
        var result = try current_pairings.clone();
        try result.insert(name);
        // std.debug.print("->(1) {s}\n", .{bufPrintNamesSet(&print_buf, result)});
        return result;
    }
    var max_size_group: std.BufSet = std.BufSet.init(allocator);
    var max_size: usize = 0;
    var remaining_pairings = current_pairings.count();
    var it = current_pairings.iterator();
    while (it.next()) |ptr| {
        if (max_size >= remaining_pairings) {
            break;
        }
        const pair_name = ptr.*;
        const pairings_set = pairing_sets.sets.get(pair_name).?;
        var common_pairings_set = try intersection(allocator, current_pairings, pairings_set);
        defer common_pairings_set.deinit();
        var group = try maxSizeGroup(allocator, pairing_sets, pair_name, common_pairings_set);
        if (group.count() > max_size) {
            max_size_group.deinit();
            max_size = group.count();
            max_size_group = group;
        } else {
            group.deinit();
        }
        remaining_pairings -= 1;
    }
    try max_size_group.insert(name);
    // std.debug.print("->(N) {s}\n", .{bufPrintNamesSet(&print_buf, max_size_group)});
    return max_size_group;
}

pub fn lanParty(allocator: std.mem.Allocator, network_map: NetworkMap) !void {
    var print_buf = [1]u8{0} ** (10 * 1024);
    var pairing_sets = try pairingSets(allocator, network_map);
    defer pairing_sets.deinit();
    var max_size_group: std.BufSet = std.BufSet.init(allocator);
    var max_size: usize = 0;
    var map_it = pairing_sets.sets.iterator();
    const names_count = pairing_sets.sets.count();
    var i: usize = 0;
    while (map_it.next()) |kv| {
        // for (0..1) |_| {
        //     const kv = map_it.next().?;
        const name = kv.key_ptr.*;
        const pairings_set = kv.value_ptr.*;
        std.debug.print("[{d}/{d}]============ {s}\n", .{ i, names_count, name });
        var group = try maxSizeGroup(allocator, pairing_sets, name, pairings_set);
        if (group.count() > max_size) {
            max_size_group.deinit();
            max_size = group.count();
            max_size_group = group;
            std.debug.print("max_size_group = {s}\n", .{bufPrintNamesSet(&print_buf, max_size_group)});
        } else {
            group.deinit();
        }
        i += 1;
    }
    std.debug.print("max_size_group = {s}\n", .{bufPrintNamesSet(&print_buf, max_size_group)});
    max_size_group.deinit();
}

test lanParty {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    // const allocator = arena.allocator();

    std.debug.print("day23/lanParty\n", .{});
    std.debug.print("\tread input file\n", .{});
    var network_map = try parseNetworkMapFile(allocator, "data/day23/test.txt");
    defer network_map.deinit();
    std.debug.print("\tlocate the lan party\n", .{});
    try lanParty(allocator, network_map);
}
// az,cg,ei,hz,jc,km,kt,mv,sv,sx,wc,wq,xy
