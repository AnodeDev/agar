const std = @import("std");
const builtin = @import("builtin");
const widget = @import("widgets/widget.zig");
const Text = @import("text/text.zig").Text;
const Color = @import("style/color.zig").Color;

const Linux = std.os.linux;
const Posix = std.posix;
const Winsize = Posix.winsize;
const Termios = Posix.termios;
const Rect = widget.Rect;

pub const Cursor = struct {
    x: usize,
    y: usize,

    pub fn init() Cursor {
        return Cursor{
            .x = 0,
            .y = 0,
        };
    }
};

pub const Backend = struct {
    stdin: std.fs.File,
    stdout: std.fs.File,
    screen_size: *Winsize,
    cursor: Cursor,

    pub fn init(allocator: std.mem.Allocator) !Backend {
        var backend = Backend{
            .stdin = std.io.getStdIn(),
            .stdout = std.io.getStdOut(),
            .screen_size = undefined,
            .cursor = Cursor.init(),
        };

        backend.screen_size = try backend.getSize(allocator);
        try backend.clear();
        try backend.moveCursor(0, 0);

        return backend;
    }

    pub fn deinit(self: *const Backend, allocator: std.mem.Allocator) void {
        allocator.destroy(self.screen_size);
    }

    pub fn renderText(self: *const Backend, text: Text) !void {
        try text.style.add_modifier.apply();
        try text.style.sub_modifier.exempt();

        if (text.style.foreground) |fg| {
            if (text.style.background) |bg| {
                try self.stdout.writer().print("\x1b[{d};{d}m", .{ fg.parseForeground(), bg.parseBackground() });
            } else {
                try self.stdout.writer().print("\x1b[{d}m", .{ fg.parseForeground() });
            }
        } else if (text.style.background) |bg| {
            try self.stdout.writer().print("\x1b[{d};{d}m", .{ 39, bg.parseBackground() });
        }

        try self.write(text.text);

        try self.write("\x1b[0m");
    }

    pub fn write(self: *const Backend, buf: []const u8) !void {
        try self.stdout.writer().print("{s}", .{buf});
    }

    pub fn clear(self: *const Backend) !void {
        try self.stdout.writer().writeAll("\x1b[2J");
    }

    pub fn getSize(self: *const Backend, allocator: std.mem.Allocator) !*Winsize {
        if (builtin.target.os.tag == .linux) {
            const size = try allocator.create(Winsize);

            switch (Linux.ioctl(self.stdout.handle, Linux.T.IOCGWINSZ, @intFromPtr(size))) {
                0 => return size,
                else => return error.UnexpectedError,
            }
        } else {
            return error.NotOnLinux;
        }
    }

    pub fn showCursor(self: *const Backend) !void {
        try self.stdout.writer().writeAll("\x1b[?25h");
    }

    pub fn hideCursor(self: *const Backend) !void {
        try self.stdout.writer().writeAll("\x1b[?25l");
    }

    pub fn moveCursor(self: *Backend, x: usize, y: usize) !void {
        const new_x = x + 1;
        const new_y = y + 1;

        if (new_x > self.screen_size.col or new_y > self.screen_size.row or new_x < 0 or new_y < 0) {
            return error.OutOfBoundsCoordinate;
        }

        try self.stdout.writer().print("\x1b[{d};{d}H", .{ new_y, new_x });

        self.cursor.x = x;
        self.cursor.y = y;
    }

    // Wrapper function for resetting cursor to 0, 0
    pub fn resetCursor(self: *Backend) !void {
        try self.moveCursor(0, 0);
    }

    // Wrapper function to get a Rect for the entire screen
    pub fn area(self: *const Backend, allocator: std.mem.Allocator) *Rect {
        return Rect.init(allocator, self.screen_size.col, self.screen_size.row);
    }
};
