const std = @import("std");

const ClawMachine = struct {
    button_a: struct { x: usize, y: usize },
    button_b: struct { x: usize, y: usize },
    prize: struct { x: usize, y: usize },
};

pub fn parseClawMachinesFile(allocator: std.mem.Allocator, file_name: []const u8) ![]ClawMachine {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var machines_list = std.ArrayList(ClawMachine).init(allocator);
    defer machines_list.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |button_a_line| {
        if (button_a_line.len == 0) continue;

        var it = std.mem.splitScalar(u8, button_a_line, ',');
        var token = it.next() orelse unreachable;
        const button_a_x = try std.fmt.parseInt(usize, token[12..], 10);
        token = it.next() orelse unreachable;
        const button_a_y = try std.fmt.parseInt(usize, token[3..], 10);

        const button_b_line = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n') orelse unreachable;
        it = std.mem.splitScalar(u8, button_b_line, ',');
        token = it.next() orelse unreachable;
        const button_b_x = try std.fmt.parseInt(usize, token[12..], 10);
        token = it.next() orelse unreachable;
        const button_b_y = try std.fmt.parseInt(usize, token[3..], 10);

        const prize_line = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n') orelse unreachable;
        it = std.mem.splitScalar(u8, prize_line, ',');
        token = it.next() orelse unreachable;
        const prize_x = try std.fmt.parseInt(usize, token[9..], 10);
        token = it.next() orelse unreachable;
        const prize_y = try std.fmt.parseInt(usize, token[3..], 10);

        try machines_list.append(.{
            .button_a = .{ .x = button_a_x, .y = button_a_y },
            .button_b = .{ .x = button_b_x, .y = button_b_y },
            .prize = .{ .x = prize_x, .y = prize_y },
        });
    }

    return try machines_list.toOwnedSlice();
}

test parseClawMachinesFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day13/parseClawMachinesFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    const claw_machines = try parseClawMachinesFile(allocator, "data/day13/test.txt");
    std.debug.print("\tread claw machines\n", .{});
    try std.testing.expectEqualDeep(&[_]ClawMachine{
        .{
            .button_a = .{ .x = 94, .y = 34 },
            .button_b = .{ .x = 22, .y = 67 },
            .prize = .{ .x = 8400, .y = 5400 },
        },
        .{
            .button_a = .{ .x = 26, .y = 66 },
            .button_b = .{ .x = 67, .y = 21 },
            .prize = .{ .x = 12748, .y = 12176 },
        },
        .{
            .button_a = .{ .x = 17, .y = 86 },
            .button_b = .{ .x = 84, .y = 37 },
            .prize = .{ .x = 7870, .y = 6450 },
        },
        .{
            .button_a = .{ .x = 69, .y = 23 },
            .button_b = .{ .x = 27, .y = 71 },
            .prize = .{ .x = 18641, .y = 10279 },
        },
    }, claw_machines);
}

const OptimalPrize = struct {
    button_a: usize,
    button_b: usize,
    price: usize,
};

fn findOptimalPrize(claw_machine: ClawMachine) ?OptimalPrize {
    for (1..@min(claw_machine.prize.x / claw_machine.button_a.x + 1, 101)) |a| {
        const remaining = claw_machine.prize.x - a * claw_machine.button_a.x;
        const b = remaining / claw_machine.button_b.x;
        if (b > 100) continue;
        const rem_x = remaining - b * claw_machine.button_b.x;
        if (rem_x != 0) continue;
        if (a * claw_machine.button_a.y + b * claw_machine.button_b.y != claw_machine.prize.y) continue;
        const rem_y = claw_machine.prize.y - a * claw_machine.button_a.y - b * claw_machine.button_b.y;
        std.debug.print("a: {d} b: {d} remX: {d} remY: {d}\n", .{ a, b, rem_x, rem_y });
        return .{
            .button_a = a,
            .button_b = b,
            .price = 3 * a + b,
        };
    }
    return null;
}

test findOptimalPrize {
    std.debug.print("day13/findOptimalPrize\n", .{});
    std.debug.print("\tfirst machine\n", .{});
    try std.testing.expectEqualDeep(OptimalPrize{
        .button_a = 80,
        .button_b = 40,
        .price = 280,
    }, findOptimalPrize(.{
        .button_a = .{ .x = 94, .y = 34 },
        .button_b = .{ .x = 22, .y = 67 },
        .prize = .{ .x = 8400, .y = 5400 },
    }));
    try std.testing.expectEqualDeep(null, findOptimalPrize(.{
        .button_a = .{ .x = 26, .y = 66 },
        .button_b = .{ .x = 67, .y = 21 },
        .prize = .{ .x = 12748, .y = 12176 },
    }));
    try std.testing.expectEqualDeep(OptimalPrize{
        .button_a = 38,
        .button_b = 86,
        .price = 200,
    }, findOptimalPrize(.{
        .button_a = .{ .x = 17, .y = 86 },
        .button_b = .{ .x = 84, .y = 37 },
        .prize = .{ .x = 7870, .y = 6450 },
    }));
    try std.testing.expectEqualDeep(null, findOptimalPrize(.{
        .button_a = .{ .x = 69, .y = 23 },
        .button_b = .{ .x = 27, .y = 71 },
        .prize = .{ .x = 18641, .y = 10279 },
    }));
}

pub fn totalPrice(claw_machines: []ClawMachine) usize {
    var total_price: usize = 0;
    for (claw_machines, 0..) |claw_machine, index| {
        std.debug.print("machine: {d}\n", .{index});
        if (findOptimalPrize(claw_machine)) |optimal_prize| {
            total_price += optimal_prize.price;
        }
    }
    return total_price;
}

test totalPrice {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day13/totalPrice\n", .{});
    std.debug.print("\tread input file\n", .{});
    const claw_machines = try parseClawMachinesFile(allocator, "data/day13/test.txt");
    std.debug.print("\ttotal price\n", .{});
    try std.testing.expectEqual(480, totalPrice(claw_machines));
}

const ButtonPair = struct { a: usize, b: usize };

const Equation = struct {
    a_offset: isize,
    a_factor: isize,
    b_offset: isize,
    b_factor: isize,
    pub fn init(first_pair: ButtonPair, second_pair: ButtonPair) Equation {
        const b_factor: isize = @intCast(first_pair.b - second_pair.b);
        return Equation{
            .a_offset = @intCast(first_pair.a),
            .a_factor = @intCast(second_pair.a - first_pair.a),
            .b_offset = @intCast(first_pair.b),
            .b_factor = -b_factor,
        };
    }
};

fn findXEquation(claw_machine: ClawMachine) ?Equation {
    const true_prize_x = 10000000000000 + claw_machine.prize.x;
    const max_a_x = claw_machine.button_b.x * 2;

    const first_x_pair: ButtonPair = for (0..max_a_x + 1) |a| {
        const rem = (true_prize_x - a * claw_machine.button_a.x) % claw_machine.button_b.x;
        if (rem != 0) continue;
        const b = (true_prize_x - a * claw_machine.button_a.x) / claw_machine.button_b.x;
        std.debug.print("a: {d} b: {d}\n", .{ a, b });
        break .{ .a = a, .b = b };
    } else return null;
    std.debug.print("first_x_pair: {any}\n", .{first_x_pair});

    const second_x_pair: ButtonPair = for (@intCast(first_x_pair.a + 1)..max_a_x + 1) |a| {
        const rem = (true_prize_x - a * claw_machine.button_a.x) % claw_machine.button_b.x;
        if (rem != 0) continue;
        const b = (true_prize_x - a * claw_machine.button_a.x) / claw_machine.button_b.x;
        std.debug.print("a: {d} b: {d}\n", .{ a, b });
        break .{ .a = a, .b = b };
    } else return null;
    std.debug.print("second_x_pair: {any}\n", .{second_x_pair});

    return Equation.init(first_x_pair, second_x_pair);
}

fn findYEquation(claw_machine: ClawMachine) ?Equation {
    const true_prize_y = 10000000000000 + claw_machine.prize.y;

    const max_a_y = claw_machine.button_b.y * 2;
    const first_y_pair: ButtonPair = for (0..max_a_y + 1) |a| {
        const rem = (true_prize_y - a * claw_machine.button_a.y) % claw_machine.button_b.y;
        // std.debug.print("a: {d} rem: {d}\n", .{ a, rem });
        if (rem != 0) continue;
        const b = (true_prize_y - a * claw_machine.button_a.y) / claw_machine.button_b.y;
        std.debug.print("a: {d} b: {d}\n", .{ a, b });
        break .{ .a = a, .b = b };
    } else return null;
    std.debug.print("first_y_pair: {any}\n", .{first_y_pair});

    const second_y_pair: ButtonPair = for (@intCast(first_y_pair.a + 1)..max_a_y + 1) |a| {
        const rem = (true_prize_y - a * claw_machine.button_a.y) % claw_machine.button_b.y;
        if (rem != 0) continue;
        const b = (true_prize_y - a * claw_machine.button_a.y) / claw_machine.button_b.y;
        std.debug.print("a: {d} b: {d}\n", .{ a, b });
        break .{ .a = a, .b = b };
    } else return null;

    std.debug.print("second_y_pair: {any}\n", .{second_y_pair});
    return Equation.init(first_y_pair, second_y_pair);
}

fn gaussPivot(x_equation: Equation, y_equation: Equation) ?ButtonPair {
    std.debug.print("\na-x equation: {d} + {d} * i = {d} + {d} * j\n", .{ x_equation.a_offset, x_equation.a_factor, y_equation.a_offset, y_equation.a_factor });
    std.debug.print("b-x equation: {d} + {d} * i = {d} + {d} * j\n", .{ x_equation.b_offset, x_equation.b_factor, y_equation.b_offset, y_equation.b_factor });

    std.debug.print("\na-x equation: {d} + {d} * i = {d} + {d} * j\n", .{
        x_equation.a_offset * (-x_equation.b_factor),
        x_equation.a_factor * (-x_equation.b_factor),
        y_equation.a_offset * (-x_equation.b_factor),
        y_equation.a_factor * (-x_equation.b_factor),
    });
    std.debug.print("b-x equation: {d} + {d} * i = {d} + {d} * j\n", .{
        x_equation.b_offset * x_equation.a_factor,
        x_equation.b_factor * x_equation.a_factor,
        y_equation.b_offset * x_equation.a_factor,
        y_equation.b_factor * x_equation.a_factor,
    });

    std.debug.print("\nequation: {d} + {d} * i = {d} + {d} * j\n", .{
        x_equation.a_offset * (-x_equation.b_factor) + x_equation.b_offset * x_equation.a_factor,
        x_equation.a_factor * (-x_equation.b_factor) + x_equation.b_factor * x_equation.a_factor,
        y_equation.a_offset * (-x_equation.b_factor) + y_equation.b_offset * x_equation.a_factor,
        y_equation.a_factor * (-x_equation.b_factor) + y_equation.b_factor * x_equation.a_factor,
    });

    std.debug.print("\nequation: {d} = {d} * j\n", .{
        x_equation.a_offset * (-x_equation.b_factor) + x_equation.b_offset * x_equation.a_factor -
            (y_equation.a_offset * (-x_equation.b_factor) + y_equation.b_offset * x_equation.a_factor),
        y_equation.a_factor * (-x_equation.b_factor) + y_equation.b_factor * x_equation.a_factor,
    });

    std.debug.print("\nequation: ({d}){d} = j\n", .{ @rem(
        x_equation.a_offset * (-x_equation.b_factor) + x_equation.b_offset * x_equation.a_factor -
            (y_equation.a_offset * (-x_equation.b_factor) + y_equation.b_offset * x_equation.a_factor),
        y_equation.a_factor * (-x_equation.b_factor) + y_equation.b_factor * x_equation.a_factor,
    ), std.math.divExact(
        isize,
        x_equation.a_offset * (-x_equation.b_factor) + x_equation.b_offset * x_equation.a_factor -
            (y_equation.a_offset * (-x_equation.b_factor) + y_equation.b_offset * x_equation.a_factor),
        y_equation.a_factor * (-x_equation.b_factor) + y_equation.b_factor * x_equation.a_factor,
    ) catch return null });

    const j = std.math.divExact(
        isize,
        x_equation.a_offset * (-x_equation.b_factor) + x_equation.b_offset * x_equation.a_factor -
            (y_equation.a_offset * (-x_equation.b_factor) + y_equation.b_offset * x_equation.a_factor),
        y_equation.a_factor * (-x_equation.b_factor) + y_equation.b_factor * x_equation.a_factor,
    ) catch return null;

    const a: usize = @intCast(y_equation.a_offset + y_equation.a_factor * j);
    const b: usize = @intCast(y_equation.b_offset + y_equation.b_factor * j);

    return .{ .a = a, .b = b };
}

fn findTrueOptimalPrize(claw_machine: ClawMachine) ?OptimalPrize {
    const x_equation = findXEquation(claw_machine);
    if (x_equation == null) return null;
    std.debug.print("x_equation: {any}\n", .{x_equation});

    const y_equation = findYEquation(claw_machine);
    if (y_equation == null) return null;
    std.debug.print("y_equation: {any}\n", .{y_equation});

    const result = gaussPivot(x_equation.?, y_equation.?);
    if (result == null) return null;
    std.debug.print("a: {d} b: {d}\n", .{ result.?.a, result.?.b });

    return .{
        .button_a = result.?.a,
        .button_b = result.?.b,
        .price = 3 * result.?.a + result.?.b,
    };
}

pub fn trueTotalPrice(claw_machines: []ClawMachine) usize {
    var total_price: usize = 0;
    for (claw_machines, 0..) |claw_machine, index| {
        std.debug.print("============= machine: {d}\n", .{index});
        if (findTrueOptimalPrize(claw_machine)) |optimal_prize| {
            total_price += optimal_prize.price;
        }
    }
    return total_price;
}
