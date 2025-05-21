const std = @import("std");

const Borders = enum {
    None,
    All,
    Left,
    Right,
    Top,
    Bottom,
};

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

pub const Widget = struct {
    const Kind = union(enum) {
        paragraph: Paragraph,
        block: Block,
    };

    const Paragraph = struct {
        block: Block,
        text: []const u8,
    };

    const Block = struct {
        borders: Borders,
    };

    kind: Kind,
    width: u16,
    height: u16,

    pub fn paragraph(allocator: std.mem.Allocator, text: []const u8) *Widget {
        const widget = allocator.create(Widget) catch unreachable;

        widget.* = .{
            .kind = .{
                .paragraph = .{
                    .block = .{
                        .borders = Borders.All,
                    },
                    .text = text,
                },
            },
            .width = 0,
            .height = 0,
        };

        return widget;
    }

    pub fn block(allocator: std.mem.Allocator) *Widget {
        const widget = allocator.create(Widget) catch unreachable;

        widget.* = .{
            .kind = .{
                .block = .{
                    .borders = Borders.All,
                },
            },
        };

        return widget;
    }
};

pub const Constraint = union(enum) {
    Length: u16,
};

pub fn horizontal(allocator: std.mem.Allocator, constraints: []const Constraint, area: Rect) ![]Rect {
    var new_areas = try allocator.alloc(Rect, constraints.len);
    defer allocator.free(new_areas);
    const len = constraints.len;
    var offset: u16 = 0;

    for (0..len) |i| {
        switch (constraints[i]) {
            .Length => |width| {
                const new_rect = Rect{
                    .x = area.x + offset,
                    .y = area.y,
                    .width = width,
                    .height = area.height,
                };

                new_areas[i] = new_rect;
                offset += width;
            },
        }
    }

    return new_areas;
}

pub fn vertical(allocator: std.mem.Allocator, constraints: []const Constraint, area: Rect) ![]Rect {
    var new_areas = try allocator.alloc(Rect, constraints.len);
    defer allocator.free(new_areas);
    const len = constraints.len;
    var offset: u16 = 0;

    for (0..len) |i| {
        switch (constraints[i]) {
            .Length => |height| {
                const new_rect = Rect{
                    .x = area.x,
                    .y = area.y + offset,
                    .width = area.width,
                    .height = height,
                };

                new_areas[i] = new_rect;
                offset += height;
            },
        }
    }

    return new_areas;
}
