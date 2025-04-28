const std = @import("std");
const builtin = @import("builtin");

// Fields
//  - row: u16
//  - col: u16
//  - xpixel: u16,
//  - ypixel: u16,
const Linux = std.os.linux;
const Posix = std.posix;
const Winsize = Posix.winsize;
const Termios = Posix.termios;

pub const Cursor = struct {
    x: usize,
    y: usize,

    pub fn init() Cursor {
        return Cursor {
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

    pub fn write(self: *const Backend, buf: []const u8) !void {
        try self.stdout.writer().print("{s}", .{ buf });
    }

    pub fn clear(self: *const Backend) !void {
        try self.stdout.writer().writeAll("\x1b[2J");
    }

//   pub fn flush() !void {
//   }
// 
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
        if (x >= self.screen_size.col or y >= self.screen_size.row or x < 0 or y < 0) {
            return error.OutOfBoundsCoordinate;
        }

        try self.stdout.writer().print("\x1b[{d};{d}H", .{ y, x });

        self.cursor.x = x;
        self.cursor.y = y;
    }
};
