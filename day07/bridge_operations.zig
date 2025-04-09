const std = @import("std");

const BridgeOperation = struct {
    test_value: usize,
    operands: []const usize,
};

pub fn parseBridgeOperationsFile(allocator: std.mem.Allocator, file_name: []const u8) ![]BridgeOperation {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var operations_list = std.ArrayList(BridgeOperation).init(allocator);
    defer operations_list.deinit();
    var operands_list = std.ArrayList(usize).init(allocator);
    defer operands_list.deinit();

    var lineBuf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |readLineBuf| {
        var it = std.mem.splitScalar(u8, readLineBuf, ' ');

        const test_value_token = it.next().?;
        const test_value = try std.fmt.parseInt(usize, test_value_token[0 .. test_value_token.len - 1], 10);

        while (it.next()) |operand_token| {
            const operand = try std.fmt.parseInt(usize, operand_token, 10);
            try operands_list.append(operand);
        }
        try operations_list.append(.{
            .test_value = test_value,
            .operands = try operands_list.toOwnedSlice(),
        });
    }

    return operations_list.toOwnedSlice();
}

test parseBridgeOperationsFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day07/parseBridgeOperationsFile\n", .{});
    std.debug.print("\tread input file\n", .{});

    const operations = try parseBridgeOperationsFile(allocator, "data/day07/test.txt");
    try std.testing.expectEqualDeep(&[_]BridgeOperation{
        .{ .test_value = 190, .operands = &[_]usize{ 10, 19 } },
        .{ .test_value = 3267, .operands = &[_]usize{ 81, 40, 27 } },
        .{ .test_value = 83, .operands = &[_]usize{ 17, 5 } },
        .{ .test_value = 156, .operands = &[_]usize{ 15, 6 } },
        .{ .test_value = 7290, .operands = &[_]usize{ 6, 8, 6, 15 } },
        .{ .test_value = 161011, .operands = &[_]usize{ 16, 10, 13 } },
        .{ .test_value = 192, .operands = &[_]usize{ 17, 8, 14 } },
        .{ .test_value = 21037, .operands = &[_]usize{ 9, 7, 18, 13 } },
        .{ .test_value = 292, .operands = &[_]usize{ 11, 6, 16, 20 } },
    }, operations);
}

const Operator = enum { Add, Multiply, Concatenate };

fn concatenateOperands(a: usize, b: usize) !usize {
    var concatenateBuf = [1]u8{0} ** 1024;
    const concatenateStr = try std.fmt.bufPrint(&concatenateBuf, "{d}{d}", .{ a, b });
    return try std.fmt.parseInt(usize, concatenateStr, 10);
}

fn unconcatenateOperand(test_value: usize, operand: usize) !?usize {
    var test_value_buf = [1]u8{0} ** 1024;
    var last_operand_buf = [1]u8{0} ** 1024;

    const test_value_str = try std.fmt.bufPrint(&test_value_buf, "{d}", .{test_value});
    const last_operand_str = try std.fmt.bufPrint(&last_operand_buf, "{d}", .{operand});

    if (test_value_str.len > last_operand_str.len and std.mem.endsWith(u8, test_value_str, last_operand_str)) {
        return try std.fmt.parseInt(usize, test_value_str[0 .. test_value_str.len - last_operand_str.len], 10);
    }
    return null;
}

fn findOperators(operation: BridgeOperation, result: []Operator) !bool {
    if (operation.operands.len == 2) {
        if (operation.test_value == operation.operands[0] + operation.operands[1]) {
            result[0] = .Add;
            return true;
        }
        if (operation.test_value == operation.operands[0] * operation.operands[1]) {
            result[0] = .Multiply;
            return true;
        }
        const concatenate_value = try concatenateOperands(operation.operands[0], operation.operands[1]);
        if (operation.test_value == concatenate_value) {
            result[0] = .Concatenate;
            return true;
        }
        return false;
    }
    const last_operand = operation.operands[operation.operands.len - 1];
    if ((std.math.rem(usize, operation.test_value, last_operand) catch 1) == 0) {
        const found = try findOperators(.{
            .test_value = operation.test_value / last_operand,
            .operands = operation.operands[0 .. operation.operands.len - 1],
        }, result);
        if (found) {
            result[operation.operands.len - 2] = .Multiply;
            return true;
        }
    }
    if (operation.test_value > last_operand) {
        const found = try findOperators(.{
            .test_value = operation.test_value - last_operand,
            .operands = operation.operands[0 .. operation.operands.len - 1],
        }, result);
        if (found) {
            result[operation.operands.len - 2] = .Add;
            return true;
        }
    }
    const new_test_value = try unconcatenateOperand(operation.test_value, last_operand);
    if (new_test_value) |test_value| {
        const found = try findOperators(.{
            .test_value = test_value,
            .operands = operation.operands[0 .. operation.operands.len - 1],
        }, result);
        if (found) {
            result[operation.operands.len - 2] = .Concatenate;
            return true;
        }
    }
    return false;
}

fn findAllOperators(allocator: std.mem.Allocator, operation: BridgeOperation) !?[]const Operator {
    const result = try allocator.alloc(Operator, operation.operands.len - 1);
    const found = try findOperators(operation, result);
    if (!found) {
        allocator.free(result);
        return null;
    }
    return result;
}

test findAllOperators {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day07/findAllOperators\n", .{});

    std.debug.print("\t- 2 operands add\n", .{});
    var operators = try findAllOperators(allocator, .{ .test_value = 29, .operands = &[_]usize{ 10, 19 } });
    try std.testing.expectEqualDeep(&[_]Operator{.Add}, operators);

    std.debug.print("\t- 2 operands multiply\n", .{});
    operators = try findAllOperators(allocator, .{ .test_value = 190, .operands = &[_]usize{ 10, 19 } });
    try std.testing.expectEqualDeep(&[_]Operator{.Multiply}, operators);

    std.debug.print("\t- 2 operands concatenate\n", .{});
    operators = try findAllOperators(allocator, .{ .test_value = 1019, .operands = &[_]usize{ 10, 19 } });
    try std.testing.expectEqualDeep(&[_]Operator{.Concatenate}, operators);

    std.debug.print("\t- 2 operands invalid\n", .{});
    operators = try findAllOperators(allocator, .{ .test_value = 19, .operands = &[_]usize{ 10, 19 } });
    try std.testing.expectEqual(null, operators);

    std.debug.print("\t- 3 operands: add then multiply\n", .{});
    operators = try findAllOperators(allocator, .{ .test_value = 3267, .operands = &[_]usize{ 81, 40, 27 } });
    try std.testing.expectEqualDeep(&[_]Operator{ .Add, .Multiply }, operators);

    std.debug.print("\t- 3 operands: concatenate then add\n", .{});
    operators = try findAllOperators(allocator, .{ .test_value = 192, .operands = &[_]usize{ 17, 8, 14 } });
    try std.testing.expectEqualDeep(&[_]Operator{ .Concatenate, .Add }, operators);

    std.debug.print("\t- 4 operands: add then multiply then add\n", .{});
    operators = try findAllOperators(allocator, .{ .test_value = 292, .operands = &[_]usize{ 11, 6, 16, 20 } });
    try std.testing.expectEqualDeep(&[_]Operator{ .Add, .Multiply, .Add }, operators);

    std.debug.print("\t- 4 operands: multiply then concatenate then multiply\n", .{});
    operators = try findAllOperators(allocator, .{ .test_value = 7290, .operands = &[_]usize{ 6, 8, 6, 15 } });
    try std.testing.expectEqualDeep(&[_]Operator{ .Multiply, .Concatenate, .Multiply }, operators);
}

pub fn calibrationResult(allocator: std.mem.Allocator, operations: []const BridgeOperation) !usize {
    var result: usize = 0;
    for (operations) |operation| {
        const operators: ?[]const Operator = try findAllOperators(allocator, operation);
        if (operators) |_| {
            allocator.free(operators.?);
            result += operation.test_value;
        }
    }
    return result;
}

test calibrationResult {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day07/calibrationResult\n", .{});
    std.debug.print("\tthe sum of the test values from just the equations that could possibly be true.\n", .{});

    try std.testing.expectEqual(11387, try calibrationResult(allocator, &[_]BridgeOperation{
        .{ .test_value = 190, .operands = &[_]usize{ 10, 19 } },
        .{ .test_value = 3267, .operands = &[_]usize{ 81, 40, 27 } },
        .{ .test_value = 83, .operands = &[_]usize{ 17, 5 } },
        .{ .test_value = 156, .operands = &[_]usize{ 15, 6 } },
        .{ .test_value = 7290, .operands = &[_]usize{ 6, 8, 6, 15 } },
        .{ .test_value = 161011, .operands = &[_]usize{ 16, 10, 13 } },
        .{ .test_value = 192, .operands = &[_]usize{ 17, 8, 14 } },
        .{ .test_value = 21037, .operands = &[_]usize{ 9, 7, 18, 13 } },
        .{ .test_value = 292, .operands = &[_]usize{ 11, 6, 16, 20 } },
    }));
}
