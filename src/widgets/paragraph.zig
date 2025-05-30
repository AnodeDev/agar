const std = @import("std");
const Block = @import("block.zig").Block;
const Widget = @import("widget.zig").Widget;
const Text = @import("../text/text.zig").Text;

pub const Paragraph = struct {
    block: ?*Block,
    text: Text,

    pub fn init(allocator: std.mem.Allocator, text: Text) *Paragraph {
        const paragraph = allocator.create(Paragraph) catch unreachable;

        paragraph.* = .{
            .block = null,
            .text = text,
        };

        return paragraph;
    }

    pub fn deinit(self: *const Paragraph, allocator: std.mem.Allocator) void {
        if (self.block) |block| {
            allocator.destroy(block);
        }

        self.text.deinit(allocator);
        
        allocator.destroy(self);
    }

    pub fn assignBlock(self: *Paragraph, block: *Block) *Paragraph {
        self.block = block;

        return self;
    }

    pub fn getKind(ptr: *anyopaque) Widget.Kind {
        const self: *Paragraph = @ptrCast(@alignCast(ptr));

        return .{ .Paragraph = self };
    }

    pub fn widget(self: *Paragraph) Widget {
        return .{
            .ptr = self,
            .getKindFn = getKind,
        };
    }
};
