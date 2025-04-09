const std = @import("std");

const GardenMap = struct {
    height: usize,
    width: usize,
    map: []const []const u8,
};

pub fn parseGardenMapFile(allocator: std.mem.Allocator, file_name: []const u8) !GardenMap {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    var garden_map = std.ArrayList([]const u8).init(allocator);
    defer garden_map.deinit();

    var lineBuf: [25 * 1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&lineBuf, '\n')) |readLineBuf| {
        const line = try allocator.alloc(u8, readLineBuf.len);
        std.mem.copyForwards(u8, line, readLineBuf);
        try garden_map.append(line);
    }

    return .{
        .height = garden_map.items.len,
        .width = garden_map.items[0].len,
        .map = try garden_map.toOwnedSlice(),
    };
}

test parseGardenMapFile {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day12/parseGardenMapFile\n", .{});
    std.debug.print("\tread input file\n", .{});
    const garden_map = try parseGardenMapFile(allocator, "data/day12/test.txt");
    try std.testing.expectEqual(10, garden_map.height);
    try std.testing.expectEqual(10, garden_map.width);
    try std.testing.expectEqualDeep(&[_][]const u8{
        "RRRRIICCFF",
        "RRRRIICCCF",
        "VVRRRCCFFF",
        "VVRCCCJFFF",
        "VVVVCJJCFE",
        "VVIVCCJJEE",
        "VVIIICJJEE",
        "MIIIIIJJEE",
        "MIIISIJEEE",
        "MMMISSJEEE",
    }, garden_map.map);
}

const Position = struct {
    row: usize,
    col: usize,
    pub fn index(self: *const Position, garden_map: GardenMap) usize {
        return self.row * garden_map.width + self.col;
    }
};

const GardenPlot = struct {
    position: Position,
    plant: u8,
    neighbours: []const usize,
    fences: u8,
    corners: u8,
};

fn getNeightbours(garden_map: GardenMap, position: Position, neighbours_buf: *[4]Position) []Position {
    var n_neighbours: usize = 0;
    if (position.row > 0) {
        neighbours_buf[n_neighbours] = .{ .row = position.row - 1, .col = position.col };
        n_neighbours += 1;
    }
    if (position.row < garden_map.height - 1) {
        neighbours_buf[n_neighbours] = .{ .row = position.row + 1, .col = position.col };
        n_neighbours += 1;
    }
    if (position.col > 0) {
        neighbours_buf[n_neighbours] = .{ .row = position.row, .col = position.col - 1 };
        n_neighbours += 1;
    }
    if (position.col < garden_map.width - 1) {
        neighbours_buf[n_neighbours] = .{ .row = position.row, .col = position.col + 1 };
        n_neighbours += 1;
    }
    return neighbours_buf[0..n_neighbours];
}

fn plotCorners(garden_map: GardenMap, garden_plot: GardenPlot) u8 {
    const plant = garden_plot.plant;
    const row = garden_plot.position.row;
    const col = garden_plot.position.col;
    const plant_up = if (row > 0) garden_map.map[row - 1][col] == plant else false;
    const plant_up_right = if (row > 0 and col < garden_map.width - 1) garden_map.map[row - 1][col + 1] == plant else false;
    const plant_right = if (col < garden_map.width - 1) garden_map.map[row][col + 1] == plant else false;
    const plant_down_right = if (row < garden_map.height - 1 and col < garden_map.width - 1) garden_map.map[row + 1][col + 1] == plant else false;
    const plant_down = if (row < garden_map.height - 1) garden_map.map[row + 1][col] == plant else false;
    const plant_down_left = if (row < garden_map.height - 1 and col > 0) garden_map.map[row + 1][col - 1] == plant else false;
    const plant_left = if (col > 0) garden_map.map[row][col - 1] == plant else false;
    const plant_up_left = if (row > 0 and col > 0) garden_map.map[row - 1][col - 1] == plant else false;
    var corners: u8 = 0;
    if (!plant_up and !plant_right) {
        corners += 1;
    }
    if (plant_up and plant_right and !plant_up_right) {
        corners += 1;
    }
    if (!plant_right and !plant_down) {
        corners += 1;
    }
    if (plant_right and plant_down and !plant_down_right) {
        corners += 1;
    }
    if (!plant_down and !plant_left) {
        corners += 1;
    }
    if (plant_down and plant_left and !plant_down_left) {
        corners += 1;
    }
    if (!plant_left and !plant_up) {
        corners += 1;
    }
    if (plant_left and plant_up and !plant_up_left) {
        corners += 1;
    }
    return corners;
}

const GardenPlots = struct {
    plots: []const GardenPlot,
    width: usize,
    height: usize,
};

pub fn gardenPlots(allocator: std.mem.Allocator, garden_map: GardenMap) !GardenPlots {
    const garden_plots = try allocator.alloc(
        GardenPlot,
        garden_map.height * garden_map.width,
    );
    var neighbours_buf = [1]Position{.{ .row = 0, .col = 0 }} ** 4;
    for (garden_map.map, 0..) |line, row| {
        for (line, 0..) |plant, col| {
            const index = row * garden_map.width + col;
            const position = Position{ .row = row, .col = col };
            garden_plots[index].position = position;
            const neighbours = getNeightbours(garden_map, position, &neighbours_buf);
            var neighbours_ids = std.ArrayList(usize).init(allocator);
            defer neighbours_ids.deinit();
            for (neighbours) |neighbour| {
                if (garden_map.map[neighbour.row][neighbour.col] != plant) continue;
                const neighbour_key = neighbour.index(garden_map);
                try neighbours_ids.append(neighbour_key);
            }
            garden_plots[index].neighbours = try neighbours_ids.toOwnedSlice();
            garden_plots[index].plant = plant;
            garden_plots[index].fences = @intCast(4 - garden_plots[index].neighbours.len);
            garden_plots[index].corners = plotCorners(garden_map, garden_plots[index]);
        }
    }
    return .{
        .plots = garden_plots,
        .width = garden_map.width,
        .height = garden_map.height,
    };
}

test gardenPlots {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day12/gardenPlots\n", .{});
    std.debug.print("\tcompute plots\n", .{});
    const garden_plots = try gardenPlots(allocator, .{
        .width = 4,
        .height = 4,
        .map = &[_][]const u8{
            "AAAA",
            "BBCD",
            "BBCC",
            "EEEC",
        },
    });
    try std.testing.expectEqualDeep(GardenPlots{
        .width = 4,
        .height = 4,
        .plots = &[_]GardenPlot{
            .{
                .plant = 'A',
                .position = .{ .row = 0, .col = 0 },
                .neighbours = &[_]usize{1},
                .fences = 3,
                .corners = 2,
            },
            .{
                .plant = 'A',
                .position = .{ .row = 0, .col = 1 },
                .neighbours = &[_]usize{ 0, 2 },
                .fences = 2,
                .corners = 0,
            },
            .{
                .plant = 'A',
                .position = .{ .row = 0, .col = 2 },
                .neighbours = &[_]usize{ 1, 3 },
                .fences = 2,
                .corners = 0,
            },
            .{
                .plant = 'A',
                .position = .{ .row = 0, .col = 3 },
                .neighbours = &[_]usize{2},
                .fences = 3,
                .corners = 2,
            },
            .{
                .plant = 'B',
                .position = .{ .row = 1, .col = 0 },
                .neighbours = &[_]usize{ 8, 5 },
                .fences = 2,
                .corners = 1,
            },
            .{
                .plant = 'B',
                .position = .{ .row = 1, .col = 1 },
                .neighbours = &[_]usize{ 9, 4 },
                .fences = 2,
                .corners = 1,
            },
            .{
                .plant = 'C',
                .position = .{ .row = 1, .col = 2 },
                .neighbours = &[_]usize{10},
                .fences = 3,
                .corners = 2,
            },
            .{
                .plant = 'D',
                .position = .{ .row = 1, .col = 3 },
                .neighbours = &[_]usize{},
                .fences = 4,
                .corners = 4,
            },
            .{
                .plant = 'B',
                .position = .{ .row = 2, .col = 0 },
                .neighbours = &[_]usize{ 4, 9 },
                .fences = 2,
                .corners = 1,
            },
            .{
                .plant = 'B',
                .position = .{ .row = 2, .col = 1 },
                .neighbours = &[_]usize{ 5, 8 },
                .fences = 2,
                .corners = 1,
            },
            .{
                .plant = 'C',
                .position = .{ .row = 2, .col = 2 },
                .neighbours = &[_]usize{ 6, 11 },
                .fences = 2,
                .corners = 2,
            },
            .{
                .plant = 'C',
                .position = .{ .row = 2, .col = 3 },
                .neighbours = &[_]usize{ 15, 10 },
                .fences = 2,
                .corners = 2,
            },
            .{
                .plant = 'E',
                .position = .{ .row = 3, .col = 0 },
                .neighbours = &[_]usize{13},
                .fences = 3,
                .corners = 2,
            },
            .{
                .plant = 'E',
                .position = .{ .row = 3, .col = 1 },
                .neighbours = &[_]usize{ 12, 14 },
                .fences = 2,
                .corners = 0,
            },
            .{
                .plant = 'E',
                .position = .{ .row = 3, .col = 2 },
                .neighbours = &[_]usize{13},
                .fences = 3,
                .corners = 2,
            },
            .{
                .plant = 'C',
                .position = .{ .row = 3, .col = 3 },
                .neighbours = &[_]usize{11},
                .fences = 3,
                .corners = 2,
            },
        },
    }, garden_plots);
}

const GardenArea = struct {
    plant: u8,
    plots: []const usize,
    area: usize,
    perimeter: usize,
    sides: usize,
};

fn addPlotNeighboursToAreaPlotsList(garden_plots: GardenPlots, plot: GardenPlot, plots_list: *std.ArrayList(usize)) !void {
    add_neighbour: for (plot.neighbours) |neighbour| {
        for (plots_list.items) |existing| {
            if (neighbour == existing) continue :add_neighbour;
        }
        try plots_list.append(neighbour);
        try addPlotNeighboursToAreaPlotsList(garden_plots, garden_plots.plots[neighbour], plots_list);
    }
}

fn areaPerimeter(garden_plots: GardenPlots, plot_indices: []const usize) usize {
    var perimeter: usize = 0;
    for (plot_indices) |plot| {
        perimeter += garden_plots.plots[plot].fences;
    }
    return perimeter;
}

fn areaSides(garden_plots: GardenPlots, plot_indices: []const usize) usize {
    var sides: usize = 0;
    for (plot_indices) |plot| {
        sides += garden_plots.plots[plot].corners;
    }
    return sides;
}

fn inArea(plot_indices: []const usize, plot_index: usize) bool {
    for (plot_indices) |plot| {
        if (plot == plot_index) {
            return true;
        }
    }
    return false;
}

pub fn gardenAreas(allocator: std.mem.Allocator, garden_plots: GardenPlots) ![]const GardenArea {
    var areas_list = std.ArrayList(GardenArea).init(allocator);
    defer areas_list.deinit();

    var plots_list = std.ArrayList(usize).init(allocator);
    defer plots_list.deinit();

    add_area: for (0..garden_plots.plots.len) |index| {
        for (areas_list.items) |area| {
            for (area.plots) |area_plot| {
                if (area_plot == index) {
                    continue :add_area;
                }
            }
        }
        const plot = garden_plots.plots[index];
        try plots_list.append(index);
        try addPlotNeighboursToAreaPlotsList(garden_plots, plot, &plots_list);

        const area = plots_list.items.len;
        const perimeter = areaPerimeter(garden_plots, plots_list.items);
        const plots = try plots_list.toOwnedSlice();
        std.mem.sort(usize, plots, {}, comptime std.sort.asc(usize));
        const sides = areaSides(garden_plots, plots);
        try areas_list.append(.{
            .plant = plot.plant,
            .plots = plots,
            .area = area,
            .perimeter = perimeter,
            .sides = sides,
        });
    }

    return try areas_list.toOwnedSlice();
}

test gardenAreas {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day12/gardenAreas\n", .{});
    std.debug.print("\tcompute plots\n", .{});
    const garden_map = GardenMap{
        .width = 4,
        .height = 4,
        .map = &[_][]const u8{
            "AAAA",
            "BBCD",
            "BBCC",
            "EEEC",
        },
    };
    const garden_plots = try gardenPlots(allocator, garden_map);
    std.debug.print("\tcompute areas\n", .{});
    const garden_areas = try gardenAreas(allocator, garden_plots);
    try std.testing.expectEqualDeep(&[_]GardenArea{
        .{ .plant = 'A', .plots = &[_]usize{ 0, 1, 2, 3 }, .area = 4, .perimeter = 10, .sides = 4 },
        .{ .plant = 'B', .plots = &[_]usize{ 4, 5, 8, 9 }, .area = 4, .perimeter = 8, .sides = 4 },
        .{ .plant = 'C', .plots = &[_]usize{ 6, 10, 11, 15 }, .area = 4, .perimeter = 10, .sides = 8 },
        .{ .plant = 'D', .plots = &[_]usize{7}, .area = 1, .perimeter = 4, .sides = 4 },
        .{ .plant = 'E', .plots = &[_]usize{ 12, 13, 14 }, .area = 3, .perimeter = 8, .sides = 4 },
    }, garden_areas);
}

pub fn totalFencePrice(garden_areas: []const GardenArea) usize {
    var total_price: usize = 0;
    for (garden_areas) |area| {
        total_price += area.perimeter * area.area;
    }
    return total_price;
}

test totalFencePrice {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day12/totalFencePrice\n", .{});
    std.debug.print("\tcompute plots\n", .{});
    var garden_map = GardenMap{
        .width = 4,
        .height = 4,
        .map = &[_][]const u8{
            "AAAA",
            "BBCD",
            "BBCC",
            "EEEC",
        },
    };
    var garden_plots = try gardenPlots(allocator, garden_map);
    std.debug.print("\tcompute areas\n", .{});
    var garden_areas = try gardenAreas(allocator, garden_plots);
    std.debug.print("\tthe price of fence required for a region is found by multiplying that region's area by its perimeter.\n", .{});
    std.debug.print("\tThe total price of fencing all regions on a map is found by adding together the price of fence for every region on the map\n", .{});
    try std.testing.expectEqual(140, totalFencePrice(garden_areas));

    std.debug.print("\tread input file\n", .{});
    garden_map = try parseGardenMapFile(allocator, "data/day12/test.txt");
    std.debug.print("\tcompute plots\n", .{});
    garden_plots = try gardenPlots(allocator, garden_map);
    std.debug.print("\tcompute areas\n", .{});
    garden_areas = try gardenAreas(allocator, garden_plots);
    std.debug.print("\ttotal fence price\n", .{});
    try std.testing.expectEqual(1930, totalFencePrice(garden_areas));
}

pub fn totalFencePriceDiscount(garden_areas: []const GardenArea) usize {
    var total_price: usize = 0;
    for (garden_areas) |area| {
        total_price += area.sides * area.area;
    }
    return total_price;
}

test totalFencePriceDiscount {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("day12/totalFencePriceDiscount\n", .{});
    std.debug.print("\tcompute plots\n", .{});
    var garden_map = GardenMap{
        .width = 4,
        .height = 4,
        .map = &[_][]const u8{
            "AAAA",
            "BBCD",
            "BBCC",
            "EEEC",
        },
    };
    var garden_plots = try gardenPlots(allocator, garden_map);
    std.debug.print("\tcompute areas\n", .{});
    var garden_areas = try gardenAreas(allocator, garden_plots);
    std.debug.print("\tinstead of using the perimeter to calculate the price, you need to use the number of sides each region has.\n", .{});
    std.debug.print("\tEach straight section of fence counts as a side, regardless of how long it is.\n", .{});
    try std.testing.expectEqual(80, totalFencePriceDiscount(garden_areas));

    std.debug.print("\tread input file\n", .{});
    garden_map = try parseGardenMapFile(allocator, "data/day12/test.txt");
    std.debug.print("\tcompute plots\n", .{});
    garden_plots = try gardenPlots(allocator, garden_map);
    std.debug.print("\tcompute areas\n", .{});
    garden_areas = try gardenAreas(allocator, garden_plots);
    std.debug.print("\ttotal fence price\n", .{});
    try std.testing.expectEqual(1206, totalFencePriceDiscount(garden_areas));
}
