const std = @import("std");
pub const Block = @import("block.zig").Block;
pub const Paragraph = @import("paragraph.zig").Paragraph;

pub const Rect = packed struct {
    x: u16,
    y: u16,
    width: u16,
    height: u16,

    pub fn init(allocator: std.mem.Allocator, width: u16, height: u16) *Rect {
        const rect = allocator.create(Rect) catch unreachable;

        rect.* = .{
            .x = 0,
            .y = 0,
            .width = width,
            .height = height,
        };

        return rect;
    }
};

pub const Constraint = union(enum) {
    Length: u16,
    Fill: u16,
};

pub const Widget = struct {
    pub const Kind = union(enum) {
        Block: *Block,
        Paragraph: *Paragraph,
    };

    ptr: *anyopaque,
    getKindFn: *const fn (ptr: *anyopaque) Kind,

    pub fn getKind(self: *const Widget) Kind {
        return self.getKindFn(self.ptr);
    }
};

pub fn horizontal(allocator: std.mem.Allocator, constraints: []const Constraint, area: Rect) ![]Rect {
    var new_areas = try allocator.alloc(Rect, constraints.len);

    var total_fixed_width: u16 = 0;
    var total_fill_weight: usize = 0;

    for (constraints) |constraint| {
        switch (constraint) {
            .Length => |width| {
                total_fixed_width += width;
            },
            .Fill => |weight| {
                total_fill_weight += weight;
            },
        }
    }

    const remaining_width = area.width - total_fixed_width;
    var offset: u16 = 0;

    for (constraints, 0..) |constraint, i| {
        switch (constraint) {
            .Length => |width| {
                const rect = Rect{
                    .x = area.x + offset,
                    .y = area.y,
                    .width = width,
                    .height = area.height,
                };

                new_areas[i] = rect;
                offset += rect.width;
            },
            .Fill => |weight| {
                const fill_weight: u16 = @intFromFloat(@as(f32, @floatFromInt(remaining_width * weight)) / @as(f32, @floatFromInt(total_fill_weight)));

                const rect = Rect{
                    .x = area.x + offset,
                    .y = area.y,
                    .width = fill_weight,
                    .height = area.height,
                };

                new_areas[i] = rect;
                offset += rect.width;
            },
        }
    }

    return new_areas;
}

pub fn vertical(allocator: std.mem.Allocator, constraints: []const Constraint, area: Rect) ![]Rect {
    var new_areas = try allocator.alloc(Rect, constraints.len);

    var total_fixed_height: u16 = 0;
    var total_fill_weight: usize = 0;

    for (constraints) |constraint| {
        switch (constraint) {
            .Length => |height| {
                total_fixed_height += height;
            },
            .Fill => |weight| {
                total_fill_weight += weight;
            },
        }
    }

    const remaining_height = area.height - total_fixed_height;
    var offset: u16 = 0;

    for (constraints, 0..) |constraint, i| {
        switch (constraint) {
            .Length => |height| {
                const rect = Rect{
                    .x = area.x,
                    .y = area.y + offset,
                    .width = area.width,
                    .height = height,
                };

                new_areas[i] = rect;
                offset += rect.height;
            },
            .Fill => |weight| {
                const fill_weight: u16 = @intFromFloat(@as(f32, @floatFromInt(remaining_height * weight)) / @as(f32, @floatFromInt(total_fill_weight)));

                const rect = Rect{
                    .x = area.x,
                    .y = area.y + offset,
                    .width = area.width,
                    .height = fill_weight,
                };

                new_areas[i] = rect;
                offset += rect.height;
            },
        }
    }

    return new_areas;
}
