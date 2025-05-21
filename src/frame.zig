const std = @import("std");
const terminal_mod = @import("terminal.zig");
const widget_mod = @import("widget.zig");

const Terminal = terminal_mod.Terminal;
const Widget = widget_mod.Widget;
const Rect = widget_mod.Rect;

pub const Frame = struct {
    ptr: *Terminal,

    pub fn area(self: *const Frame) Rect {
        return Rect{
            .x = 0,
            .y = 0,
            .width = self.ptr.backend.screen_size.col,
            .height = self.ptr.backend.screen_size.row,
        };
    }

    pub fn renderWidget(self: *const Frame, allocator: std.mem.Allocator, widget: *Widget, rect: Rect) !void {
        widget.width = rect.width;
        widget.height = rect.height;

        switch (widget.kind) {
            .paragraph => |paragraph| {
                var x_offset: u16 = 0;
                var y_offset: u16 = 0;

                switch (paragraph.block.borders) {
                    .None => {},
                    .All => {
                        const horizontal = try allocator.alloc(u8, 4 * rect.width);
                        defer allocator.free(horizontal);
                        const vertical = try allocator.alloc(u8, 4 * rect.height);
                        defer allocator.free(vertical);

                        var hor_line: [4]u8 = undefined;
                        const hor_len = try std.unicode.utf8Encode('─', &hor_line);
                        var vert_line: [4]u8 = undefined;
                        const vert_len = try std.unicode.utf8Encode('│', &vert_line);
                        var top_left_line: [4]u8 = undefined;
                        const top_left_len = try std.unicode.utf8Encode('┌', &top_left_line);
                        var top_right_line: [4]u8 = undefined;
                        const top_right_len = try std.unicode.utf8Encode('┐', &top_right_line);
                        var bottom_left_line: [4]u8 = undefined;
                        const bottom_left_len = try std.unicode.utf8Encode('└', &bottom_left_line);
                        var bottom_right_line: [4]u8 = undefined;
                        const bottom_right_len = try std.unicode.utf8Encode('┘', &bottom_right_line);

                        var width_offset: u16 = 0;

                        for (0..rect.width - 2) |_| {

                            @memcpy(horizontal[width_offset..hor_len + width_offset], hor_line[0..hor_len]);

                            width_offset += hor_len;
                        }

                        // Top
                        try self.ptr.backend.moveCursor(rect.x + 2, rect.y);
                        try self.ptr.backend.stdout.writer().print("{s}", .{ horizontal[0..width_offset] });

                        // Bottom
                        try self.ptr.backend.moveCursor(rect.x + 2, rect.y + rect.height);
                        try self.ptr.backend.stdout.writer().print("{s}", .{ horizontal[0..width_offset] });

                        // Vertical
                        for (2..rect.height) |i| {
                            try self.ptr.backend.moveCursor(rect.x, rect.y + i);
                            try self.ptr.backend.stdout.writer().print("{s}", .{ vert_line[0..vert_len] });

                            try self.ptr.backend.moveCursor(rect.x + rect.width, rect.y + i);
                            try self.ptr.backend.stdout.writer().print("{s}", .{ vert_line[0..vert_len] });
                        }

                        try self.ptr.backend.moveCursor(rect.x, rect.y);
                        try self.ptr.backend.write(top_left_line[0..top_left_len]);
                        try self.ptr.backend.moveCursor(rect.x + rect.width, rect.y);
                        try self.ptr.backend.write(top_right_line[0..top_right_len]);
                        try self.ptr.backend.moveCursor(rect.x, rect.y + rect.height);
                        try self.ptr.backend.write(bottom_left_line[0..bottom_left_len]);
                        try self.ptr.backend.moveCursor(rect.x + rect.width, rect.y + rect.height);
                        try self.ptr.backend.write(bottom_right_line[0..bottom_right_len]);

                        x_offset += 2;
                        y_offset += 2;
                    },
                    .Left => undefined,
                    .Right => undefined,
                    .Top => undefined,
                    .Bottom => undefined,
                }

                try self.ptr.backend.moveCursor(rect.x + x_offset, rect.y + y_offset);
        

                try self.ptr.backend.write(paragraph.text[0..paragraph.text.len]);
            },
            .block => {},
        }
    }
};
