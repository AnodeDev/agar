const std = @import("std");

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
    const Paragraph = struct {
        content: []const u8,
    };

    const Block = struct {
        content: ?*Block,
    };

    const Kind = union(enum) {
        Paragraph: *Paragraph,
        Block: *Block,
    };

    kind: *Kind,

    pub fn paragraph(allocator: std.mem.Allocator, content: []const u8) *Widget {
        const widget = allocator.create(Widget) catch unreachable;

        widget.* = .{
            .kind = .{
                .paragraph = .{
                    .content = content,
                },
            },
        };

        return widget;
    }

    pub fn block(allocator: std.mem.Allocator) *Widget {
        const widget = allocator.create(Widget) catch unreachable;

        widget.* = .{
            .kind = .{
                .block = .{
                    .content = null,
                },
            },
        };

        return widget;
    }
};
