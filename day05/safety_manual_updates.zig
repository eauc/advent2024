//! # Day 5: Print Queue
//! Satisfied with their search on Ceres, the squadron of scholars suggests subsequently scanning the stationery stacks of sub-basement 17.
//!
//! The North Pole printing department is busier than ever this close to Christmas, and while The Historians continue their search of this historically significant facility, an Elf operating a very familiar printer beckons you over.
//!
//! The Elf must recognize you, because they waste no time explaining that the new sleigh launch safety manual updates won't print correctly. Failure to update the safety manuals would be dire indeed, so you offer your services.
//!
//! Safety protocols clearly indicate that new pages for the safety manuals must be printed in a very specific order. The notation X|Y means that if both page number X and page number Y are to be produced as part of an update, page number X must be printed at some point before page number Y.
//!
//! The Elf has for you both the page ordering rules and the pages to produce in each update (your puzzle input), but can't figure out whether each update has the pages in the right order.
//!
//! For example:
//! ```
//! 47|53
//! 97|13
//! 97|61
//! 97|47
//! 75|29
//! 61|13
//! 75|53
//! 29|13
//! 97|29
//! 53|29
//! 61|53
//! 97|53
//! 61|29
//! 47|13
//! 75|47
//! 97|75
//! 47|61
//! 75|61
//! 47|29
//! 75|13
//! 53|13
//!
//! 75,47,61,53,29
//! 97,61,53,29,13
//! 75,29,13
//! 75,97,47,61,53
//! 61,13,29
//! 97,13,75,29,47
//! ```
//! The first section specifies the page ordering rules, one per line. The first rule, 47|53, means that if an update includes both page number 47 and page number 53, then page number 47 must be printed at some point before page number 53. (47 doesn't necessarily need to be immediately before 53; other pages are allowed to be between them.)
//!
//! The second section specifies the page numbers of each update. Because most safety manuals are different, the pages needed in the updates are different too. The first update, 75,47,61,53,29, means that the update consists of page numbers 75, 47, 61, 53, and 29.
//!
//! To get the printers going as soon as possible, start by identifying which updates are already in the right order.
//!
//! In the above example, the first update (75,47,61,53,29) is in the right order:
//!
//! - 75 is correctly first because there are rules that put each other page after it: 75|47, 75|61, 75|53, and 75|29.
//! - 47 is correctly second because 75 must be before it (75|47) and every other page must be after it according to 47|61, 47|53, and 47|29.
//! - 61 is correctly in the middle because 75 and 47 are before it (75|61 and 47|61) and 53 and 29 are after it (61|53 and 61|29).
//! - 53 is correctly fourth because it is before page number 29 (53|29).
//! - 29 is the only page left and so is correctly last.
//!
//! Because the first update does not include some page numbers, the ordering rules involving those missing page numbers are ignored.
//!
//! The second and third updates are also in the correct order according to the rules. Like the first update, they also do not include every page number, and so only some of the ordering rules apply - within each update, the ordering rules that involve missing page numbers are not used.
//!
//! The fourth update, 75,97,47,61,53, is not in the correct order: it would print 75 before 97, which violates the rule 97|75.
//!
//! The fifth update, 61,13,29, is also not in the correct order, since it breaks the rule 29|13.
//!
//! The last update, 97,13,75,29,47, is not in the correct order due to breaking several rules.
//!
//! For some reason, the Elves also need to know the middle page number of each update being printed. Because you are currently only printing the correctly-ordered updates, you will need to find the middle page number of each correctly-ordered update. In the above example, the correctly-ordered updates are:
//!
//! 75,47,61,53,29
//! 97,61,53,29,13
//! 75,29,13
//! These have middle page numbers of 61, 53, and 29 respectively. Adding these page numbers together gives 143.
//! For each of the incorrectly-ordered updates, use the page ordering rules to put the page numbers in the right order. For the above example, here are the three incorrectly-ordered updates and their correct orderings:
//! ```
//! 75,97,47,61,53 becomes 97,75,47,61,53.
//! 61,13,29 becomes 61,29,13.
//! 97,13,75,29,47 becomes 97,75,47,29,13.
//! ```
//! After taking only the incorrectly-ordered updates and ordering them correctly, their middle page numbers are 47, 29, and 47. Adding these together produces 123.
const std = @import("std");

const PageNumber = usize;

const PageOrder = struct { before: PageNumber, after: PageNumber };

const PagesUpdate = []const PageNumber;

const SafetyManualUpdates = struct {
    allocator: std.mem.Allocator,
    page_orders: []PageOrder,
    pages_updates: []PagesUpdate,
    pub fn deinit(self: *SafetyManualUpdates) void {
        self.allocator.free(self.page_orders);
        for (self.pages_updates) |pages_update| self.allocator.free(pages_update);
        self.allocator.free(self.pages_updates);
    }
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

        page_orders_list.append(.{ .before = before, .after = after }) catch unreachable;
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
        const pages_update = allocator.alloc(PageNumber, i) catch unreachable;
        std.mem.copyForwards(PageNumber, pages_update, pagesUpdateBuf[0..i]);
        pages_updates_list.append(pages_update) catch unreachable;
    }
    return .{
        .allocator = allocator,
        .page_orders = page_orders_list.toOwnedSlice() catch unreachable,
        .pages_updates = pages_updates_list.toOwnedSlice() catch unreachable,
    };
}

test "parseSafetyManualUpdatesFile/page_orders" {
    const allocator = std.testing.allocator;

    var safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "day05/test.txt");
    defer safety_manual_updates.deinit();

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
}

test "parseSafetyManualUpdatesFile/pages_updates" {
    const allocator = std.testing.allocator;

    var safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "day05/test.txt");
    defer safety_manual_updates.deinit();

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
    allocator: std.mem.Allocator,
    is_ok: bool,
    valid_pages_update: []const PageNumber,
    errors: []const PageOrder,
    pub fn deinit(self: *SafetyManualUpdateAudit) void {
        self.allocator.free(self.valid_pages_update);
        self.allocator.free(self.errors);
    }
};

fn getValidPagesUpdate(allocator: std.mem.Allocator, pages_update: []const PageNumber, page_orders: []const PageOrder) []const PageNumber {
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
        pageNumberConstraints.put(page_number, contraints_count) catch unreachable;
    }

    const valid_pages_update = allocator.dupe(PageNumber, pages_update) catch unreachable;
    std.mem.sort(PageNumber, valid_pages_update, pageNumberConstraints, struct {
        fn lessThan(constraints: @TypeOf(pageNumberConstraints), lhs: PageNumber, rhs: PageNumber) bool {
            return constraints.get(lhs).? > constraints.get(rhs).?;
        }
    }.lessThan);

    return valid_pages_update;
}

/// Audits a safety manual update recors, checking if the pages are in the right order
/// if not, calculates the correct order for the pages
pub fn auditSafetyManualUpdate(allocator: std.mem.Allocator, pages_update: []const PageNumber, page_orders: []const PageOrder) SafetyManualUpdateAudit {
    var errors_list = std.ArrayList(PageOrder).init(allocator);
    defer errors_list.deinit();

    for (page_orders) |page_order| {
        order: for (pages_update, 0..) |page_number, update_index| {
            if (page_number != page_order.before) continue;
            for (pages_update[0..update_index]) |before| {
                if (before == page_order.after) {
                    errors_list.append(page_order) catch unreachable;
                    break :order;
                }
            }
        }
    }

    const valid_pages_update = getValidPagesUpdate(allocator, pages_update, page_orders);
    return .{
        .allocator = allocator,
        .is_ok = errors_list.items.len == 0,
        .valid_pages_update = valid_pages_update,
        .errors = errors_list.toOwnedSlice() catch unreachable,
    };
}

test "auditSafetyManualUpdate/is_ok [75, 47, 61, 53, 29]" {
    const allocator = std.testing.allocator;

    var safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "day05/test.txt");
    defer safety_manual_updates.deinit();

    var audit = auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 75, 47, 61, 53, 29 },
        safety_manual_updates.page_orders,
    );
    defer audit.deinit();

    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .allocator = allocator,
        .is_ok = true,
        .valid_pages_update = &[_]PageNumber{ 75, 47, 61, 53, 29 },
        .errors = &[_]PageOrder{},
    }, audit);
}

test "auditSafetyManualUpdate/is_ok [97, 61, 53, 29, 13]" {
    const allocator = std.testing.allocator;

    var safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "day05/test.txt");
    defer safety_manual_updates.deinit();

    var audit = auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 97, 61, 53, 29, 13 },
        safety_manual_updates.page_orders,
    );
    defer audit.deinit();

    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .allocator = allocator,
        .is_ok = true,
        .valid_pages_update = &[_]PageNumber{ 97, 61, 53, 29, 13 },
        .errors = &[_]PageOrder{},
    }, audit);
}

test "auditSafetyManualUpdate/is_ok [75, 29, 13]" {
    const allocator = std.testing.allocator;

    var safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "day05/test.txt");
    defer safety_manual_updates.deinit();

    var audit = auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 75, 29, 13 },
        safety_manual_updates.page_orders,
    );
    defer audit.deinit();

    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .allocator = allocator,
        .is_ok = true,
        .valid_pages_update = &[_]PageNumber{ 75, 29, 13 },
        .errors = &[_]PageOrder{},
    }, audit);
}

test "auditSafetyManualUpdate/is not ok: it would print 75 before 97, which violates the rule 97|75" {
    const allocator = std.testing.allocator;

    var safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "day05/test.txt");
    defer safety_manual_updates.deinit();

    var audit = auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 75, 97, 47, 61, 53 },
        safety_manual_updates.page_orders,
    );
    defer audit.deinit();

    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .allocator = allocator,
        .is_ok = false,
        .valid_pages_update = &[_]PageNumber{ 97, 75, 47, 61, 53 },
        .errors = &[_]PageOrder{
            .{ .before = 97, .after = 75 },
        },
    }, audit);
}

test "auditSafetyManualUpdate/is not ok: it breaks the rule 29|13" {
    const allocator = std.testing.allocator;

    var safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "day05/test.txt");
    defer safety_manual_updates.deinit();

    var audit = auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 61, 13, 29 },
        safety_manual_updates.page_orders,
    );
    defer audit.deinit();

    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .allocator = allocator,
        .is_ok = false,
        .valid_pages_update = &[_]PageNumber{ 61, 29, 13 },
        .errors = &[_]PageOrder{
            .{ .before = 29, .after = 13 },
        },
    }, audit);
}

test "auditSafetyManualUpdate/is not ok: it breaks several rules" {
    const allocator = std.testing.allocator;

    var safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "day05/test.txt");
    defer safety_manual_updates.deinit();

    var audit = auditSafetyManualUpdate(
        allocator,
        &[_]PageNumber{ 97, 13, 75, 29, 47 },
        safety_manual_updates.page_orders,
    );
    defer audit.deinit();

    try std.testing.expectEqualDeep(SafetyManualUpdateAudit{
        .allocator = allocator,
        .is_ok = false,
        .valid_pages_update = &[_]PageNumber{ 97, 75, 47, 29, 13 },
        .errors = &[_]PageOrder{
            .{ .before = 29, .after = 13 },
            .{ .before = 47, .after = 13 },
            .{ .before = 47, .after = 29 },
            .{ .before = 75, .after = 13 },
        },
    }, audit);
}

pub const SafetyManualUpdatesCheck = struct {
    valid_updates_check: usize,
    invalid_updates_check: usize,
};

/// Returns the sum of the middle page number of the correctly-ordered updates
/// and the sum of the middle page number of the incorrectly-ordered re-ordered updates
pub fn checkSafetyManualUpdates(allocator: std.mem.Allocator, safety_manual_updates: SafetyManualUpdates) !SafetyManualUpdatesCheck {
    var valid_updates_check: usize = 0;
    var invalid_updates_check: usize = 0;
    for (safety_manual_updates.pages_updates) |pages_update| {
        var audit = auditSafetyManualUpdate(allocator, pages_update, safety_manual_updates.page_orders);
        defer audit.deinit();

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
    const allocator = std.testing.allocator;

    var safety_manual_updates = try parseSafetyManualUpdatesFile(allocator, "day05/test.txt");
    defer safety_manual_updates.deinit();

    try std.testing.expectEqualDeep(SafetyManualUpdatesCheck{
        .valid_updates_check = 143,
        .invalid_updates_check = 123,
    }, try checkSafetyManualUpdates(allocator, safety_manual_updates));
}
