const std = @import("std");
const style_mod = @import("../style/style.zig");

const Style = style_mod.Style;
const Color = style_mod.Color;

pub const Text = struct {
    text: []const u8,
    style: Style,

    pub fn raw(allocator: std.mem.Allocator, content: []const u8) Text {
        const text = allocator.alloc(u8, content.len) catch @panic("Failed to allocate content");
        @memcpy(text, content);

        return .{
            .text = text,
            .style = Style.init(),
        };
    }

    pub fn styled(allocator: std.mem.Allocator, content: []const u8, style: Style) Text {
        const text = allocator.alloc(u8, content.len) catch @panic("Failed to allocate content");
        @memcpy(text, content);

        return .{
            .text = text,
            .style = style,
        };
    }

    pub fn deinit(self: *const Text, allocator: std.mem.Allocator) void {
        allocator.free(self.text);
    }
};
