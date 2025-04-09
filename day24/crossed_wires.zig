const std = @import("std");

const WireName = []const u8;
const WireValue = u1;
const WireValues = struct {
    map: std.StringHashMap(WireValue),
    pub fn init(allocator: std.mem.Allocator) WireValues {
        return .{ .map = std.StringHashMap(WireValue).init(allocator) };
    }
    pub fn deinit(self: *WireValues) void {
        var it = self.map.iterator();
        while (it.next()) |kv| {
            self.map.allocator.free(kv.key_ptr.*);
        }
        self.map.deinit();
    }
    pub fn bufPrint(self: WireValues, buf: []u8) []u8 {
        var printed: usize = 0;
        var it = self.map.iterator();
        while (it.next()) |kv| {
            const b = std.fmt.bufPrint(buf[printed..], "{s} = {d}\n", .{ kv.key_ptr.*, kv.value_ptr.* }) catch unreachable;
            printed += b.len;
        }
        return buf[0 .. printed - 1];
    }
};

const GateType = enum {
    AND,
    OR,
    XOR,
};

const Gate = struct {
    type: GateType,
    lhs: WireName,
    rhs: WireName,
    out: WireName,
};

const GatesMap = struct {
    map: std.StringHashMap(Gate),
    pub fn init(allocator: std.mem.Allocator) GatesMap {
        return .{ .map = std.StringHashMap(Gate).init(allocator) };
    }
    pub fn clone(self: GatesMap) !GatesMap {
        return .{ .map = try self.map.clone() };
    }
    pub fn put(self: *GatesMap, gate: Gate) !void {
        if (self.map.contains(gate.out)) {
            return;
        }
        const out = try self.map.allocator.dupe(u8, gate.out);
        try self.map.put(out, .{
            .type = gate.type,
            .lhs = try self.map.allocator.dupe(u8, gate.lhs),
            .rhs = try self.map.allocator.dupe(u8, gate.rhs),
            .out = out,
        });
    }
    pub fn deinit(self: *GatesMap) void {
        var it = self.map.iterator();
        while (it.next()) |kv| {
            const gate = kv.value_ptr.*;
            self.map.allocator.free(kv.key_ptr.*);
            self.map.allocator.free(gate.lhs);
            self.map.allocator.free(gate.rhs);
        }
        self.map.deinit();
    }
    pub fn bufPrint(self: GatesMap, buf: []u8) []u8 {
        var printed: usize = 0;
        var it = self.map.iterator();
        while (it.next()) |kv| {
            const b = std.fmt.bufPrint(buf[printed..], "{s} {?s} {s} -> {s}\n", .{
                kv.value_ptr.*.lhs,
                std.enums.tagName(GateType, kv.value_ptr.*.type),
                kv.value_ptr.*.rhs,
                kv.key_ptr.*,
            }) catch unreachable;
            printed += b.len;
        }
        return buf[0 .. printed - 1];
    }
};

const ParseResult = struct {
    wire_values: WireValues,
    gates_map: GatesMap,
    outs: []WireName,
};

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(.lt);
}

pub fn parseWiresFile(allocator: std.mem.Allocator, file_name: []const u8) !ParseResult {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var wire_values = WireValues.init(allocator);

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |value_line| {
        if (value_line.len == 0) {
            break;
        }
        var it = std.mem.splitScalar(u8, value_line, ':');
        const name = it.next().?;
        const value_token = it.next().?;
        const value = try std.fmt.parseInt(WireValue, value_token[1..], 10);
        // std.debug.print("wire value {s} = {d}\n", .{ name, value });
        try wire_values.map.put(try allocator.dupe(u8, name), value);
    }

    var gates_map = GatesMap.init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |gate_line| {
        var it = std.mem.splitScalar(u8, gate_line, ' ');
        const lhs = it.next().?;
        const type_token = it.next().?;
        const gate_type = std.meta.stringToEnum(GateType, type_token) orelse unreachable;
        const rhs = it.next().?;
        _ = it.next().?; // ->
        const out = it.next().?;
        // std.debug.print("gate {s} {?s} {s} -> {s}\n", .{ lhs, std.enums.tagName(GateType, gate_type), rhs, out });
        const out_key = try allocator.dupe(u8, out);
        try gates_map.map.put(out_key, .{
            .type = gate_type,
            .lhs = try allocator.dupe(u8, lhs),
            .rhs = try allocator.dupe(u8, rhs),
            .out = out_key,
        });
    }

    var outs_list = std.ArrayList(WireName).init(allocator);
    defer outs_list.deinit();
    var it = gates_map.map.iterator();
    while (it.next()) |kv| {
        const name = kv.key_ptr.*;
        if (name[0] == 'z') {
            try outs_list.append(kv.key_ptr.*);
        }
    }
    const outs = try outs_list.toOwnedSlice();
    std.mem.sort(WireName, outs, {}, compareStrings);
    return .{
        .wire_values = wire_values,
        .gates_map = gates_map,
        .outs = outs,
    };
}

test parseWiresFile {
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** (16 * 1024);

    std.debug.print("day24/parseWiresFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    var parse_result = try parseWiresFile(allocator, "data/day24/test.txt");
    defer parse_result.wire_values.deinit();
    defer parse_result.gates_map.deinit();
    defer allocator.free(parse_result.outs);
    try std.testing.expectEqualStrings(
        \\y02 = 1
        \\y04 = 1
        \\x01 = 0
        \\x00 = 1
        \\x04 = 0
        \\y01 = 1
        \\x02 = 1
        \\y00 = 1
        \\y03 = 1
        \\x03 = 1
    , parse_result.wire_values.bufPrint(&print_buf));
    try std.testing.expectEqualStrings(
        \\bfw OR bqk -> z06
        \\bfw XOR mjb -> z00
        \\hwm AND bqk -> z03
        \\tnw OR fst -> frj
        \\ntg OR kjc -> kwq
        \\nrd XOR fgs -> wpb
        \\y03 OR x01 -> nrd
        \\y01 AND x02 -> pbm
        \\y02 OR x01 -> tnw
        \\x03 OR x00 -> vdt
        \\kwq OR kpj -> z05
        \\y00 AND y03 -> djm
        \\frj XOR qhw -> z04
        \\tnw OR pbm -> gnj
        \\gnj AND tgd -> z11
        \\x00 OR x03 -> fst
        \\ffh OR nrd -> bqk
        \\bqk OR frj -> z08
        \\psh XOR fgs -> tgd
        \\tgd XOR rvg -> z01
        \\x00 XOR y04 -> ntg
        \\bfw AND frj -> z10
        \\nrd AND vdt -> hwm
        \\qhw XOR tgd -> z09
        \\vdt OR tnw -> bfw
        \\djm OR pbm -> qhw
        \\x03 XOR y03 -> ffh
        \\ntg XOR fgs -> mjb
        \\y03 OR y00 -> psh
        \\y04 OR y02 -> fgs
        \\bqk OR frj -> z07
        \\gnj AND wpb -> z02
        \\x04 AND y00 -> kjc
        \\kjc AND fst -> rvg
        \\pbm OR djm -> kpj
        \\tgd XOR rvg -> z12
    , parse_result.gates_map.bufPrint(&print_buf));
    try std.testing.expectEqualDeep(&[_]WireName{
        "z00",
        "z01",
        "z02",
        "z03",
        "z04",
        "z05",
        "z06",
        "z07",
        "z08",
        "z09",
        "z10",
        "z11",
        "z12",
    }, parse_result.outs);
}

fn wireValue(wire_name: WireName, gates_map: GatesMap, wire_values: *WireValues) !u1 {
    if (wire_values.map.get(wire_name)) |val| {
        return val;
    }
    const gate = gates_map.map.get(wire_name).?;
    const lhs_val = try wireValue(gate.lhs, gates_map, wire_values);
    const rhs_val = try wireValue(gate.rhs, gates_map, wire_values);
    return switch (gate.type) {
        .AND => lhs_val & rhs_val,
        .OR => lhs_val | rhs_val,
        .XOR => lhs_val ^ rhs_val,
    };
}

test wireValue {
    const allocator = std.testing.allocator;

    std.debug.print("day24/wireValue\n", .{});
    std.debug.print("\tread input file\n", .{});
    var parse_result = try parseWiresFile(allocator, "data/day24/test.txt");
    defer parse_result.wire_values.deinit();
    defer parse_result.gates_map.deinit();
    defer allocator.free(parse_result.outs);

    std.debug.print("\ty00=1 AND y03=1 -> djm=1\n", .{});
    try std.testing.expectEqual(1, try wireValue("djm", parse_result.gates_map, &parse_result.wire_values));
    std.debug.print("\t(y00=1 AND y03=1 -> djm=1) OR (y01=1 AND x02=1 -> pbm=1) -> qhw=1\n", .{});
    try std.testing.expectEqual(1, try wireValue("qhw", parse_result.gates_map, &parse_result.wire_values));
}

pub fn outputValue(outs: []const WireName, gates_map: GatesMap, wire_values: *WireValues) !usize {
    var result: usize = 0;
    var shift: u6 = 0;
    for (outs) |out| {
        const out_value: usize = @intCast(try wireValue(out, gates_map, wire_values));
        // std.debug.print("[{d}] {s} = {d}\n", .{ shift, out, out_value });
        result += out_value << shift;
        shift += 1;
    }
    return result;
}

test outputValue {
    const allocator = std.testing.allocator;

    std.debug.print("day24/outputValue\n", .{});
    std.debug.print("\tread input file\n", .{});
    var parse_result = try parseWiresFile(allocator, "data/day24/test.txt");
    defer parse_result.wire_values.deinit();
    defer parse_result.gates_map.deinit();
    defer allocator.free(parse_result.outs);

    std.debug.print("\tout = 2024\n", .{});
    try std.testing.expectEqual(2024, try outputValue(parse_result.outs, parse_result.gates_map, &parse_result.wire_values));
}

fn testOutput(allocator: std.mem.Allocator, x: usize, y: usize, outs: []const WireName, gates_map: GatesMap) !usize {
    var wire_values = WireValues.init(allocator);
    defer wire_values.deinit();
    for (0..45) |i| {
        const shift: u6 = @intCast(i);
        const xbit: u1 = @intCast((x >> shift) & 1);
        const ybit: u1 = @intCast((y >> shift) & 1);
        try wire_values.map.put(
            try std.fmt.allocPrint(allocator, "x{d:0>2}", .{i}),
            xbit,
        );
        try wire_values.map.put(
            try std.fmt.allocPrint(allocator, "y{d:0>2}", .{i}),
            ybit,
        );
    }
    return outputValue(outs, gates_map, &wire_values);
}

const WiresPair = [2]WireName;

fn swapWires(gates_map: GatesMap, wire_pairs: []const WiresPair) !GatesMap {
    var new_gates_map = try gates_map.clone();
    for (wire_pairs) |pair| {
        const g0 = gates_map.map.get(pair[0]).?;
        const g1 = gates_map.map.get(pair[1]).?;
        try new_gates_map.map.put(pair[0], g1);
        try new_gates_map.map.put(pair[1], g0);
    }
    return new_gates_map;
}

const spaces = "       |" ** 100;

fn printGate(gates_map: GatesMap, out: WireName, gate_type: GateType, lhs: WireName, rhs: WireName, depth: usize, buf: []u8) []u8 {
    var buf_lhs = [1]u8{0} ** (256 * 1024);
    var buf_rhs = [1]u8{0} ** (256 * 1024);
    return std.fmt.bufPrint(buf, "{s} <- {s}\n{s}({s})\n{s}({s})", .{
        out,
        @tagName(gate_type),
        spaces[0 .. (depth + 1) * 8 - 1],
        trace(gates_map, lhs, depth + 1, &buf_lhs),
        spaces[0 .. (depth + 1) * 8 - 1],
        trace(gates_map, rhs, depth + 1, &buf_rhs),
    }) catch unreachable;
}

fn trace(gates_map: GatesMap, wire: WireName, depth: usize, buf: []u8) []u8 {
    if (depth > 10) {
        return buf[0..0];
    }
    if (gates_map.map.get(wire)) |gate| {
        if (gate.type == .XOR) {
            if (gates_map.map.get(gate.rhs)) |rhs_gate| {
                if (rhs_gate.type == .XOR) {
                    return printGate(gates_map, wire, gate.type, gate.rhs, gate.lhs, depth, buf);
                }
            } else {
                if (gate.rhs[0] == 'x') {
                    return printGate(gates_map, wire, gate.type, gate.rhs, gate.lhs, depth, buf);
                }
            }
        }
        if (gate.type == .OR) {
            if (gates_map.map.get(gate.lhs)) |lhs_gate| {
                if (lhs_gate.type == .AND and
                    gates_map.map.get(lhs_gate.rhs) == null)
                {
                    return printGate(gates_map, wire, gate.type, gate.rhs, gate.lhs, depth, buf);
                }
            }
        }
        if (gate.type == .AND) {
            if (gates_map.map.get(gate.rhs)) |rhs_gate| {
                if (gates_map.map.get(rhs_gate.rhs) == null) {
                    return printGate(gates_map, wire, gate.type, gate.rhs, gate.lhs, depth, buf);
                }
            }
        }
        if (gate.rhs[0] == 'x') {
            return printGate(gates_map, wire, gate.type, gate.rhs, gate.lhs, depth, buf);
        }
        return printGate(gates_map, wire, gate.type, gate.lhs, gate.rhs, depth, buf);
    } else {
        return std.fmt.bufPrint(buf, "{s}", .{wire}) catch unreachable;
    }
}

fn plusGate(result: *GatesMap, bit: usize) !void {
    var out_key_buf = [1]u8{0} ** 4;
    var lhs_key_buf = [1]u8{0} ** 4;
    var rhs_key_buf = [1]u8{0} ** 4;
    const out_key = if (bit == 0)
        std.fmt.bufPrint(&out_key_buf, "z{d:0>2}", .{bit}) catch unreachable
    else
        std.fmt.bufPrint(&out_key_buf, "p{d:0>2}", .{bit}) catch unreachable;
    const lhs_key = std.fmt.bufPrint(&lhs_key_buf, "x{d:0>2}", .{bit}) catch unreachable;
    const rhs_key = std.fmt.bufPrint(&rhs_key_buf, "y{d:0>2}", .{bit}) catch unreachable;
    return result.put(Gate{ .type = .XOR, .lhs = lhs_key, .rhs = rhs_key, .out = out_key });
}

fn directCarryGate(result: *GatesMap, bit: usize) !void {
    var out_key_buf = [1]u8{0} ** 4;
    var lhs_key_buf = [1]u8{0} ** 4;
    var rhs_key_buf = [1]u8{0} ** 4;
    const out_key = if (bit == 1)
        std.fmt.bufPrint(&out_key_buf, "c{d:0>2}", .{bit}) catch unreachable
    else
        std.fmt.bufPrint(&out_key_buf, "d{d:0>2}", .{bit}) catch unreachable;
    const lhs_key = std.fmt.bufPrint(&lhs_key_buf, "x{d:0>2}", .{bit - 1}) catch unreachable;
    const rhs_key = std.fmt.bufPrint(&rhs_key_buf, "y{d:0>2}", .{bit - 1}) catch unreachable;
    try result.put(Gate{ .type = .AND, .lhs = lhs_key, .rhs = rhs_key, .out = out_key });
}

fn carryGate(result: *GatesMap, bit: usize) !void {
    if (bit == 1) {
        try directCarryGate(result, bit);
    } else {
        var out_key_buf = [1]u8{0} ** 4;
        var lhs_key_buf = [1]u8{0} ** 4;
        var rhs_key_buf = [1]u8{0} ** 4;
        try plusGate(result, bit - 1);
        try carryGate(result, bit - 1);
        try directCarryGate(result, bit);
        var out_key = std.fmt.bufPrint(&out_key_buf, "v{d:0>2}", .{bit}) catch unreachable;
        var lhs_key = std.fmt.bufPrint(&lhs_key_buf, "p{d:0>2}", .{bit - 1}) catch unreachable;
        var rhs_key = std.fmt.bufPrint(&rhs_key_buf, "c{d:0>2}", .{bit - 1}) catch unreachable;
        try result.put(Gate{ .type = .AND, .lhs = lhs_key, .rhs = rhs_key, .out = out_key });
        out_key = std.fmt.bufPrint(&out_key_buf, "c{d:0>2}", .{bit}) catch unreachable;
        lhs_key = std.fmt.bufPrint(&lhs_key_buf, "v{d:0>2}", .{bit}) catch unreachable;
        rhs_key = std.fmt.bufPrint(&rhs_key_buf, "d{d:0>2}", .{bit}) catch unreachable;
        try result.put(Gate{ .type = .OR, .lhs = lhs_key, .rhs = rhs_key, .out = out_key });
    }
}

fn resultGate(result: *GatesMap, bit: usize) !void {
    var out_key_buf = [1]u8{0} ** 4;
    var lhs_key_buf = [1]u8{0} ** 4;
    var rhs_key_buf = [1]u8{0} ** 4;
    const out_key = std.fmt.bufPrint(&out_key_buf, "z{d:0>2}", .{bit}) catch unreachable;
    const lhs_key = std.fmt.bufPrint(&lhs_key_buf, "p{d:0>2}", .{bit}) catch unreachable;
    const rhs_key = std.fmt.bufPrint(&rhs_key_buf, "c{d:0>2}", .{bit}) catch unreachable;
    try result.put(Gate{ .type = .XOR, .lhs = lhs_key, .rhs = rhs_key, .out = out_key });
}

fn expectedAdditionBitMap(allocator: std.mem.Allocator, bit: usize) !GatesMap {
    var result = GatesMap.init(allocator);
    if (bit == 0) {
        try plusGate(&result, bit);
    } else {
        try plusGate(&result, bit);
        try carryGate(&result, bit);
        try resultGate(&result, bit);
    }
    return result;
}

fn expectedAdditionMap(allocator: std.mem.Allocator, size: usize) !GatesMap {
    var result = GatesMap.init(allocator);
    for (0..size - 1) |bit| {
        if (bit == 0) {
            try plusGate(&result, bit);
        } else {
            try plusGate(&result, bit);
            try carryGate(&result, bit);
            try resultGate(&result, bit);
        }
    }
    try carryGate(&result, size - 1);
    return result;
}

test {
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** (256 * 1024);

    std.debug.print("day24/playground\n", .{});
    var parse_result = try parseWiresFile(allocator, "data/day24/input.txt");
    defer parse_result.wire_values.deinit();
    defer parse_result.gates_map.deinit();
    defer allocator.free(parse_result.outs);

    // for ([_]struct { x: usize, y: usize }{
    //     .{ .x = 0, .y = 0 },
    //     .{ .x = 1, .y = 0 },
    //     .{ .x = 2, .y = 0 },
    //     .{ .x = 3, .y = 0 },
    // }) |inputs| {
    //     std.debug.print("{d} + {d} = {d}\n", .{
    //         inputs.x,
    //         inputs.y,
    //         try testOutput(allocator, inputs.x, inputs.y, parse_result.outs, parse_result.gates_map),
    //     });
    // }
    //
    // for (0..45) |i| {
    //     const shift: u6 = @intCast(i);
    //     const expected: usize = bit << shift;
    //     const output = try testOutput(allocator, expected, 0, parse_result.outs, parse_result.gates_map);
    //     if (output != expected) {
    //         std.debug.print("1<<{d} + 0 = expected {d}, actual {d}\n", .{
    //             shift,
    //             expected,
    //             output,
    //         });
    //     }
    // }
    // for (0..45) |i| {
    //     const shift: u6 = @intCast(i);
    //     const expected: usize = bit << shift;
    //     const output = try testOutput(allocator, 0, expected, parse_result.outs, parse_result.gates_map);
    //     if (output != expected) {
    //         std.debug.print("0 + 1<<{d} = expected {d}, actual {d}\n", .{
    //             shift,
    //             expected,
    //             output,
    //         });
    //     }
    // }
    std.debug.print("trace real\n{s}\n", .{trace(parse_result.gates_map, "z00", 0, &print_buf)});
    var expected_z00_gates_map = try expectedAdditionBitMap(allocator, 0);
    defer expected_z00_gates_map.deinit();
    std.debug.print("trace expected\n{s}\n", .{trace(expected_z00_gates_map, "z00", 0, &print_buf)});

    std.debug.print("trace real\n{s}\n", .{trace(parse_result.gates_map, "z01", 0, &print_buf)});
    var expected_z01_gates_map = try expectedAdditionBitMap(allocator, 1);
    defer expected_z01_gates_map.deinit();
    std.debug.print("trace expected\n{s}\n", .{trace(expected_z01_gates_map, "z01", 0, &print_buf)});

    std.debug.print("trace real\n{s}\n", .{trace(parse_result.gates_map, "z02", 0, &print_buf)});
    var expected_z02_gates_map = try expectedAdditionBitMap(allocator, 2);
    defer expected_z02_gates_map.deinit();
    std.debug.print("trace expected\n{s}\n", .{trace(expected_z02_gates_map, "z02", 0, &print_buf)});

    std.debug.print("trace real\n{s}\n", .{trace(parse_result.gates_map, "z03", 0, &print_buf)});
    var expected_z03_gates_map = try expectedAdditionBitMap(allocator, 3);
    defer expected_z03_gates_map.deinit();
    std.debug.print("trace expected\n{s}\n", .{trace(expected_z03_gates_map, "z03", 0, &print_buf)});

    std.debug.print("trace real\n{s}\n", .{trace(parse_result.gates_map, "z38", 0, &print_buf)});
    var expected_z38_gates_map = try expectedAdditionBitMap(allocator, 38);
    defer expected_z38_gates_map.deinit();
    std.debug.print("trace expected\n{s}\n", .{trace(expected_z38_gates_map, "z38", 0, &print_buf)});

    std.debug.print("trace real\n{s}\n", .{trace(parse_result.gates_map, "z39", 0, &print_buf)});
    var expected_z39_gates_map = try expectedAdditionBitMap(allocator, 39);
    defer expected_z39_gates_map.deinit();
    std.debug.print("trace expected\n{s}\n", .{trace(expected_z39_gates_map, "z39", 0, &print_buf)});

    var expected_full_gates_map = try expectedAdditionMap(allocator, 46);
    defer expected_full_gates_map.deinit();
    std.debug.print("46 = {d}\n", .{expected_full_gates_map.map.count()});

    var corrected_gates_map = try swapWires(
        parse_result.gates_map,
        &[_]WiresPair{
            .{ "z11", "rpv" },
            .{ "rpb", "ctg" },
            .{ "z31", "dmh" },
            .{ "z38", "dvq" },
        },
    );
    defer corrected_gates_map.map.deinit();
    const bit: usize = 1;
    for (0..45) |i| {
        const shift: u6 = @intCast(i);
        const expected: usize = bit << shift;
        const output = try testOutput(allocator, expected, 0, parse_result.outs, corrected_gates_map);
        if (output != expected) {
            std.debug.print("1<<{d} + 0 = expected {d}, actual {d}\n", .{
                shift,
                expected,
                output,
            });
        }
    }
}

// ctg,dmh,dvq,rpb,rpv,z11,z31,z38
