const std = @import("std");
const terminal_mod = @import("terminal.zig");

const Stdout = std.io.stdout;
const posix = std.posix;
const linux = std.os.linux;
const Terminal = terminal_mod.Terminal;

pub const Widget = struct {
    pub const Kind = union(enum) {
        paragraph: *Paragraph,
        block: *Block,
    };

    pub const Paragraph = struct {
        x: usize,
        y: usize,
        width: usize,
        height: usize,
        chars: []const u8,

        pub fn init(x: usize, y: usize, width: usize, height: usize, chars: ?[]const u8, terminal: *Terminal) !Widget {
            const paragraph = try terminal.allocator.create(Paragraph);
            const chars_free = chars orelse "";

            paragraph.* = .{
                .x = x,
                .y = y,
                .width = width,
                .height = height,
                .chars = chars_free,
            };

            return Widget{
                .kind = .{
                    .paragraph = paragraph,
                },
                .terminal = terminal,
            };
        }

        pub fn deinit(self: *const Paragraph, allocator: std.mem.Allocator) void {
            allocator.destroy(self);
        }
    };

    pub const Block = struct {
        x: usize,
        y: usize,
        width: usize,
        height: usize,
        chars: []const u8,
        child: ?*Widget,

        pub fn init(x: usize, y: usize, width: usize, height: usize, content: ?*Widget, terminal: *Terminal) !Widget {
            const block = try terminal.allocator.create(Block);

            block.* = .{
                .x = x,
                .y = y,
                .width = width,
                .height = height,
                .chars = "",
                .content = content,
            };

            return Widget{
                .kind = .{
                    .block = block,
                },
                .terminal = terminal,
            };
        }

        pub fn deinit(self: *const Block, allocator: std.mem.Allocator) void {
            if (self.child) |child| {
                child.deinit();
            }

            allocator.destroy(self);
        }
    };

    kind: Kind,
    terminal: *Terminal,

    pub fn deinit(self: *const Widget) void {
        const allocator = self.terminal.allocator;

        switch (self.kind) {
            .paragraph => |paragraph| {
                paragraph.deinit(allocator);
            },
            .block => |block| {
                block.deinit(allocator);
            },
        }
    }
};
