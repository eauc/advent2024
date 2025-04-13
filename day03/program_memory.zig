//! # Day 3: Mull It Over
//! "Our computers are having issues, so I have no idea if we have any Chief Historians in stock! You're welcome to check the warehouse, though," says the mildly flustered shopkeeper at the North Pole Toboggan Rental Shop. The Historians head out to take a look.
//!
//! The shopkeeper turns to you. "Any chance you can see why our computers are having issues again?"
//!
//! The computer appears to be trying to run a program, but its memory (your puzzle input) is corrupted. All of the instructions have been jumbled up!
//!
//! It seems like the goal of the program is just to multiply some numbers. It does that with instructions like mul(X,Y), where X and Y are each 1-3 digit numbers. For instance, mul(44,46) multiplies 44 by 46 to get a result of 2024. Similarly, mul(123,4) would multiply 123 by 4.
//!
//! However, because the program's memory has been corrupted, there are also many invalid characters that should be ignored, even if they look like part of a mul instruction. Sequences like
//! ```
//! mul(4*, mul(6,9!, ?(12,34), or mul ( 2 , 4 )
//! ```
//! do nothing.
//!
//! For example, consider the following section of corrupted memory:
//!
//! ```
//! xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
//! ```
//! Only the four highlighted sections are real mul instructions. Adding up the result of each instruction produces
//! ```
//! 161 (2*4 + 5*5 + 11*8 + 8*5).
//! ```
//!
//! As you scan through the corrupted memory, you notice that some of the conditional statements are also still intact. If you handle some of the uncorrupted conditional statements in the program, you might be able to get an even more accurate result.
//!
//! There are two new instructions you'll need to handle:
//!
//! The do() instruction enables future mul instructions.
//! The don't() instruction disables future mul instructions.
//! Only the most recent do() or don't() instruction applies. At the beginning of the program, mul instructions are enabled.
//!
//! For example:
//!
//! ```
//! xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
//! ```
//! This corrupted memory is similar to the example from before, but this time the mul(5,5) and mul(11,8) instructions are disabled because there is a don't() instruction before them. The other mul instructions function normally, including the one at the end that gets re-enabled by a do() instruction.
//!
//! This time, the sum of the results is
//! ```
//! 48 (2*4 + 8*5).
//! ```

const std = @import("std");

const ProgramMemory = []const u8;

pub fn parseProgramMemoryFile(allocator: std.mem.Allocator, file_name: []const u8) !ProgramMemory {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();
    var lineBuf: [1024 * 1024]u8 = undefined;

    const nRead = try in_stream.read(&lineBuf);
    const memory = allocator.alloc(u8, nRead) catch unreachable;
    std.mem.copyForwards(u8, memory, lineBuf[0..nRead]);
    return memory;
}

test parseProgramMemoryFile {
    const allocator = std.testing.allocator;

    const programMemory = try parseProgramMemoryFile(allocator, "day03/test.txt");
    defer allocator.free(programMemory);

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

test "parseNextInstruction/mul" {
    const mulResult = parseNextInstruction("xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))");
    try std.testing.expectEqualDeep(ParseInstructionResult{
        .instruction = .{
            .operand = .MUL,
            .args = .{ .lhs = 2, .rhs = 4 },
        },
        .programMemory = "&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))",
    }, mulResult);
}

test "parseNextInstruction/dont" {
    const dontResult = parseNextInstruction("&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))");
    try std.testing.expectEqualDeep(ParseInstructionResult{
        .instruction = .{
            .operand = .DONT,
            .args = null,
        },
        .programMemory = "_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))",
    }, dontResult);
}

test "parseNextInstruction/do" {
    const doResult = parseNextInstruction("undo()?mul(8,5))");
    try std.testing.expectEqualDeep(ParseInstructionResult{
        .instruction = .{
            .operand = .DO,
            .args = null,
        },
        .programMemory = "?mul(8,5))",
    }, doResult);
}

/// Parses all valid instructions in programMemory
pub fn parseAllInstructions(allocator: std.mem.Allocator, programMemory: ProgramMemory) []Instruction {
    var instructionsList = std.ArrayList(Instruction).init(allocator);
    defer instructionsList.deinit();

    var nextInstructionResult = parseNextInstruction(programMemory);
    while (nextInstructionResult.instruction) |instruction| {
        instructionsList.append(instruction) catch unreachable;
        nextInstructionResult = parseNextInstruction(nextInstructionResult.programMemory);
    }
    return instructionsList.toOwnedSlice() catch unreachable;
}

test parseAllInstructions {
    const allocator = std.testing.allocator;

    const programMemory = try parseProgramMemoryFile(allocator, "day03/test.txt");
    defer allocator.free(programMemory);

    const instructions = parseAllInstructions(allocator, programMemory);
    defer allocator.free(instructions);

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

// Sums the result of all mul instructions
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
    const allocator = std.testing.allocator;

    const programMemory = try parseProgramMemoryFile(allocator, "day03/test.txt");
    defer allocator.free(programMemory);

    const instructions = parseAllInstructions(allocator, programMemory);
    defer allocator.free(instructions);

    const sum = sumInstructions(instructions);
    try std.testing.expectEqual(48, sum);
}
