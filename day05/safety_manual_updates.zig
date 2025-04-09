const std = @import("std");

const PageNumber = usize;

const PageOrder = struct { before: PageNumber, after: PageNumber };

const PagesUpdate = []const PageNumber;

const SafetyManualUpdates = struct {
    page_orders: []PageOrder,
    pages_updates: []PagesUpdate,
};

pub fn parseSafetyManualUpdatesFile(allocator: std.mem.Allocator, file_name: []const u8) !SafetyManualUpdates {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var page_orders_list = std.ArrayList(PageOrder).init(allocator);
    defer page_orders_list.deinit();

    var lineBuf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |readLineBuf| {
        if (readLineBuf.len == 0) break;

        var it = std.mem.splitScalar(u8, readLineBuf, '|');
        const before = try std.fmt.parseInt(PageNumber, it.next().?, 10);
        const after = try std.fmt.parseInt(PageNumber, it.next().?, 10);

        try page_orders_list.append(.{ .before = before, .after = after });
    }

    var pages_updates_list = std.ArrayList([]const PageNumber).init(allocator);
    defer pages_updates_list.deinit();

    var pagesUpdateBuf: [1024]PageNumber = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |readLineBuf| {
        var i: usize = 0;
        var it = std.mem.splitScalar(u8, readLineBuf, ',');
        while (it.next()) |token| {
            const pageNumber = try std.fmt.parseInt(PageNumber, token, 10);
            pagesUpdateBuf[i] = pageNumber;
            i += 1;
        }
        const pages_update = try allocator.alloc(PageNumber, i);
        std.mem.copyForwards(PageNumber, pages_update, pagesUpdateBuf[0..i]);
        try pages_updates_list.append(pages_update);
    }
    return .{
        .page_orders = try page_orders_list.toOwnedSlice(),
        .pages_updates = try pages_updates_list.toOwnedSlice(),
    };
}

test parseSafetyManualUpdatesFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day05/parseSafetyManualUpdatesFile\n", .{});
    std.debug.print("\tread test input file\n", .{});
    const safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "data/day05/test.txt");
    std.debug.print("\tcheck page orders\n", .{});
    try std.testing.expectEqualDeep(&[_]PageOrder{
        .{ .before = 47, .after = 53 },
        .{ .before = 97, .after = 13 },
        .{ .before = 97, .after = 61 },
        .{ .before = 97, .after = 47 },
        .{ .before = 75, .after = 29 },
        .{ .before = 61, .after = 13 },
        .{ .before = 75, .after = 53 },
        .{ .before = 29, .after = 13 },
        .{ .before = 97, .after = 29 },
        .{ .before = 53, .after = 29 },
        .{ .before = 61, .after = 53 },
        .{ .before = 97, .after = 53 },
        .{ .before = 61, .after = 29 },
        .{ .before = 47, .after = 13 },
        .{ .before = 75, .after = 47 },
        .{ .before = 97, .after = 75 },
        .{ .before = 47, .after = 61 },
        .{ .before = 75, .after = 61 },
        .{ .before = 47, .after = 29 },
        .{ .before = 75, .after = 13 },
        .{ .before = 53, .after = 13 },
    }, safety_manual_updates.page_orders);
    std.debug.print("\tcheck pages updates\n", .{});
    try std.testing.expectEqualDeep(&[_][]const PageNumber{ &[_]PageNumber{
        75,
        47,
        61,
        53,
        29,
    }, &[_]PageNumber{
        97,
        61,
        53,
        29,
        13,
    }, &[_]PageNumber{
        75,
        29,
        13,
    }, &[_]PageNumber{
        75,
        97,
        47,
        61,
        53,
    }, &[_]PageNumber{
        61,
        13,
        29,
    }, &[_]PageNumber{
        97,
        13,
        75,
        29,
        47,
    } }, safety_manual_updates.pages_updates);
}

const SafetyManualUpdateAudit = struct {
    is_ok: bool,
    valid_pages_update: []const PageNumber,
    errors: []const PageOrder,
};

fn getValidPagesUpdate(allocator: std.mem.Allocator, pages_update: []const PageNumber, page_orders: []const PageOrder) ![]const PageNumber {
    var pageNumberConstraints = std.hash_map.AutoHashMap(PageNumber, usize).init(allocator);
    defer pageNumberConstraints.deinit();
    for (pages_update) |page_number| {
        var contraints_count: usize = 0;
        for (page_orders) |page_order| {
            for (pages_update) |other_page_number| {
                if (page_number == page_order.before and other_page_number == page_order.after) {
                    contraints_count += 1;
                }
            }
        }
        try pageNumberConstraints.put(page_number, contraints_count);
    }

    const valid_pages_update = try allocator.dupe(PageNumber, pages_update);
    std.mem.sort(PageNumber, valid_pages_update, pageNumberConstraints, struct {
        fn lessThan(constraints: @TypeOf(pageNumberConstraints), lhs: PageNumber, rhs: PageNumber) bool {
            return constraints.get(lhs).? > constraints.get(rhs).?;
        }
    }.lessThan);

    return valid_pages_update;
}

pub fn auditSafetyManualUpdate(allocator: std.mem.Allocator, pages_update: []const PageNumber, page_orders: []const PageOrder) !SafetyManualUpdateAudit {
    var errors_list = std.ArrayList(PageOrder).init(allocator);
    defer errors_list.deinit();

    for (page_orders) |page_order| {
        order: for (pages_update, 0..) |page_number, update_index| {
            if (page_number != page_order.before) continue;
            for (pages_update[0..update_index]) |before| {
                if (before == page_order.after) {
                    try errors_list.append(page_order);
                    break :order;
                }
            }
        }
    }

    const valid_pages_update = try getValidPagesUpdate(allocator, pages_update, page_orders);
    return .{
        .is_ok = errors_list.items.len == 0,
        .valid_pages_update = valid_pages_update,
        .errors = try errors_list.toOwnedSlice(),
    };
}

test auditSafetyManualUpdate {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day05/auditSafetyManualUpdate\n", .{});
    std.debug.print("\tread test input file\n", .{});
    const safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "data/day05/test.txt");

    std.debug.print("\tSafety protocols clearly indicate that new pages for the safety manuals must be printed in a very specific order.\n", .{});
    std.debug.print("\tThe notation X|Y means that if both page number X and page number Y are to be produced as part of an update\n", .{});
    std.debug.print("\tpage number X must be printed at some point before page number Y.\n", .{});
    std.debug.print("\t75,47,61,53,29 is ok\n", .{});
    std.debug.print("\t- 75 is correctly first because there are rules that put each other page after it: 75|47, 75|61, 75|53, and 75|29.\n", .{});
    std.debug.print("\t- 47 is correctly second because 75 must be before it (75|47) and every other page must be after it according to 47|61, 47|53, and 47|29.\n", .{});
    std.debug.print("\t- 61 is correctly in the middle because 75 and 47 are before it (75|61 and 47|61) and 53 and 29 are after it (61|53 and 61|29).\n", .{});
    std.debug.print("\t- 53 is correctly fourth because it is before page number 29 (53|29).\n", .{});
    std.debug.print("\t- 29 is the only page left and so is correctly last.\n", .{});
    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .is_ok = true,
        .valid_pages_update = &[_]PageNumber{ 75, 47, 61, 53, 29 },
        .errors = &[_]PageOrder{},
    }, try auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 75, 47, 61, 53, 29 },
        safety_manual_updates.page_orders,
    ));

    std.debug.print("\t97,61,53,29,13 is ok\n", .{});
    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .is_ok = true,
        .valid_pages_update = &[_]PageNumber{ 97, 61, 53, 29, 13 },
        .errors = &[_]PageOrder{},
    }, try auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 97, 61, 53, 29, 13 },
        safety_manual_updates.page_orders,
    ));

    std.debug.print("\t75,29,13 is ok\n", .{});
    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .is_ok = true,
        .valid_pages_update = &[_]PageNumber{ 75, 29, 13 },
        .errors = &[_]PageOrder{},
    }, try auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 75, 29, 13 },
        safety_manual_updates.page_orders,
    ));

    std.debug.print("\t75,97,47,61,53 is not ok: it would print 75 before 97, which violates the rule 97|75\n", .{});
    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .is_ok = false,
        .valid_pages_update = &[_]PageNumber{ 97, 75, 47, 61, 53 },
        .errors = &[_]PageOrder{
            .{ .before = 97, .after = 75 },
        },
    }, try auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 75, 97, 47, 61, 53 },
        safety_manual_updates.page_orders,
    ));

    std.debug.print("\t61,13,29 is not ok: it breaks the rule 29|13\n", .{});
    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .is_ok = false,
        .valid_pages_update = &[_]PageNumber{ 61, 29, 13 },
        .errors = &[_]PageOrder{
            .{ .before = 29, .after = 13 },
        },
    }, try auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 61, 13, 29 },
        safety_manual_updates.page_orders,
    ));

    std.debug.print("\t97,13,75,29,47 is not ok: it breaks several rules\n", .{});
    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .is_ok = false,
        .valid_pages_update = &[_]PageNumber{ 97, 75, 47, 29, 13 },
        .errors = &[_]PageOrder{
            .{ .before = 29, .after = 13 },
            .{ .before = 47, .after = 13 },
            .{ .before = 47, .after = 29 },
            .{ .before = 75, .after = 13 },
        },
    }, try auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 97, 13, 75, 29, 47 },
        safety_manual_updates.page_orders,
    ));
}

const SafetyManualUpdatesCheck = struct {
    valid_updates_check: usize,
    invalid_updates_check: usize,
};

pub fn checkSafetyManualUpdates(allocator: std.mem.Allocator, safety_manual_updates: SafetyManualUpdates) !SafetyManualUpdatesCheck {
    var valid_updates_check: usize = 0;
    var invalid_updates_check: usize = 0;
    for (safety_manual_updates.pages_updates) |pages_update| {
        const audit = try auditSafetyManualUpdate(allocator, pages_update, safety_manual_updates.page_orders);
        if (audit.is_ok) {
            const middle_number = pages_update[pages_update.len / 2];
            valid_updates_check += middle_number;
        } else {
            const middle_number = audit.valid_pages_update[pages_update.len / 2];
            invalid_updates_check += middle_number;
        }
    }
    return .{
        .valid_updates_check = valid_updates_check,
        .invalid_updates_check = invalid_updates_check,
    };
}

test checkSafetyManualUpdates {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day05/checkSafetyManualUpdates\n", .{});
    std.debug.print("\tread test input file\n", .{});
    const safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "data/day05/test.txt");

    std.debug.print("\tcheck safety manual updates\n", .{});
    try std.testing.expectEqualDeep(SafetyManualUpdatesCheck{
        .valid_updates_check = 143,
        .invalid_updates_check = 123,
    }, try checkSafetyManualUpdates(allocator, safety_manual_updates));
}
