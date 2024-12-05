const std = @import("std");

const ProgramMemory = []const u8;

pub fn parseProgramMemoryFile(allocator: std.mem.Allocator, file_name: []const u8) !ProgramMemory {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();
    var lineBuf: [1024 * 1024]u8 = undefined;

    const nRead = try in_stream.read(&lineBuf);
    const memory = try allocator.alloc(u8, nRead);
    std.mem.copyForwards(u8, memory, lineBuf[0..nRead]);
    return memory;
}

test parseProgramMemoryFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day03/parseProgramMemoryFile\n", .{});
    std.debug.print("\treading test input\n", .{});
    const programMemory = try parseProgramMemoryFile(allocator, "data/day03/test.txt");
    try std.testing.expectEqualStrings(
        "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))\n",
        programMemory,
    );
}

const Operand = enum {
    MUL,
    DO,
    DONT,
};

const Instruction = struct {
    operand: Operand,
    args: ?struct {
        lhs: isize,
        rhs: isize,
    },
    pub fn format(
        self: Instruction,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        switch (self.operand) {
            .MUL => try writer.print("mul({},{})", .{ self.args.?.lhs, self.args.?.rhs }),
            .DO => try writer.print("do()", .{}),
            .DONT => try writer.print("dont()", .{}),
        }
    }
};

fn parseToken(programMemory: ProgramMemory, token: []const u8) struct { token: ?[]const u8, programMemory: ProgramMemory } {
    if (std.mem.eql(u8, token, programMemory[0..token.len])) {
        return .{
            .token = token,
            .programMemory = programMemory[token.len..],
        };
    }
    return .{
        .token = null,
        .programMemory = programMemory,
    };
}

const ParseIntegerResult = struct { integer: ?isize, programMemory: ProgramMemory };
fn parseInt(programMemory: ProgramMemory, maxDigits: usize) ParseIntegerResult {
    const integerStrLen = for (programMemory, 0..) |c, i| {
        if (c < '0' or c > '9') {
            break i;
        }
        if (i == maxDigits) break maxDigits;
    } else programMemory.len;
    if (integerStrLen == 0) {
        return .{
            .integer = null,
            .programMemory = programMemory,
        };
    }
    return .{
        .integer = std.fmt.parseInt(isize, programMemory[0..integerStrLen], 10) catch null,
        .programMemory = programMemory[integerStrLen..],
    };
}

const ParseInstructionResult = struct { instruction: ?Instruction, programMemory: ProgramMemory };
fn parseNextInstruction(programMemory: ProgramMemory) ParseInstructionResult {
    var pc = programMemory;
    while (pc.len > 0) {
        const c = pc[0];
        pc = pc[1..];
        if (c == 'm') {
            var parseTokenResult = parseToken(pc, "ul(");
            if (parseTokenResult.token == null) continue;
            pc = parseTokenResult.programMemory;

            var parseIntegerResult = parseInt(pc, 3);
            if (parseIntegerResult.integer == null) continue;
            pc = parseIntegerResult.programMemory;
            const lhs = parseIntegerResult.integer.?;

            parseTokenResult = parseToken(pc, ",");
            if (parseTokenResult.token == null) continue;
            pc = parseTokenResult.programMemory;

            parseIntegerResult = parseInt(pc, 3);
            if (parseIntegerResult.integer == null) continue;
            pc = parseIntegerResult.programMemory;
            const rhs = parseIntegerResult.integer.?;

            parseTokenResult = parseToken(pc, ")");
            if (parseTokenResult.token == null) continue;
            pc = parseTokenResult.programMemory;

            return .{
                .instruction = Instruction{
                    .operand = .MUL,
                    .args = .{ .lhs = lhs, .rhs = rhs },
                },
                .programMemory = pc,
            };
        } else if (c == 'd') {
            var parseTokenResult = parseToken(pc, "o()");
            if (parseTokenResult.token) |_| {
                return .{
                    .instruction = Instruction{
                        .operand = .DO,
                        .args = null,
                    },
                    .programMemory = parseTokenResult.programMemory,
                };
            }

            parseTokenResult = parseToken(pc, "on't()");
            if (parseTokenResult.token) |_| {
                return .{
                    .instruction = Instruction{
                        .operand = .DONT,
                        .args = null,
                    },
                    .programMemory = parseTokenResult.programMemory,
                };
            }
        }
    } else return .{
        .instruction = null,
        .programMemory = programMemory,
    };
}

test parseNextInstruction {
    std.debug.print("day03/parseNextInstruction\n", .{});
    const mulResult = parseNextInstruction("xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))");
    try std.testing.expectEqualDeep(ParseInstructionResult{
        .instruction = .{
            .operand = .MUL,
            .args = .{ .lhs = 2, .rhs = 4 },
        },
        .programMemory = "&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))",
    }, mulResult);

    const dontResult = parseNextInstruction("&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))");
    try std.testing.expectEqualDeep(ParseInstructionResult{
        .instruction = .{
            .operand = .DONT,
            .args = null,
        },
        .programMemory = "_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))",
    }, dontResult);

    const doResult = parseNextInstruction("undo()?mul(8,5))");
    try std.testing.expectEqualDeep(ParseInstructionResult{
        .instruction = .{
            .operand = .DO,
            .args = null,
        },
        .programMemory = "?mul(8,5))",
    }, doResult);
}

pub fn parseAllInstructions(allocator: std.mem.Allocator, programMemory: ProgramMemory) ![]Instruction {
    var instructionsList = std.ArrayList(Instruction).init(allocator);
    defer instructionsList.deinit();

    var nextInstructionResult = parseNextInstruction(programMemory);
    while (nextInstructionResult.instruction) |instruction| {
        try instructionsList.append(instruction);
        nextInstructionResult = parseNextInstruction(nextInstructionResult.programMemory);
    }
    return instructionsList.toOwnedSlice();
}

test parseAllInstructions {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day03/parseAllInstructions\n", .{});
    const programMemory = try parseProgramMemoryFile(allocator, "data/day03/test.txt");

    const instructions = try parseAllInstructions(allocator, programMemory);
    try std.testing.expectEqualDeep(&[_]Instruction{
        .{
            .operand = .MUL,
            .args = .{ .lhs = 2, .rhs = 4 },
        },
        .{
            .operand = .DONT,
            .args = null,
        },
        .{
            .operand = .MUL,
            .args = .{ .lhs = 5, .rhs = 5 },
        },
        .{
            .operand = .MUL,
            .args = .{ .lhs = 11, .rhs = 8 },
        },
        .{
            .operand = .DO,
            .args = null,
        },
        .{
            .operand = .MUL,
            .args = .{ .lhs = 8, .rhs = 5 },
        },
    }, instructions);
}

pub fn sumInstructions(instructions: []const Instruction) isize {
    var sum: isize = 0;
    var active = true;
    for (instructions) |instruction| {
        switch (instruction.operand) {
            .MUL => if (active) {
                sum += instruction.args.?.lhs * instruction.args.?.rhs;
            },
            .DO => active = true,
            .DONT => active = false,
        }
    }
    return sum;
}

test sumInstructions {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day03/sumInstructions\n", .{});
    const programMemory = try parseProgramMemoryFile(allocator, "data/day03/test.txt");

    const instructions = try parseAllInstructions(allocator, programMemory);
    const sum = sumInstructions(instructions);
    try std.testing.expectEqual(48, sum);
}
