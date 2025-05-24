const std = @import("std");
const Widget = @import("widget.zig").Widget;

const Borders = enum {
    None,
    All,
    Left,
    Right,
    Top,
    Bottom,
};

pub const Block = struct {
    title: []const u8,
    borders: Borders,

    pub fn init(allocator: std.mem.Allocator) *Block {
        const block = allocator.create(Block) catch unreachable;

        block.* = .{
            .title = "",
            .borders = .None,
        };

        return block;
    }

    pub fn deinit(self: *const Block, allocator: std.mem.Allocator) void {
        allocator.destroy(self);
    }

    pub fn bordered(allocator: std.mem.Allocator, border: Borders) *Block {
        const block = allocator.create(Block) catch unreachable;

        block.* = .{
            .title = "",
            .borders = border,
        };

        return block;
    }

    pub fn assignTitle(self: *Block, title: []const u8) *Block {
        self.title = title;

        return self;
    }

    pub fn getKind(ptr: *anyopaque) Widget.Kind {
        const self: *Block = @ptrCast(@alignCast(ptr));

        return .{ .Block = self };
    }

    pub fn widget(self: *Block) Widget {
        return .{
            .ptr = self,
            .getKindFn = getKind,
        };
    }
};
