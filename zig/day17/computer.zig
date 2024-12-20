const std = @import("std");

const Registers = struct {
    A: isize = 0,
    B: isize = 0,
    C: isize = 0,
};

const OpCode = enum(u3) {
    adv = 0,
    bxl,
    bst,
    jnz,
    bxc,
    out,
    bdv,
    cdv,
};

const Instruction = struct {
    opCode: OpCode,
    operand: u3,
    pub fn comboOperand(self: *const Instruction, registers: Registers) !isize {
        return switch (self.operand) {
            0...3 => self.operand,
            4 => registers.A,
            5 => registers.B,
            6 => registers.C,
            7 => error.ReservedOperand,
        };
    }
    pub fn bufPrint(self: *const Instruction, buf: []u8) []u8 {
        var op_buf = [1]u8{0} ** 1024;
        switch (self.opCode) {
            .adv => return std.fmt.bufPrint(buf, "avd[0]({d}): A <- A / 2^{s}", .{ self.operand, self.bufPrintComboOperand(&op_buf) }) catch unreachable,
            .bxl => return std.fmt.bufPrint(buf, "bxl[1]({d}): B <- B ^ {d}", .{ self.operand, self.operand }) catch unreachable,
            .bst => return std.fmt.bufPrint(buf, "bst[2]({d}): B <- {s} % 8", .{ self.operand, self.bufPrintComboOperand(&op_buf) }) catch unreachable,
            .jnz => return std.fmt.bufPrint(buf, "jnz[3]({d}): JMP(A != 0) {d}", .{ self.operand, self.operand }) catch unreachable,
            .bxc => return std.fmt.bufPrint(buf, "bxc[4]({d}): B <- B ^ C", .{self.operand}) catch unreachable,
            .out => return std.fmt.bufPrint(buf, "out[5]({d}): OUT {s} % 8", .{ self.operand, self.bufPrintComboOperand(&op_buf) }) catch unreachable,
            .bdv => return std.fmt.bufPrint(buf, "bdv[6]({d}): B <- A / 2^{s}", .{ self.operand, self.bufPrintComboOperand(&op_buf) }) catch unreachable,
            .cdv => return std.fmt.bufPrint(buf, "cdv[7]({d}): C <- A / 2^{s}", .{ self.operand, self.bufPrintComboOperand(&op_buf) }) catch unreachable,
        }
    }
    pub fn bufPrintComboOperand(self: *const Instruction, buf: []u8) []u8 {
        return switch (self.operand) {
            0...3 => std.fmt.bufPrint(buf, "{d}", .{self.operand}) catch unreachable,
            4 => std.fmt.bufPrint(buf, "A", .{}) catch unreachable,
            5 => std.fmt.bufPrint(buf, "B", .{}) catch unreachable,
            6 => std.fmt.bufPrint(buf, "C", .{}) catch unreachable,
            7 => buf[0..0],
        };
    }
};

pub const ProgramState = struct {
    allocator: std.mem.Allocator,
    ip: usize = 0,
    registers: Registers,
    instructionsString: []const u8,
    instructions: []const Instruction,
    output: std.ArrayList(isize),
    pub fn init(allocator: std.mem.Allocator, registers: Registers, instructionString: []const u8, instructions: []const Instruction) !ProgramState {
        return .{
            .allocator = allocator,
            .registers = registers,
            .instructionsString = try allocator.dupe(u8, instructionString),
            .instructions = try allocator.dupe(Instruction, instructions),
            .output = std.ArrayList(isize).init(allocator),
        };
    }
    pub fn runProgram(self: *ProgramState) !void {
        // var print_buf = [1]u8{0} ** 1024;
        while (true) {
            if (self.ip >= self.instructions.len) return;
            // std.debug.print("==========\n{s}\n", .{self.bufPrint(&print_buf)});
            try self.executeInstruction();
        }
    }
    pub fn executeInstruction(self: *ProgramState) !void {
        const instruction = self.instructions[self.ip];
        // std.debug.print("ip={d} {s} {d}\n", .{ self.ip, @tagName(instruction.opCode), instruction.operand });
        switch (instruction.opCode) {
            .adv => {
                self.ip += 1;
                self.registers.A = @divTrunc(
                    self.registers.A,
                    std.math.pow(isize, 2, try instruction.comboOperand(self.registers)),
                );
            },
            .bxl => {
                self.ip += 1;
                self.registers.B = self.registers.B ^ instruction.operand;
            },
            .bst => {
                self.ip += 1;
                self.registers.B = @mod(try instruction.comboOperand(self.registers), 8);
            },
            .jnz => {
                self.ip = if (self.registers.A != 0)
                    @divTrunc(instruction.operand, 2)
                else
                    self.ip + 1;
            },
            .bxc => {
                self.ip += 1;
                self.registers.B = self.registers.C ^ self.registers.B;
            },
            .out => {
                self.ip += 1;
                try self.output.append(@mod(try instruction.comboOperand(self.registers), 8));
            },
            .bdv => {
                self.ip += 1;
                self.registers.B = @divTrunc(
                    self.registers.A,
                    std.math.pow(isize, 2, try instruction.comboOperand(self.registers)),
                );
            },
            .cdv => {
                self.ip += 1;
                self.registers.C = @divTrunc(
                    self.registers.A,
                    std.math.pow(isize, 2, try instruction.comboOperand(self.registers)),
                );
            },
        }
    }
    pub fn fixA(self: *ProgramState, a: ?usize) error{ NoSpaceLeft, OutOfMemory, ReservedOperand, NoSolutionFound }!usize {
        var print_buf = [1]u8{0} ** 1024;
        const start_a = a orelse 0;
        for (start_a * 8..(start_a * 8) + 8) |regA| {
            if (regA == 0) continue;

            self.reset(regA);
            try self.runProgram();
            const output = try self.bufPrintOutput(&print_buf);

            const match = std.mem.endsWith(u8, self.instructionsString, output);
            if (match) {
                if (output.len == self.instructionsString.len) return regA;

                return self.fixA(regA) catch |err| switch (err) {
                    error.NoSolutionFound => continue,
                    else => return err,
                };
            }
        }
        return error.NoSolutionFound;
    }
    fn reset(self: *ProgramState, regA: usize) void {
        self.ip = 0;
        self.registers = .{ .A = @intCast(regA), .B = 0, .C = 0 };
        self.output.shrinkAndFree(0);
    }
    pub fn bufPrintOutput(self: *const ProgramState, buf: []u8) ![]u8 {
        if (self.output.items.len == 0) return buf[0..0];

        var printed: usize = 0;
        for (self.output.items) |item| {
            const str = try std.fmt.bufPrint(buf[printed..], "{d},", .{item});
            printed += str.len;
        }
        return buf[0 .. printed - 1];
    }
    pub fn bufPrint(self: *const ProgramState, buf: []u8) []u8 {
        var printed: usize = 0;
        var b = std.fmt.bufPrint(buf[printed..], "ip={d}\n", .{self.ip}) catch unreachable;
        printed += b.len;
        b = std.fmt.bufPrint(buf[printed..], "A={d}\n", .{self.registers.A}) catch unreachable;
        printed += b.len;
        b = std.fmt.bufPrint(buf[printed..], "B={d}\n", .{self.registers.B}) catch unreachable;
        printed += b.len;
        b = std.fmt.bufPrint(buf[printed..], "C={d}\n", .{self.registers.C}) catch unreachable;
        printed += b.len;
        b = std.fmt.bufPrint(buf[printed..], "out=", .{}) catch unreachable;
        printed += b.len;
        b = self.bufPrintOutput(buf[printed..]) catch unreachable;
        printed += b.len;
        return buf[0..printed];
    }
    pub fn deinit(self: *ProgramState) void {
        self.allocator.free(self.instructionsString);
        self.allocator.free(self.instructions);
        self.output.deinit();
    }
};

pub fn parseComputerStateFile(allocator: std.mem.Allocator, file_name: []const u8) !ProgramState {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var instructions_list = std.ArrayList(Instruction).init(allocator);
    defer instructions_list.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    const regA_line = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n') orelse return error.RegisterANotFound;
    const regA = try std.fmt.parseInt(isize, regA_line[12..], 10);
    const regB_line = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n') orelse return error.RegisterBNotFound;
    const regB = try std.fmt.parseInt(isize, regB_line[12..], 10);
    const regC_line = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n') orelse return error.RegisterCNotFound;
    const regC = try std.fmt.parseInt(isize, regC_line[12..], 10);

    _ = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n');

    const instructions_line = try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n') orelse return error.InstructionsNotFound;
    var it = std.mem.splitScalar(u8, instructions_line[9..], ',');
    while (it.next()) |opCodeToken| {
        const opCode = try std.fmt.parseInt(u3, opCodeToken, 10);
        const operandToken = it.next() orelse return error.OperandNotFound;
        const operand = try std.fmt.parseInt(u3, operandToken, 10);
        try instructions_list.append(.{ .opCode = @enumFromInt(opCode), .operand = operand });
    }
    return ProgramState.init(
        allocator,
        .{ .A = regA, .B = regB, .C = regC },
        instructions_line[9..],
        instructions_list.items,
    );
}

test parseComputerStateFile {
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** 1024;

    std.debug.print("day17/parseComputerStateFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    var program_state = try parseComputerStateFile(allocator, "data/day17/test.txt");
    defer program_state.deinit();

    try std.testing.expectEqualDeep(Registers{
        .A = 2024,
        .B = 0,
        .C = 0,
    }, program_state.registers);
    try std.testing.expectEqualDeep(&[_]Instruction{
        .{ .opCode = .adv, .operand = 3 },
        .{ .opCode = .out, .operand = 4 },
        .{ .opCode = .jnz, .operand = 0 },
    }, program_state.instructions);
    try std.testing.expectEqualStrings("", try program_state.bufPrintOutput(&print_buf));
}

test { // comboOperand
    std.debug.print("day17/comboOperand\n", .{});
    std.debug.print("\t0...3 -> literal value\n", .{});
    try std.testing.expectEqual(0, (Instruction{ .opCode = .adv, .operand = 0 }).comboOperand(.{ .A = 10, .B = 20, .C = 30 }));
    try std.testing.expectEqual(1, (Instruction{ .opCode = .adv, .operand = 1 }).comboOperand(.{ .A = 10, .B = 20, .C = 30 }));
    try std.testing.expectEqual(2, (Instruction{ .opCode = .adv, .operand = 2 }).comboOperand(.{ .A = 10, .B = 20, .C = 30 }));
    try std.testing.expectEqual(3, (Instruction{ .opCode = .adv, .operand = 3 }).comboOperand(.{ .A = 10, .B = 20, .C = 30 }));
    std.debug.print("\t4 -> regA value\n", .{});
    try std.testing.expectEqual(10, (Instruction{ .opCode = .adv, .operand = 4 }).comboOperand(.{ .A = 10, .B = 20, .C = 30 }));
    std.debug.print("\t5 -> regB value\n", .{});
    try std.testing.expectEqual(20, (Instruction{ .opCode = .adv, .operand = 5 }).comboOperand(.{ .A = 10, .B = 20, .C = 30 }));
    std.debug.print("\t6 -> regC value\n", .{});
    try std.testing.expectEqual(30, (Instruction{ .opCode = .adv, .operand = 6 }).comboOperand(.{ .A = 10, .B = 20, .C = 30 }));
    std.debug.print("\t7 -> illegal reserved operand\n", .{});
    try std.testing.expectEqual(error.ReservedOperand, (Instruction{ .opCode = .adv, .operand = 7 }).comboOperand(.{ .A = 10, .B = 20, .C = 30 }));
}

test { // executeInstruction
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** 1024;

    std.debug.print("day17/executeInstruction\n", .{});
    std.debug.print("\tadv performs division of register A by 2^comboOperand - literal combo operand\n", .{});
    var adv_program_state_literal = try ProgramState.init(
        allocator,
        .{ .A = 32, .B = 2, .C = 1 },
        "",
        &[_]Instruction{.{ .opCode = .adv, .operand = 3 }},
    );
    defer adv_program_state_literal.deinit();
    try adv_program_state_literal.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=4
        \\B=2
        \\C=1
        \\out=
    , adv_program_state_literal.bufPrint(&print_buf));

    std.debug.print("\tadv performs division of register A by 2^comboOperand - regB combo operand\n", .{});
    var adv_program_state_regB = try ProgramState.init(
        allocator,
        .{ .A = 32, .B = 2, .C = 1 },
        "",
        &[_]Instruction{.{ .opCode = .adv, .operand = 5 }},
    );
    defer adv_program_state_regB.deinit();
    try adv_program_state_regB.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=8
        \\B=2
        \\C=1
        \\out=
    , adv_program_state_regB.bufPrint(&print_buf));

    std.debug.print("\tbxl performs bitwise XOR of register B with literalOperand\n", .{});
    var bxl_program_state = try ProgramState.init(
        allocator,
        .{ .A = 0, .B = 7, .C = 0 },
        "",
        &[_]Instruction{.{ .opCode = .bxl, .operand = 3 }},
    );
    defer bxl_program_state.deinit();
    try bxl_program_state.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=0
        \\B=4
        \\C=0
        \\out=
    , bxl_program_state.bufPrint(&print_buf));

    std.debug.print("\tbst takes comboOperand %8 and stores in register B - literal value\n", .{});
    var bst_program_state_literal = try ProgramState.init(
        allocator,
        .{ .A = 11, .B = 0, .C = 0 },
        "",
        &[_]Instruction{.{ .opCode = .bst, .operand = 3 }},
    );
    defer bst_program_state_literal.deinit();
    try bst_program_state_literal.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=11
        \\B=3
        \\C=0
        \\out=
    , bst_program_state_literal.bufPrint(&print_buf));

    std.debug.print("\tbst takes comboOperand %8 and stores in register B - regA value\n", .{});
    var bst_program_state_regA = try ProgramState.init(
        allocator,
        .{ .A = 11, .B = 0, .C = 0 },
        "",
        &[_]Instruction{.{ .opCode = .bst, .operand = 4 }},
    );
    defer bst_program_state_regA.deinit();
    try bst_program_state_regA.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=11
        \\B=3
        \\C=0
        \\out=
    , bst_program_state_regA.bufPrint(&print_buf));

    std.debug.print("\tjnz jumps to ip = operand if regA != 0\n", .{});
    var jnz_program_state_jump = try ProgramState.init(
        allocator,
        .{ .A = 1, .B = 0, .C = 0 },
        "",
        &[_]Instruction{
            .{ .opCode = .jnz, .operand = 0 },
            .{ .opCode = .jnz, .operand = 4 },
        },
    );
    jnz_program_state_jump.ip = 1;
    defer jnz_program_state_jump.deinit();
    try jnz_program_state_jump.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=2
        \\A=1
        \\B=0
        \\C=0
        \\out=
    , jnz_program_state_jump.bufPrint(&print_buf));

    var jnz_program_state_no_jump = try ProgramState.init(
        allocator,
        .{ .A = 0, .B = 0, .C = 0 },
        "",
        &[_]Instruction{
            .{ .opCode = .jnz, .operand = 0 },
            .{ .opCode = .jnz, .operand = 4 },
        },
    );
    jnz_program_state_no_jump.ip = 1;
    defer jnz_program_state_no_jump.deinit();
    try jnz_program_state_no_jump.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=2
        \\A=0
        \\B=0
        \\C=0
        \\out=
    , jnz_program_state_no_jump.bufPrint(&print_buf));

    std.debug.print("\tbxc takes bitwise XOR of register B and C and stores in register B\n", .{});
    var bxc_program_state_literal = try ProgramState.init(
        allocator,
        .{ .A = 0, .B = 6, .C = 3 },
        "",
        &[_]Instruction{.{ .opCode = .bxc, .operand = 3 }},
    );
    defer bxc_program_state_literal.deinit();
    try bxc_program_state_literal.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=0
        \\B=5
        \\C=3
        \\out=
    , bxc_program_state_literal.bufPrint(&print_buf));

    std.debug.print("\tout outputs value of its combOperand modulo 8 - literal value\n", .{});
    var out_program_state_literal = try ProgramState.init(
        allocator,
        .{ .A = 11, .B = 6, .C = 3 },
        "",
        &[_]Instruction{.{ .opCode = .out, .operand = 3 }},
    );
    defer out_program_state_literal.deinit();
    try out_program_state_literal.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=11
        \\B=6
        \\C=3
        \\out=3
    , out_program_state_literal.bufPrint(&print_buf));

    std.debug.print("\tout outputs value of its combOperand modulo 8 - literal value\n", .{});
    var out_program_state_regA = try ProgramState.init(
        allocator,
        .{ .A = 12, .B = 6, .C = 3 },
        "",
        &[_]Instruction{.{ .opCode = .out, .operand = 4 }},
    );
    defer out_program_state_regA.deinit();
    try out_program_state_regA.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=12
        \\B=6
        \\C=3
        \\out=4
    , out_program_state_regA.bufPrint(&print_buf));

    std.debug.print("\tbdv divides register A by 2^comboOperand and stores in register B - literal\n", .{});
    var bdv_program_state_literal = try ProgramState.init(
        allocator,
        .{ .A = 32, .B = 2, .C = 0 },
        "",
        &[_]Instruction{.{ .opCode = .bdv, .operand = 3 }},
    );
    defer bdv_program_state_literal.deinit();
    try bdv_program_state_literal.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=32
        \\B=4
        \\C=0
        \\out=
    , bdv_program_state_literal.bufPrint(&print_buf));

    std.debug.print("\tbdv divides register A by 2^comboOperand and stores in register B - register B\n", .{});
    var bdv_program_state_regB = try ProgramState.init(
        allocator,
        .{ .A = 32, .B = 2, .C = 0 },
        "",
        &[_]Instruction{.{ .opCode = .bdv, .operand = 5 }},
    );
    defer bdv_program_state_regB.deinit();
    try bdv_program_state_regB.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=32
        \\B=8
        \\C=0
        \\out=
    , bdv_program_state_regB.bufPrint(&print_buf));

    std.debug.print("\tcdv divides register A by 2^comboOperand and stores in register C - literal\n", .{});
    var cdv_program_state_literal = try ProgramState.init(
        allocator,
        .{ .A = 32, .B = 2, .C = 0 },
        "",
        &[_]Instruction{.{ .opCode = .cdv, .operand = 3 }},
    );
    defer cdv_program_state_literal.deinit();
    try cdv_program_state_literal.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=32
        \\B=2
        \\C=4
        \\out=
    , cdv_program_state_literal.bufPrint(&print_buf));

    std.debug.print("\tcdv divides register A by 2^comboOperand and stores in register C - register C\n", .{});
    var cdv_program_state_regB = try ProgramState.init(
        allocator,
        .{ .A = 32, .B = 0, .C = 1 },
        "",
        &[_]Instruction{.{ .opCode = .cdv, .operand = 6 }},
    );
    defer cdv_program_state_regB.deinit();
    try cdv_program_state_regB.executeInstruction();
    try std.testing.expectEqualStrings(
        \\ip=1
        \\A=32
        \\B=0
        \\C=16
        \\out=
    , cdv_program_state_regB.bufPrint(&print_buf));
}

test { // runProgram
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** 1024;

    std.debug.print("day17/runProgram\n", .{});
    std.debug.print("\tread input file\n", .{});
    var program_state = try parseComputerStateFile(allocator, "data/day17/test.txt");
    defer program_state.deinit();

    std.debug.print("\trun program\n", .{});
    try program_state.runProgram();

    std.debug.print("\tcheck output\n", .{});

    try std.testing.expectEqualStrings(
        \\ip=3
        \\A=0
        \\B=0
        \\C=0
        \\out=5,7,3,0
    , program_state.bufPrint(&print_buf));
}

test { // runProgram
    const allocator = std.testing.allocator;
    var print_buf = [1]u8{0} ** 1024;

    std.debug.print("day17/runProgram\n", .{});
    std.debug.print("\tread input file\n", .{});
    var program_state = try parseComputerStateFile(allocator, "data/day17/test.txt");
    defer program_state.deinit();

    std.debug.print("\trun program\n", .{});
    program_state.registers.A = 117440;
    try program_state.runProgram();

    std.debug.print("\tcheck output\n", .{});

    try std.testing.expectEqualStrings(
        \\ip=3
        \\A=0
        \\B=0
        \\C=0
        \\out=0,3,5,4,3,0
    , program_state.bufPrint(&print_buf));
}

test { // fixA
    const allocator = std.testing.allocator;

    std.debug.print("day17/fix A\n", .{});
    std.debug.print("\tread input file\n", .{});
    var program_state = try parseComputerStateFile(allocator, "data/day17/test.txt");
    defer program_state.deinit();

    std.debug.print("\tfix A\n", .{});
    const fix_a = try program_state.fixA(null);

    try std.testing.expectEqual(117440, fix_a);
}
